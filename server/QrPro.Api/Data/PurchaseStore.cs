using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;

namespace QrPro.Api.Data;

/// <summary>Her doğrulama isteği `purchases` tablosuna yazılır (token başına tek satır, upsert).</summary>
public sealed class PurchaseStore(QrProDbContext db)
{
    // Aynı token yeniden gelirse satır güncellenir. Google'ın yanıtına dayanan bir sonuç (raw_response dolu),
    // Google'a hiç sorulmadan verilen bir sonuçla (paket uyuşmazlığı, anahtar yok, ağ hatası) ezilmez: başkası
    // bildiği bir token'ı yanlış paket adıyla göndererek doğrulanmış kaydı bozamasın.
    private const string Upsert = """
        INSERT INTO purchases (token, package_name, product_id, order_id, status, reason, raw_response,
                               request_count, created_at, updated_at)
        VALUES (@token, @package_name, @product_id, @order_id, @status, @reason, @raw_response,
                1, @now, @now)
        ON CONFLICT (token) DO UPDATE SET
            package_name  = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                                 THEN purchases.package_name ELSE excluded.package_name END,
            product_id    = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                                 THEN purchases.product_id ELSE excluded.product_id END,
            order_id      = COALESCE(excluded.order_id, purchases.order_id),
            status        = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                                 THEN purchases.status ELSE excluded.status END,
            reason        = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                                 THEN purchases.reason ELSE excluded.reason END,
            raw_response  = COALESCE(excluded.raw_response, purchases.raw_response),
            request_count = purchases.request_count + 1,
            updated_at    = excluded.updated_at
        """;

    public async Task RecordAsync(
        string token,
        string packageName,
        string productId,
        string? orderId,
        string status,
        string? reason,
        string? rawResponse,
        CancellationToken ct = default)
    {
        object[] parameters =
        [
            Text("token", token),
            Text("package_name", packageName),
            Text("product_id", productId),
            Text("order_id", orderId),
            Text("status", status),
            Text("reason", reason),
            new NpgsqlParameter("raw_response", NpgsqlDbType.Jsonb) { Value = (object?)rawResponse ?? DBNull.Value },
            new NpgsqlParameter("now", NpgsqlDbType.TimestampTz) { Value = DateTimeOffset.UtcNow },
        ];
        await db.Database.ExecuteSqlRawAsync(Upsert, parameters, ct);
    }

    private static NpgsqlParameter Text(string name, string? value) =>
        new(name, NpgsqlDbType.Text) { Value = (object?)value ?? DBNull.Value };
}
