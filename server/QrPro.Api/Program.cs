// QR Pro sunucusu: Google Play satın alma doğrulama, gizlilik politikası ve sağlık ucu.

using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using QrPro.Api;
using QrPro.Api.Data;
using QrPro.Api.Guards;
using QrPro.Api.Play;
using QrPro.Api.Privacy;

// Docker sağlık denetimi: imajda curl yok, aynı ikili /health'e sorar.
if (args.Contains("--healthcheck"))
{
    return await HealthCheck.RunAsync();
}

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(o => o.AddServerHeader = false);
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole(o =>
{
    o.SingleLine = true;
    o.TimestampFormat = "yyyy-MM-dd HH:mm:ss ";
    o.UseUtcTimestamp = true;
});

// Ayarlar ve bağlantı dizesi DI'dan tembel okunur: testler yapılandırmayı uygulama kurulurken değiştirebilir.
builder.Services.AddSingleton(sp => AppSettings.From(sp.GetRequiredService<IConfiguration>()));
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddDbContext<QrProDbContext>((sp, o) =>
    o.UseNpgsql(sp.GetRequiredService<IConfiguration>().GetConnectionString("Postgres")
                ?? throw new InvalidOperationException("ConnectionStrings__Postgres tanımlı değil")));
builder.Services.AddScoped<PurchaseStore>();
builder.Services.AddSingleton<IPlayPublisherSource, ServiceAccountPublisherSource>();
builder.Services.AddSingleton<PlayVerifier>();

var app = builder.Build();
var log = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("QrPro");

await Database.MigrateAsync(app.Services, log, app.Lifetime.ApplicationStopping);

var verifier = app.Services.GetRequiredService<PlayVerifier>();
if (verifier.IsConfigured)
{
    log.LogInformation("Servis hesabı anahtarı bulundu: Google Play doğrulaması açık.");
}
else
{
    log.LogWarning("Servis hesabı anahtarı yok ({Path}): yanıtlar 'unverified' olacak.", verifier.ServiceAccountPath);
}

// Önce hız sınırı, sonra gövde sınırı (eski sürümdeki sıra).
app.UseMiddleware<RateLimitMiddleware>();
app.UseMiddleware<BodySizeLimitMiddleware>();
app.UseStatusCodePages(async ctx =>
{
    var detail = ctx.HttpContext.Response.StatusCode switch
    {
        StatusCodes.Status404NotFound => "Not Found",
        StatusCodes.Status405MethodNotAllowed => "Method Not Allowed",
        _ => null,
    };
    if (detail is not null)
    {
        await ctx.HttpContext.Response.WriteAsJsonAsync(new { detail });
    }
});

app.MapPost("/v1/purchases/verify", async (HttpContext context, AppSettings settings, PlayVerifier playVerifier,
    PurchaseStore store, ILogger<PlayVerifier> verifyLog) =>
{
    using var body = new MemoryStream();
    await context.Request.Body.CopyToAsync(body, context.RequestAborted);
    var (req, errors) = VerifyRequest.Parse(body.GetBuffer().AsSpan(0, (int)body.Length));
    if (req is null)
    {
        return Results.Json(errors, statusCode: StatusCodes.Status422UnprocessableEntity);
    }

    VerifyResult result;
    if (req.PackageName != settings.PackageName)
    {
        result = VerifyResult.Invalid("package_mismatch");
    }
    else if (req.ProductId != settings.ProductId)
    {
        result = VerifyResult.Invalid("product_mismatch");
    }
    else
    {
        result = await playVerifier.VerifyAsync(req.PackageName, req.ProductId, req.PurchaseToken);
    }

    try
    {
        await store.RecordAsync(req.PurchaseToken, req.PackageName, req.ProductId, req.OrderId, result.Status,
            result.Reason, result.Raw?.ToJsonString());
    }
    catch (Exception ex) // Kayıt hatası doğrulama sonucunu bozmasın.
    {
        verifyLog.LogError(ex, "Satın alma kaydı yazılamadı");
    }

    // Günlükte IP, sipariş numarası ya da tam jeton tutulmaz.
    verifyLog.LogInformation("verify -> {Status} ({Reason})", result.Status, result.Reason ?? "None");
    return Results.Json(new VerifyResponse(result.Valid, result.Status, result.Reason));
});

// GET ve HEAD (curl -I ile başlık kontrolü 405 dönmesin).
string[] getHead = ["GET", "HEAD"];

app.MapMethods("/privacy", getHead, (HttpContext context, AppSettings settings) =>
{
    context.Response.Headers.ContentSecurityPolicy =
        "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'";
    // Politika güncellenince tarayıcı eski sürümü göstermesin: her açılışta sunucuya sorulur.
    context.Response.Headers.CacheControl = "no-cache";
    return Results.Content(PrivacyPage.Render(settings.ContactEmail, settings.DeveloperName),
        "text/html; charset=utf-8");
});

// Play Console "Veri silme" bağlantısı.
app.MapMethods("/delete", getHead, (HttpContext context, AppSettings settings) =>
{
    context.Response.Headers.ContentSecurityPolicy =
        "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'";
    // Politika güncellenince tarayıcı eski sürümü göstermesin: her açılışta sunucuya sorulur.
    context.Response.Headers.CacheControl = "no-cache";
    return Results.Content(PrivacyPage.RenderDelete(settings.ContactEmail, settings.DeveloperName),
        "text/html; charset=utf-8");
});

app.MapMethods("/health", getHead, () => Results.Text("""{"ok":true}""", "application/json"));

app.MapMethods("/", getHead, () => Results.Redirect("/privacy"));

app.Run();
return 0;

/// <summary>Yanıt: <c>{"valid": true|false|null, "status": "...", "reason": "..."|null}</c>.</summary>
internal sealed record VerifyResponse(
    [property: System.Text.Json.Serialization.JsonPropertyName("valid")] bool? Valid,
    [property: System.Text.Json.Serialization.JsonPropertyName("status")] string Status,
    [property: System.Text.Json.Serialization.JsonPropertyName("reason")] string? Reason);

internal static class Database
{
    /// <summary>
    /// Açılışta migration'ları uygular. Sunucu yeniden başlarken Postgres henüz hazır olmayabilir
    /// (Docker, compose'un depends_on sırasını gözetmez): bir süre yeniden dener.
    /// </summary>
    public static async Task MigrateAsync(IServiceProvider services, ILogger log, CancellationToken ct)
    {
        const int attempts = 30;
        for (var i = 1; ; i++)
        {
            try
            {
                await using var scope = services.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<QrProDbContext>();
                await db.Database.MigrateAsync(ct);
                return;
            }
            catch (Exception ex) when (i < attempts && ex is Npgsql.NpgsqlException or TimeoutException)
            {
                log.LogWarning("Veritabanına bağlanılamadı ({Attempt}/{Attempts}): {Error}", i, attempts, ex.Message);
                await Task.Delay(TimeSpan.FromSeconds(2), ct);
            }
        }
    }
}

internal static class HealthCheck
{
    public static async Task<int> RunAsync()
    {
        var port = (Environment.GetEnvironmentVariable("ASPNETCORE_HTTP_PORTS") ?? "8080").Split(';', ',')[0].Trim();
        using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(3) };
        try
        {
            using var resp = await http.GetAsync($"http://127.0.0.1:{port}/health");
            using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
            return resp.IsSuccessStatusCode && doc.RootElement.GetProperty("ok").GetBoolean() ? 0 : 1;
        }
        catch (Exception)
        {
            return 1;
        }
    }
}

public partial class Program;
