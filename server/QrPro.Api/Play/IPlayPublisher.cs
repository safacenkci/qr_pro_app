namespace QrPro.Api.Play;

/// <summary>
/// Google Play Developer API'nin (androidpublisher v3) kullandığımız tek çağrısı (salt okuma). Testlerde taklit edilir.
/// </summary>
public interface IPlayPublisher
{
    /// <summary>
    /// purchases.products.get. HTTP durum kodunu ve ham gövdeyi döner (hata kodlarında istisna atmaz).
    /// Erişim belirteci alınamazsa <see cref="PlayAuthException"/>, ağ hatasında
    /// <see cref="HttpRequestException"/>, zaman aşımında <see cref="TaskCanceledException"/> atar.
    /// </summary>
    Task<PlayHttpResponse> GetProductPurchaseAsync(string packageName, string productId, string token,
        CancellationToken ct = default);
}

/// <summary>Servis hesabı anahtarından <see cref="IPlayPublisher"/> kurar.</summary>
public interface IPlayPublisherSource
{
    /// <summary>Anahtar dosyasının yolu (günlükler için).</summary>
    string Path { get; }

    /// <summary>Anahtar dosyası var mı.</summary>
    bool IsConfigured { get; }

    /// <summary>
    /// Anahtar dosyası yoksa null (her çağrıda yeniden bakılır). Dosya var ama okunamıyorsa istisna atar.
    /// </summary>
    IPlayPublisher? TryGet();
}

public sealed record PlayHttpResponse(int StatusCode, string Body);

/// <summary>Google erişim belirteci alınamadı (geçersiz ya da iptal edilmiş servis hesabı anahtarı).</summary>
public sealed class PlayAuthException(string message, Exception? inner = null) : Exception(message, inner);
