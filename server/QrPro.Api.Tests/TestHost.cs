using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Npgsql;
using QrPro.Api.Data;
using QrPro.Api.Play;
using Testcontainers.PostgreSql;

namespace QrPro.Api.Tests;

public static class Consts
{
    public const string Pkg = "com.safarahmancenkci.qrpro";
    public const string Product = "qr_pro_lifetime";
}

/// <summary>Bütün test sınıflarının paylaştığı geçici Postgres (Docker). Her uygulama örneği ayrı veritabanı alır.</summary>
public sealed class PostgresFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder("postgres:17-alpine").Build();

    public Task InitializeAsync() => _container.StartAsync();

    public Task DisposeAsync() => _container.DisposeAsync().AsTask();

    public string NewDatabase()
    {
        var csb = new NpgsqlConnectionStringBuilder(_container.GetConnectionString())
        {
            Database = "qrpro_test_" + Guid.NewGuid().ToString("N"),
        };
        return csb.ConnectionString;
    }
}

[CollectionDefinition(Name)]
public sealed class PostgresCollection : ICollectionFixture<PostgresFixture>
{
    public const string Name = "postgres";
}

/// <summary>
/// Uygulama örneği: ayrı veritabanı, var olmayan servis hesabı dosyası (eski conftest gibi), dakikada 1000 istek.
/// İstenirse Google katmanı ve saat taklit edilir.
/// </summary>
public sealed class QrProFactory(
    string connectionString,
    IDictionary<string, string>? settings = null,
    IPlayPublisherSource? publisherSource = null,
    TimeProvider? time = null) : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("ConnectionStrings:Postgres", connectionString);
        builder.UseSetting("SERVICE_ACCOUNT_FILE", Path.Combine(Path.GetTempPath(), "qrpro-yok-" + Guid.NewGuid() + ".json"));
        builder.UseSetting("RATE_LIMIT_PER_MINUTE", "1000");
        builder.UseSetting("CONTACT_EMAIL", "");
        foreach (var (key, value) in settings ?? new Dictionary<string, string>())
        {
            builder.UseSetting(key, value);
        }
        builder.ConfigureServices(services =>
        {
            if (publisherSource is not null)
            {
                services.RemoveAll<IPlayPublisherSource>();
                services.AddSingleton(publisherSource);
            }
            if (time is not null)
            {
                services.RemoveAll<TimeProvider>();
                services.AddSingleton(time);
            }
        });
    }

    public async Task<Purchase?> RowAsync(string token)
    {
        await using var scope = Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<QrProDbContext>();
        return await db.Purchases.AsNoTracking().SingleOrDefaultAsync(p => p.Token == token);
    }
}

/// <summary>Google Play API taklidi: GET yanıtı ya da istisnası ayarlanır.</summary>
public sealed class FakePublisher(PlayHttpResponse? getResponse = null, Exception? getException = null)
    : IPlayPublisher
{
    public List<(string Package, string Product, string Token)> Gets { get; } = [];

    public Task<PlayHttpResponse> GetProductPurchaseAsync(string packageName, string productId, string token,
        CancellationToken ct = default)
    {
        Gets.Add((packageName, productId, token));
        if (getException is not null)
        {
            throw getException;
        }
        return Task.FromResult(getResponse!);
    }


    public static FakePublisher Json(int status, string body) =>
        new(new PlayHttpResponse(status, body));
}

public sealed class FakeSource(IPlayPublisher? publisher) : IPlayPublisherSource
{
    public string Path => "/fake/key.json";
    public bool IsConfigured => publisher is not null;
    public IPlayPublisher? TryGet() => publisher;
}

/// <summary>Elle ilerletilen saat (hız sınırı penceresi için).</summary>
public sealed class ManualTime : TimeProvider
{
    private long _ticks = 1_000_000;

    public override long TimestampFrequency => TimeSpan.TicksPerSecond;

    public override long GetTimestamp() => Interlocked.Read(ref _ticks);

    public void Advance(TimeSpan by) => Interlocked.Add(ref _ticks, by.Ticks);
}
