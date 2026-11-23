using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc.Testing;
using QrPro.Api.Play;
using static QrPro.Api.Tests.Consts;

namespace QrPro.Api.Tests;

/// <summary>HTTP sözleşmesi ve kayıtlar: gerçek Postgres, Google taklidi.</summary>
[Collection(PostgresCollection.Name)]
public sealed class ApiTests(PostgresFixture pg) : IDisposable
{
    private readonly List<IDisposable> _disposables = [];

    public void Dispose() => _disposables.ForEach(d => d.Dispose());

    private QrProFactory Factory(IDictionary<string, string>? settings = null, IPlayPublisherSource? source = null,
        TimeProvider? time = null)
    {
        var f = new QrProFactory(pg.NewDatabase(), settings, source, time);
        _disposables.Add(f);
        return f;
    }

    private static HttpClient Client(QrProFactory f) =>
        f.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });

    private static object Body(string token, string pkg = Pkg, string product = Product, string? orderId = "GPA.1") =>
        new { packageName = pkg, productId = product, purchaseToken = token, orderId };

    private static async Task<JsonNode?> PostVerify(HttpClient c, object body, string? forwardedFor = null)
    {
        using var req = new HttpRequestMessage(HttpMethod.Post, "/v1/purchases/verify") { Content = JsonContent.Create(body) };
        if (forwardedFor is not null)
        {
            req.Headers.Add("X-Forwarded-For", forwardedFor);
        }
        using var resp = await c.SendAsync(req);
        Assert.Equal(HttpStatusCode.OK, resp.StatusCode);
        return JsonNode.Parse(await resp.Content.ReadAsStringAsync());
    }

    private static void AssertResult(JsonNode? json, bool? valid, string status, string? reason)
    {
        var expected = new JsonObject { ["valid"] = valid, ["status"] = status, ["reason"] = reason };
        Assert.True(JsonNode.DeepEquals(expected, json), json?.ToJsonString());
    }

    [Fact]
    public async Task HealthAndRoot()
    {
        var c = Client(Factory());
        var health = await c.GetAsync("/health");
        Assert.Equal("""{"ok":true}""", await health.Content.ReadAsStringAsync());
        Assert.Equal("application/json", health.Content.Headers.ContentType?.MediaType);

        var root = await c.GetAsync("/");
        Assert.Equal(HttpStatusCode.Found, root.StatusCode);
        Assert.Equal("/privacy", root.Headers.Location?.OriginalString);
        Assert.False(root.Headers.Contains("Server"));
    }

    [Fact]
    public async Task UnknownPathIs404Json()
    {
        var c = Client(Factory());
        var r = await c.GetAsync("/yok");
        Assert.Equal(HttpStatusCode.NotFound, r.StatusCode);
        Assert.Equal("""{"detail":"Not Found"}""", await r.Content.ReadAsStringAsync());
        var m = await c.GetAsync("/v1/purchases/verify");
        Assert.Equal(HttpStatusCode.MethodNotAllowed, m.StatusCode);
    }

    [Fact]
    public async Task PrivacyPage()
    {
        var r = await Client(Factory()).GetAsync("/privacy");
        Assert.Equal(HttpStatusCode.OK, r.StatusCode);
        Assert.Equal("text/html", r.Content.Headers.ContentType?.MediaType);
        var html = await r.Content.ReadAsStringAsync();
        foreach (var text in new[]
                 {
                     "QR Kod Okuyucu", "2026-11-24", "Safa Rahman Cenkci", "ML Kit", "30 gün", "href=\"/delete\"",
                     "Gizlilik Politikası", "Privacy Policy", "Android 12",
                     "Google Play mağaza sayfasındaki geliştirici iletişim adresi",
                     "the developer contact address on the Google Play store page", "Wi‑Fi",
                     ":root { color-scheme: light dark; }",
                 })
        {
            Assert.Contains(text, html);
        }
        Assert.DoesNotContain("{date}", html);
        Assert.DoesNotContain("{contact_", html);
        Assert.StartsWith("default-src 'none'", r.Headers.GetValues("Content-Security-Policy").Single());
        Assert.Equal("public, max-age=3600", r.Headers.CacheControl?.ToString());
    }

    [Fact]
    public async Task DeletePage()
    {
        var c = Client(Factory(new Dictionary<string, string>
        {
            ["CONTACT_EMAIL"] = "destek@ornek.com",
            ["DEVELOPER_NAME"] = "Örnek <Geliştirici>",
        }));
        var r = await c.GetAsync("/delete");
        Assert.Equal(HttpStatusCode.OK, r.StatusCode);
        Assert.Equal("text/html", r.Content.Headers.ContentType?.MediaType);
        var html = await r.Content.ReadAsStringAsync();
        foreach (var text in new[]
                 {
                     "QR Kod Okuyucu", "Örnek &lt;Geliştirici&gt;", "Veri silme talebi", "GPA.", "30 gün",
                     "Satın Alımı Geri Yükle", "mailto:destek@ornek.com", "href=\"/privacy\"", "Data Deletion Request",
                 })
        {
            Assert.Contains(text, html);
        }
        Assert.DoesNotContain("{", html.Split("<style>")[0] + html.Split("</style>")[1]);
        Assert.StartsWith("default-src 'none'", r.Headers.GetValues("Content-Security-Policy").Single());
    }

    [Fact]
    public async Task PrivacyContactEmailEscaped()
    {
        var c = Client(Factory(new Dictionary<string, string> { ["CONTACT_EMAIL"] = "  a<b>@ornek.com " }));
        var html = await c.GetStringAsync("/privacy");
        Assert.Contains("<a href=\"mailto:a&lt;b&gt;@ornek.com\">a&lt;b&gt;@ornek.com</a>", html);
        Assert.DoesNotContain("a<b>", html);
        Assert.DoesNotContain("Google Play mağaza sayfasındaki", html);
    }

    [Fact]
    public async Task VerifyWithoutKeyIsUnverifiedAndRecorded()
    {
        var f = Factory();
        var c = Client(f);
        AssertResult(await PostVerify(c, Body("tok-nokey"), "203.0.113.7, 10.0.0.1"),
            null, "unverified", "service_account_missing");
        var row = await f.RowAsync("tok-nokey");
        Assert.NotNull(row);
        Assert.Equal(("unverified", "GPA.1", Product, Pkg), (row.Status, row.OrderId, row.ProductId, row.PackageName));
        Assert.Equal("service_account_missing", row.Reason);
        Assert.Null(row.RawResponse);
        Assert.Equal(1, row.RequestCount);

        await PostVerify(c, Body("tok-nokey", orderId: null));
        row = await f.RowAsync("tok-nokey");
        Assert.Equal(2, row!.RequestCount);
        Assert.Equal("GPA.1", row.OrderId);
        Assert.True(row.UpdatedAt >= row.CreatedAt);
    }

    [Fact]
    public async Task VerifyWrongPackageAndProduct()
    {
        var publisher = FakePublisher.Json(200, """{"purchaseState":0}""");
        var f = Factory(source: new FakeSource(publisher));
        var c = Client(f);
        AssertResult(await PostVerify(c, Body("tok-pkg", pkg: "com.baska")), false, "invalid", "package_mismatch");
        Assert.Equal("invalid", (await f.RowAsync("tok-pkg"))!.Status);
        AssertResult(await PostVerify(c, Body("tok-prod", product: "baska")), false, "invalid", "product_mismatch");
        Assert.Empty(publisher.Gets); // Google'a hiç sorulmadı.
    }

    [Fact]
    public async Task VerifyRejectsBadBody()
    {
        var c = Client(Factory());

        async Task<(HttpStatusCode, JsonNode?)> Raw(string json)
        {
            var r = await c.PostAsync("/v1/purchases/verify", new StringContent(json, Encoding.UTF8, "application/json"));
            return (r.StatusCode, JsonNode.Parse(await r.Content.ReadAsStringAsync()));
        }

        var (status, json) = await Raw($$"""{"packageName":"{{Pkg}}"}""");
        Assert.Equal(HttpStatusCode.UnprocessableEntity, status);
        Assert.Equal(["productId", "purchaseToken"],
            json!["detail"]!.AsArray().Select(e => e!["loc"]![1]!.GetValue<string>()).ToArray());
        Assert.Equal("missing", json["detail"]![0]!["type"]!.GetValue<string>());

        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Raw("{bozuk")).Item1);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Raw("[]")).Item1);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Raw("")).Item1);
        Assert.Equal(HttpStatusCode.UnprocessableEntity,
            (await Raw($$"""{"packageName":"{{Pkg}}","productId":"{{Product}}","purchaseToken":""}""")).Item1);
        Assert.Equal(HttpStatusCode.UnprocessableEntity,
            (await Raw($$"""{"packageName":"{{Pkg}}","productId":"{{Product}}","purchaseToken":"t","orderId":5}""")).Item1);
        var longToken = new string('x', 4097);
        (status, json) = await Raw($$"""{"packageName":"{{Pkg}}","productId":"{{Product}}","purchaseToken":"{{longToken}}"}""");
        Assert.Equal(HttpStatusCode.UnprocessableEntity, status);
        Assert.Equal("string_too_long", json!["detail"]![0]!["type"]!.GetValue<string>());

        // Fazla alanlar yok sayılır, orderId isteğe bağlıdır.
        (status, json) = await Raw($$"""{"packageName":"{{Pkg}}","productId":"{{Product}}","purchaseToken":"tok-extra","x":1}""");
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.Equal("unverified", json!["status"]!.GetValue<string>());

        // Gövde sınırı: 8 KB.
        var big = await c.PostAsJsonAsync("/v1/purchases/verify", Body(new string('x', 9000)));
        Assert.Equal(HttpStatusCode.RequestEntityTooLarge, big.StatusCode);
        Assert.Equal("""{"error":"payload_too_large"}""", await big.Content.ReadAsStringAsync());

        // Content-Length olmadan (chunked) gelen büyük gövde de kesilir.
        var chunked = new StreamContent(new MemoryStream(Encoding.UTF8.GetBytes(new string('x', 9000))));
        chunked.Headers.ContentLength = null;
        using var req = new HttpRequestMessage(HttpMethod.Post, "/v1/purchases/verify") { Content = chunked };
        req.Headers.TransferEncodingChunked = true;
        Assert.Equal(HttpStatusCode.RequestEntityTooLarge, (await c.SendAsync(req)).StatusCode);
    }

    [Fact]
    public async Task GoogleResultNotOverwrittenByUnverified()
    {
        var publisher = FakePublisher.Json(200, """{"purchaseState":0,"acknowledgementState":1}""");
        var f = Factory(source: new FakeSource(publisher));
        var c = Client(f);
        AssertResult(await PostVerify(c, Body("tok-ok")), true, "verified", null);
        AssertResult(await PostVerify(c, Body("tok-ok", pkg: "com.baska", orderId: null)), false, "invalid",
            "package_mismatch");

        var row = await f.RowAsync("tok-ok");
        Assert.Equal(("verified", Pkg, (string?)null, "GPA.1", 2),
            (row!.Status, row.PackageName, row.Reason, row.OrderId, row.RequestCount));
        Assert.True(JsonNode.DeepEquals(JsonNode.Parse("""{"purchaseState":0,"acknowledgementState":1}"""),
            JsonNode.Parse(row.RawResponse!)));
    }

    [Fact]
    public async Task GoogleErrorRecordedWithRaw()
    {
        var f = Factory(source: new FakeSource(FakePublisher.Json(404, """{"error":{"code":404}}""")));
        AssertResult(await PostVerify(Client(f), Body("tok-404")), false, "invalid", "purchase_not_found");
        var row = await f.RowAsync("tok-404");
        Assert.True(JsonNode.DeepEquals(JsonNode.Parse("""{"httpStatus":404,"error":{"code":404}}"""),
            JsonNode.Parse(row!.RawResponse!)));
    }

    [Fact]
    public async Task RecordFailureDoesNotBreakVerify()
    {
        // NUL karakteri Postgres metnine yazılamaz: kayıt düşer, yanıt yine döner.
        var c = Client(Factory());
        AssertResult(await PostVerify(c, Body("tok-\u0000-nul")), null, "unverified", "service_account_missing");
    }

    [Fact]
    public async Task RateLimit()
    {
        var time = new ManualTime();
        var c = Client(Factory(new Dictionary<string, string> { ["RATE_LIMIT_PER_MINUTE"] = "3" }, time: time));

        async Task<HttpResponseMessage> Post(string ip)
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, "/v1/purchases/verify")
            {
                Content = JsonContent.Create(Body("tok-rate")),
            };
            req.Headers.Add("X-Forwarded-For", ip);
            return await c.SendAsync(req);
        }

        var codes = new List<int>();
        for (var i = 0; i < 4; i++)
        {
            codes.Add((int)(await Post("198.51.100.1")).StatusCode);
            time.Advance(TimeSpan.FromSeconds(10));
        }
        Assert.Equal([200, 200, 200, 429], codes);

        var limited = await Post("198.51.100.1");
        Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode);
        Assert.Equal("""{"error":"rate_limited"}""", await limited.Content.ReadAsStringAsync());
        // İlk istek 40 sn önce: pencere 20 sn sonra açılır.
        Assert.Equal("21", limited.Headers.GetValues("Retry-After").Single());

        Assert.Equal(HttpStatusCode.OK, (await c.GetAsync("/health")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await Post("198.51.100.2")).StatusCode); // başka IP

        // X-Forwarded-For yoksa X-Real-IP sayılır.
        for (var i = 0; i < 3; i++)
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, "/v1/purchases/verify")
            {
                Content = JsonContent.Create(Body("tok-rate")),
            };
            req.Headers.Add("X-Real-IP", "198.51.100.3");
            Assert.Equal(HttpStatusCode.OK, (await c.SendAsync(req)).StatusCode);
        }
        using (var req = new HttpRequestMessage(HttpMethod.Post, "/v1/purchases/verify")
               {
                   Content = JsonContent.Create(Body("tok-rate")),
               })
        {
            req.Headers.Add("X-Real-IP", "198.51.100.3");
            Assert.Equal(HttpStatusCode.TooManyRequests, (await c.SendAsync(req)).StatusCode);
        }

        // Kayan pencere: ilk istekten 60 sn sonra yeniden izin.
        time.Advance(TimeSpan.FromSeconds(20));
        Assert.Equal(HttpStatusCode.OK, (await Post("198.51.100.1")).StatusCode);
    }
}
