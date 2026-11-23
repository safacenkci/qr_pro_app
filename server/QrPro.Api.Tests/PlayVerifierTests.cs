using System.Text.Json.Nodes;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using QrPro.Api.Play;
using QrPro.Api.Privacy;
using static QrPro.Api.Tests.Consts;

namespace QrPro.Api.Tests;

/// <summary>Google yanıtlarının sonuca çevrilmesi (veritabanı gerekmez).</summary>
public sealed class PlayVerifierTests
{
    private static PlayVerifier Verifier(IPlayPublisher? publisher) =>
        new(new FakeSource(publisher), NullLogger<PlayVerifier>.Instance);

    private static void AssertResult(VerifyResult r, bool? valid, string status, string? reason) =>
        Assert.Equal((valid, status, reason), (r.Valid, r.Status, r.Reason));

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    public async Task VerifiedReadOnly(int acknowledgementState)
    {
        // Onaylanmamış satın almada da sunucu yalnızca okur (onayı uygulama yapar).
        var p = FakePublisher.Json(200,
            $$"""{"purchaseState":0,"acknowledgementState":{{acknowledgementState}},"consumptionState":0}""");
        var r = await Verifier(p).VerifyAsync(Pkg, Product, "t/1");
        AssertResult(r, true, "verified", null);
        Assert.Equal([(Pkg, Product, "t/1")], p.Gets);
        Assert.Equal(0, r.Raw!["purchaseState"]!.GetValue<int>());
    }

    public static TheoryData<int, string, bool?, string, string> States => new()
    {
        { 200, """{"purchaseState":1}""", false, "invalid", "canceled" },
        { 200, """{"purchaseState":2}""", false, "invalid", "pending" },
        { 200, """{"purchaseState":7}""", false, "invalid", "unknown_state" },
        { 200, """{"kind":"x"}""", false, "invalid", "unknown_state" },
        { 200, """{"purchaseState":0,"consumptionState":1}""", false, "invalid", "consumed" },
        { 200, "bozuk", null, "unverified", "google_bad_response" },
        { 200, "[1]", null, "unverified", "google_bad_response" },
        { 400, """{"error":{"code":400}}""", false, "invalid", "purchase_not_found" },
        { 404, """{"error":{"code":404}}""", false, "invalid", "purchase_not_found" },
        { 410, """{"error":{"code":410}}""", false, "invalid", "purchase_not_found" },
        { 503, """{"error":{"code":503}}""", null, "unverified", "google_error_503" },
        { 500, "sunucu hatası", null, "unverified", "google_error_500" },
        { 429, """{"error":{"code":429}}""", null, "unverified", "google_error_429" },
        { 403, """{"error":{"code":403}}""", null, "unverified", "google_permission_denied" },
        { 401, """{"error":{"code":401}}""", null, "unverified", "google_permission_denied" },
    };

    [Theory]
    [MemberData(nameof(States))]
    public async Task PlayStates(int status, string body, bool? valid, string expectedStatus, string reason)
    {
        var p = FakePublisher.Json(status, body);
        AssertResult(await Verifier(p).VerifyAsync(Pkg, Product, "t"), valid, expectedStatus, reason);
    }

    [Fact]
    public async Task ErrorRawKeepsStatusAndText()
    {
        var r = await Verifier(FakePublisher.Json(502, new string('ş', 2500))).VerifyAsync(Pkg, Product, "t");
        Assert.Equal(502, r.Raw!["httpStatus"]!.GetValue<int>());
        Assert.Equal(2000, r.Raw["text"]!.GetValue<string>().Length);

        r = await Verifier(FakePublisher.Json(503, """{"error":{"code":503,"message":"m"}}""")).VerifyAsync(Pkg, Product, "t");
        Assert.True(JsonNode.DeepEquals(JsonNode.Parse("""{"httpStatus":503,"error":{"code":503,"message":"m"}}"""), r.Raw));
    }

    public static TheoryData<Exception, string> Failures => new()
    {
        { new HttpRequestException("ag yok"), "google_unreachable" },
        { new TaskCanceledException("zaman aşımı"), "google_unreachable" },
        { new PlayAuthException("invalid_grant"), "google_auth_failed" },
    };

    [Theory]
    [MemberData(nameof(Failures))]
    public async Task NetworkAndAuthFailuresAreUnverified(Exception exception, string reason)
    {
        var p = new FakePublisher(getException: exception);
        AssertResult(await Verifier(p).VerifyAsync(Pkg, Product, "t"), null, "unverified", reason);
    }

    [Fact]
    public async Task MissingKey()
    {
        AssertResult(await Verifier(null).VerifyAsync(Pkg, Product, "t"), null, "unverified", "service_account_missing");
    }

    [Theory]
    [InlineData("bozuk")]
    [InlineData("""{"type":"service_account"}""")]
    public async Task UnreadableKey(string content)
    {
        var path = Path.Combine(Path.GetTempPath(), "qrpro-key-" + Guid.NewGuid() + ".json");
        await File.WriteAllTextAsync(path, content);
        try
        {
            var settings = new AppSettings { ServiceAccountFile = path };
            using var source = new ServiceAccountPublisherSource(settings);
            Assert.True(source.IsConfigured);
            var r = await new PlayVerifier(source, NullLogger<PlayVerifier>.Instance).VerifyAsync(Pkg, Product, "t");
            AssertResult(r, null, "unverified", "service_account_unreadable");
        }
        finally
        {
            File.Delete(path);
        }
    }

    [Fact]
    public void GoogleRequestUrls()
    {
        using var service = GooglePlayPublisher.CreateService(null);
        using var get = GooglePlayPublisher.CreateGetRequest(service, Pkg, Product, "t/1");
        Assert.Equal(HttpMethod.Get, get.Method);
        var url = get.RequestUri!.AbsoluteUri;
        Assert.StartsWith("https://androidpublisher.googleapis.com/androidpublisher/v3/applications/", url);
        Assert.EndsWith($"/applications/{Pkg}/purchases/products/{Product}/tokens/t%2F1", url);
    }
}

public sealed class SettingsAndPrivacyTests
{
    private static AppSettings From(Dictionary<string, string?> values) =>
        AppSettings.From(new ConfigurationBuilder().AddInMemoryCollection(values).Build());

    [Fact]
    public void Defaults()
    {
        var s = From([]);
        Assert.Equal((Pkg, Product, "/secrets/play-service-account.json", "", 8192, 30, 10),
            (s.PackageName, s.ProductId, s.ServiceAccountFile, s.ContactEmail, s.MaxBodyBytes, s.RateLimitPerMinute,
                s.GoogleTimeoutSeconds));
    }

    [Fact]
    public void InvalidIntegersFallBack()
    {
        var s = From(new() { ["MAX_BODY_BYTES"] = "çok", ["RATE_LIMIT_PER_MINUTE"] = " 5 ", ["CONTACT_EMAIL"] = " x@y.z " });
        Assert.Equal((8192, 5, "x@y.z"), (s.MaxBodyBytes, s.RateLimitPerMinute, s.ContactEmail));
    }

    [Fact]
    public void PrivacyRender()
    {
        var fallback = PrivacyPage.Render("");
        Assert.StartsWith("<!doctype html>\n<html lang=\"tr\">", fallback);
        Assert.EndsWith("</body>\n</html>\n", fallback);
        Assert.Contains("Yürürlük tarihi / Effective date: 2026-11-24", fallback);
        Assert.Contains("write to the developer contact address on the Google Play store page.", fallback);

        var html = PrivacyPage.Render("o'k\"{contact_en}&@x.com");
        Assert.Contains("mailto:o&#x27;k&quot;{contact_en}&amp;@x.com", html);
    }
}
