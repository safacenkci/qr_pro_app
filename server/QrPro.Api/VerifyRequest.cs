using System.Text.Json;
using System.Text.Json.Nodes;

namespace QrPro.Api;

/// <summary>
/// <c>POST /v1/purchases/verify</c> gövdesi. Bilinmeyen alanlar yok sayılır. Geçersiz gövdede eski sürüm gibi
/// 422 ve <c>{"detail": [{"type", "loc", "msg"}]}</c> döner.
/// </summary>
public sealed record VerifyRequest(string PackageName, string ProductId, string PurchaseToken, string? OrderId)
{
    public static (VerifyRequest? Request, JsonObject? Errors) Parse(ReadOnlySpan<byte> body)
    {
        var errors = new JsonArray();
        if (body.IsEmpty)
        {
            errors.Add(Error("missing", ["body"], "Field required"));
            return (null, Detail(errors));
        }

        JsonNode? root;
        try
        {
            root = JsonNode.Parse(body);
        }
        catch (JsonException)
        {
            errors.Add(Error("json_invalid", ["body"], "JSON decode error"));
            return (null, Detail(errors));
        }
        if (root is not JsonObject obj)
        {
            errors.Add(Error("model_attributes_type", ["body"],
                "Input should be a valid dictionary or object to extract fields from"));
            return (null, Detail(errors));
        }

        var packageName = Field(obj, "packageName", required: true, 1, 255, errors);
        var productId = Field(obj, "productId", required: true, 1, 255, errors);
        var purchaseToken = Field(obj, "purchaseToken", required: true, 1, 4096, errors);
        var orderId = Field(obj, "orderId", required: false, 0, 255, errors);
        if (errors.Count > 0)
        {
            return (null, Detail(errors));
        }
        return (new VerifyRequest(packageName!, productId!, purchaseToken!, orderId), null);
    }

    private static string? Field(JsonObject obj, string name, bool required, int min, int max, JsonArray errors)
    {
        if (!obj.TryGetPropertyValue(name, out var node))
        {
            if (required)
            {
                errors.Add(Error("missing", ["body", name], "Field required"));
            }
            return null;
        }
        if (node is null && !required)
        {
            return null;
        }
        if (node is not JsonValue value || value.GetValueKind() != JsonValueKind.String)
        {
            errors.Add(Error("string_type", ["body", name], "Input should be a valid string"));
            return null;
        }
        var text = value.GetValue<string>();
        // Uzunluk Python'daki gibi Unicode kod noktası sayısıdır.
        var length = text.EnumerateRunes().Count();
        if (length < min)
        {
            errors.Add(Error("string_too_short", ["body", name],
                $"String should have at least {min} character{(min == 1 ? "" : "s")}"));
            return null;
        }
        if (length > max)
        {
            errors.Add(Error("string_too_long", ["body", name], $"String should have at most {max} characters"));
            return null;
        }
        return text;
    }

    private static JsonObject Error(string type, string[] loc, string msg) => new()
    {
        ["type"] = type,
        ["loc"] = new JsonArray(loc.Select(l => (JsonNode)JsonValue.Create(l)).ToArray()),
        ["msg"] = msg,
    };

    private static JsonObject Detail(JsonArray errors) => new() { ["detail"] = errors };
}
