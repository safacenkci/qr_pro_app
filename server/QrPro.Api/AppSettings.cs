using System.Globalization;

namespace QrPro.Api;

/// <summary>Ortam değişkenlerinden okunan ayarlar (adlar ve varsayılanlar eski Python sürümüyle aynı).</summary>
public sealed record AppSettings
{
    public string PackageName { get; init; } = "com.safarahmancenkci.qrpro";
    public string ProductId { get; init; } = "qr_pro_lifetime";
    public string ServiceAccountFile { get; init; } = "/secrets/play-service-account.json";
    public const string DefaultDeveloperName = "Safa Rahman Cenkci";

    public string ContactEmail { get; init; } = "";

    /// <summary>Play Console'daki geliştirici adı; gizlilik ve veri silme sayfalarında görünür.</summary>
    public string DeveloperName { get; init; } = DefaultDeveloperName;

    // Kötüye kullanım koruması.
    public int MaxBodyBytes { get; init; } = 8 * 1024;
    public int RateLimitPerMinute { get; init; } = 30;

    // Google Play Developer API isteklerinin zaman aşımı (saniye).
    public int GoogleTimeoutSeconds { get; init; } = 10;

    public static AppSettings From(IConfiguration config)
    {
        var d = new AppSettings();
        return new AppSettings
        {
            PackageName = config["PACKAGE_NAME"] ?? d.PackageName,
            ProductId = config["PRODUCT_ID"] ?? d.ProductId,
            ServiceAccountFile = config["SERVICE_ACCOUNT_FILE"] ?? d.ServiceAccountFile,
            ContactEmail = (config["CONTACT_EMAIL"] ?? "").Trim(),
            DeveloperName = string.IsNullOrWhiteSpace(config["DEVELOPER_NAME"])
                ? d.DeveloperName
                : config["DEVELOPER_NAME"]!.Trim(),
            MaxBodyBytes = Int(config, "MAX_BODY_BYTES", d.MaxBodyBytes),
            RateLimitPerMinute = Int(config, "RATE_LIMIT_PER_MINUTE", d.RateLimitPerMinute),
            GoogleTimeoutSeconds = Int(config, "GOOGLE_TIMEOUT", d.GoogleTimeoutSeconds),
        };
    }

    /// <summary>Sayı değilse varsayılana döner.</summary>
    private static int Int(IConfiguration config, string name, int fallback)
    {
        var value = config[name];
        return value is not null
               && int.TryParse(value.Trim(), NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out var n)
            ? n
            : fallback;
    }
}
