using System.Text.Json;
using System.Text.Json.Nodes;

namespace QrPro.Api.Play;

/// <summary>Doğrulama sonucu. <c>Raw</c>: Google'ın ham yanıtı (Google'a hiç sorulmadıysa null).</summary>
public sealed record VerifyResult(bool? Valid, string Status, string? Reason, JsonObject? Raw = null)
{
    public static VerifyResult Unverified(string reason, JsonObject? raw = null) => new(null, "unverified", reason, raw);

    public static VerifyResult Invalid(string reason, JsonObject? raw = null) => new(false, "invalid", reason, raw);
}

/// <summary>
/// Google Play Developer API (androidpublisher v3) ile tek seferlik ürün satın alımı doğrulama.
///
/// Servis hesabı anahtarı yoksa, okunamıyorsa ya da Google'a ulaşılamıyorsa sonuç <c>unverified</c> olur
/// (valid=null): istemci bu durumda Play'in kendi sonucuna güvenir. Google'ın kesin olarak "geçersiz" dediği
/// durumlar (token yok, iptal, iade, bekleyen ödeme, tüketilmiş) <c>invalid</c> (valid=false) olur.
/// </summary>
public sealed class PlayVerifier(IPlayPublisherSource source, ILogger<PlayVerifier> log)
{
    public bool IsConfigured => source.IsConfigured;

    public string ServiceAccountPath => source.Path;

    public async Task<VerifyResult> VerifyAsync(string packageName, string productId, string token)
    {
        IPlayPublisher? publisher;
        try
        {
            publisher = source.TryGet();
        }
        catch (Exception ex)
        {
            log.LogError("Servis hesabı anahtarı okunamadı ({Path}): {Error}", source.Path, ex.Message);
            return VerifyResult.Unverified("service_account_unreadable");
        }
        if (publisher is null)
        {
            return VerifyResult.Unverified("service_account_missing");
        }

        PlayHttpResponse resp;
        try
        {
            resp = await publisher.GetProductPurchaseAsync(packageName, productId, token);
        }
        catch (PlayAuthException ex)
        {
            log.LogError("Google erişim belirteci alınamadı: {Error}", ex.Message);
            return VerifyResult.Unverified("google_auth_failed");
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or IOException)
        {
            log.LogWarning("Google Play API'ye ulaşılamadı: {Error}", ex.Message);
            return VerifyResult.Unverified("google_unreachable");
        }

        if (resp.StatusCode != 200)
        {
            var raw = JsonOrText(resp);
            if (resp.StatusCode is 400 or 404 or 410)
            {
                return VerifyResult.Invalid("purchase_not_found", raw);
            }
            if (resp.StatusCode is 401 or 403)
            {
                // Yapılandırma sorunu (izin verilmemiş servis hesabı): kullanıcıyı cezalandırma.
                log.LogError("Google Play API izin hatası {Status}: {Raw}", resp.StatusCode, raw.ToJsonString());
                return VerifyResult.Unverified("google_permission_denied", raw);
            }
            log.LogWarning("Google Play API hatası {Status}", resp.StatusCode);
            return VerifyResult.Unverified($"google_error_{resp.StatusCode}", raw);
        }

        if (ParseObject(resp.Body) is not { } data)
        {
            return VerifyResult.Unverified("google_bad_response");
        }

        // ProductPurchase.purchaseState: 0 satın alındı, 1 iptal (iade/geri ödeme dahil), 2 bekliyor.
        var state = Number(data, "purchaseState");
        if (state != 0)
        {
            var reason = state switch
            {
                1 => "canceled",
                2 => "pending",
                _ => "unknown_state",
            };
            return VerifyResult.Invalid(reason, data);
        }
        if (Number(data, "consumptionState") == 1)
        {
            // Ömür boyu ürün tüketilmişse kullanıcı artık ona sahip değildir.
            return VerifyResult.Invalid("consumed", data);
        }

        string? ackReason = null;
        if (Number(data, "acknowledgementState") == 0
            && !await AcknowledgeAsync(publisher, packageName, productId, token))
        {
            ackReason = "acknowledge_failed";
        }
        return new VerifyResult(true, "verified", ackReason, data);
    }

    private async Task<bool> AcknowledgeAsync(IPlayPublisher publisher, string packageName, string productId,
        string token)
    {
        int status;
        try
        {
            status = await publisher.AcknowledgeAsync(packageName, productId, token);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or IOException
                                       or PlayAuthException)
        {
            log.LogWarning("Onaylama (acknowledge) isteği başarısız: {Error}", ex.Message);
            return false;
        }
        if (status is not (200 or 204))
        {
            log.LogWarning("Onaylama (acknowledge) hatası {Status}", status);
            return false;
        }
        return true;
    }

    /// <summary>Hata yanıtı: JSON nesnesiyse <c>{"httpStatus": kod, ...gövde}</c>, değilse metnin ilk 2000 karakteri.</summary>
    private static JsonObject JsonOrText(PlayHttpResponse resp)
    {
        var raw = new JsonObject { ["httpStatus"] = resp.StatusCode };
        if (ParseObject(resp.Body) is { } data)
        {
            foreach (var (key, value) in data.ToList())
            {
                data.Remove(key);
                raw[key] = value;
            }
            return raw;
        }
        raw["text"] = Truncate(resp.Body, 2000);
        return raw;
    }

    private static JsonObject? ParseObject(string body)
    {
        try
        {
            return JsonNode.Parse(body) as JsonObject;
        }
        catch (JsonException)
        {
            return null;
        }
    }

    /// <summary>Alan sayıysa değeri, değilse (yok, metin, null) null.</summary>
    private static double? Number(JsonObject data, string name) =>
        data[name] is JsonValue v && v.GetValueKind() == JsonValueKind.Number ? v.GetValue<double>() : null;

    private static string Truncate(string text, int max)
    {
        if (text.Length <= max)
        {
            return text;
        }
        // Vekil çiftini ortadan bölme.
        return char.IsHighSurrogate(text[max - 1]) ? text[..(max - 1)] : text[..max];
    }
}
