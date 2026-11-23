using System.Net;

namespace QrPro.Api.Guards;

/// <summary>
/// İstemci IP'si. Konteyner yalnızca 127.0.0.1'e bağlıdır, gelen her bağlantı nginx'tendir; nginx
/// X-Forwarded-For ve X-Real-IP'yi gerçek istemci adresiyle (<c>$remote_addr</c>) doldurur. Sıra eski
/// sürümdekiyle (uvicorn <c>--forwarded-allow-ips *</c>) aynı: X-Forwarded-For'un ilk girdisi; yoksa X-Real-IP;
/// o da yoksa bağlantının adresi.
/// </summary>
public static class ClientIp
{
    public static string Resolve(HttpContext context)
    {
        var forwarded = context.Request.Headers["X-Forwarded-For"].ToString();
        if (forwarded.Length > 0)
        {
            var first = forwarded.Split(',')[0].Trim();
            if (first.Length > 0)
            {
                return first;
            }
        }
        var real = context.Request.Headers["X-Real-IP"].ToString().Trim();
        if (real.Length > 0)
        {
            return real;
        }
        var remote = context.Connection.RemoteIpAddress;
        if (remote is null)
        {
            return "unknown";
        }
        return (remote.IsIPv4MappedToIPv6 ? remote.MapToIPv4() : remote).ToString();
    }
}

/// <summary>Gövdeyi en çok <c>MAX_BODY_BYTES</c> bayta kadar belleğe alır; aşılırsa 413 döner (bütün yollar).</summary>
public sealed class BodySizeLimitMiddleware(RequestDelegate next, AppSettings settings)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var max = settings.MaxBodyBytes;
        if (context.Request.ContentLength is { } length && length > max)
        {
            await Json.WriteAsync(context, StatusCodes.Status413PayloadTooLarge, """{"error":"payload_too_large"}""");
            return;
        }

        var buffer = new MemoryStream();
        var chunk = new byte[4096];
        int read;
        while ((read = await context.Request.Body.ReadAsync(chunk, context.RequestAborted)) > 0)
        {
            if (buffer.Length + read > max)
            {
                await Json.WriteAsync(context, StatusCodes.Status413PayloadTooLarge,
                    """{"error":"payload_too_large"}""");
                return;
            }
            buffer.Write(chunk, 0, read);
        }
        buffer.Position = 0;
        context.Request.Body = buffer;
        await next(context);
    }
}

/// <summary>
/// <c>/v1/</c> ile başlayan yollarda IP başına kayan 60 saniyelik pencerede en çok <c>RATE_LIMIT_PER_MINUTE</c>
/// istek (bellek içi). Aşılırsa 429 ve Retry-After.
/// </summary>
public sealed class RateLimitMiddleware(RequestDelegate next, AppSettings settings, TimeProvider time)
{
    private const string PathPrefix = "/v1/";
    private static readonly TimeSpan Window = TimeSpan.FromSeconds(60);

    private readonly Dictionary<string, Queue<long>> _hits = new();
    private readonly Lock _lock = new();
    private long _lastSweep = time.GetTimestamp();

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Path.Value?.StartsWith(PathPrefix, StringComparison.Ordinal) == true)
        {
            var (allowed, retryAfter) = Allow(ClientIp.Resolve(context));
            if (!allowed)
            {
                context.Response.Headers.RetryAfter = retryAfter.ToString();
                await Json.WriteAsync(context, StatusCodes.Status429TooManyRequests, """{"error":"rate_limited"}""");
                return;
            }
        }
        await next(context);
    }

    private (bool Allowed, int RetryAfter) Allow(string ip)
    {
        var now = time.GetTimestamp();
        lock (_lock)
        {
            if (time.GetElapsedTime(_lastSweep, now) > Window)
            {
                Sweep(now);
            }
            if (!_hits.TryGetValue(ip, out var hits))
            {
                hits = new Queue<long>();
                _hits[ip] = hits;
            }
            while (hits.Count > 0 && time.GetElapsedTime(hits.Peek(), now) >= Window)
            {
                hits.Dequeue();
            }
            if (hits.Count >= settings.RateLimitPerMinute)
            {
                var remaining = (Window - time.GetElapsedTime(hits.Peek(), now)).TotalSeconds;
                return (false, Math.Max(1, (int)remaining + 1));
            }
            hits.Enqueue(now);
            return (true, 0);
        }
    }

    private void Sweep(long now)
    {
        foreach (var (ip, hits) in _hits.ToList())
        {
            if (hits.Count == 0 || time.GetElapsedTime(hits.Last(), now) >= Window)
            {
                _hits.Remove(ip);
            }
        }
        _lastSweep = now;
    }
}

internal static class Json
{
    public static async Task WriteAsync(HttpContext context, int status, string body)
    {
        context.Response.StatusCode = status;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync(body);
    }
}
