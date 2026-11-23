namespace QrPro.Api.Data;

/// <summary>`purchases` tablosunun bir satırı: token başına tek kayıt.</summary>
public sealed class Purchase
{
    public long Id { get; set; }
    public required string Token { get; set; }
    public required string PackageName { get; set; }
    public required string ProductId { get; set; }
    public string? OrderId { get; set; }
    public required string Status { get; set; }
    public string? Reason { get; set; }

    /// <summary>Google'ın ham yanıtı (jsonb). Google'a hiç sorulmadıysa boş.</summary>
    public string? RawResponse { get; set; }

    /// <summary>Son isteği gönderen istemcinin IP adresi.</summary>
    public string? ClientIp { get; set; }

    public int RequestCount { get; set; } = 1;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
