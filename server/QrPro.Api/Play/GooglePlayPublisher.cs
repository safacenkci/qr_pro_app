using Google.Apis.AndroidPublisher.v3;
using Google.Apis.AndroidPublisher.v3.Data;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Auth.OAuth2.Responses;
using Google.Apis.Http;
using Google.Apis.Services;

namespace QrPro.Api.Play;

/// <summary>
/// Gerçek Google Play Developer API istemcisi. İstekler kütüphanenin kurduğu URL ve kimlik doğrulamasıyla
/// gönderilir, ama yanıt ham olarak alınır: hata kodları istisnaya çevrilmez, ham gövde kayda geçer.
/// </summary>
public sealed class GooglePlayPublisher : IPlayPublisher, IDisposable
{
    private readonly AndroidPublisherService _service;

    public GooglePlayPublisher(IConfigurableHttpClientInitializer? credential, TimeSpan timeout)
    {
        _service = CreateService(credential);
        _service.HttpClient.Timeout = timeout;
    }

    public static AndroidPublisherService CreateService(IConfigurableHttpClientInitializer? credential) =>
        new(new BaseClientService.Initializer
        {
            HttpClientInitializer = credential,
            ApplicationName = "QrPro",
            // 503'te kendiliğinden yeniden deneme yok: sonuç hemen `unverified` olur.
            DefaultExponentialBackOffPolicy = ExponentialBackOffPolicy.None,
        });

    public static HttpRequestMessage CreateGetRequest(AndroidPublisherService service, string packageName,
        string productId, string token) =>
        service.Purchases.Products.Get(packageName, productId, token).CreateRequest();

    public async Task<PlayHttpResponse> GetProductPurchaseAsync(string packageName, string productId,
        string token, CancellationToken ct = default)
    {
        using var request = CreateGetRequest(_service, packageName, productId, token);
        using var response = await SendAsync(request, ct);
        var body = await response.Content.ReadAsStringAsync(ct);
        return new PlayHttpResponse((int)response.StatusCode, body);
    }

    private async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
    {
        try
        {
            return await _service.HttpClient.SendAsync(request, ct);
        }
        catch (TokenResponseException ex)
        {
            throw new PlayAuthException(ex.Message, ex);
        }
    }

    public void Dispose() => _service.Dispose();
}

/// <summary>
/// Servis hesabı JSON anahtarından <see cref="GooglePlayPublisher"/> kurar. Anahtar dosyası ilk kez görüldüğünde
/// istemci kurulur ve saklanır; dosya yoksa her istekte yeniden bakılır.
/// </summary>
public sealed class ServiceAccountPublisherSource(AppSettings settings) : IPlayPublisherSource, IDisposable
{
    private readonly Lock _lock = new();
    private GooglePlayPublisher? _publisher;

    public string Path => settings.ServiceAccountFile;

    public bool IsConfigured => File.Exists(Path);

    public IPlayPublisher? TryGet()
    {
        if (_publisher is not null)
        {
            return _publisher;
        }
        lock (_lock)
        {
            if (_publisher is null && File.Exists(Path))
            {
                var credential = CredentialFactory.FromFile<ServiceAccountCredential>(Path)
                    .ToGoogleCredential()
                    .CreateScoped(AndroidPublisherService.Scope.Androidpublisher);
                _publisher = new GooglePlayPublisher(credential, TimeSpan.FromSeconds(settings.GoogleTimeoutSeconds));
            }
            return _publisher;
        }
    }

    public void Dispose() => _publisher?.Dispose();
}
