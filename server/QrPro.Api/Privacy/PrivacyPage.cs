using System.Text;
using System.Text.RegularExpressions;

namespace QrPro.Api.Privacy;

/// <summary>QR Pro gizlilik politikası: Türkçe ve İngilizce, tek HTML sayfası (şablon: privacy.html).</summary>
public static partial class PrivacyPage
{
    public const string EffectiveDate = "2026-11-23";

    private const string FallbackTr = "Google Play mağaza sayfasındaki geliştirici iletişim adresi";
    private const string FallbackEn = "the developer contact address on the Google Play store page";

    private static readonly string Template = LoadTemplate();

    public static string Render(string contactEmail)
    {
        string contactTr, contactEn;
        if (contactEmail.Length > 0)
        {
            var safe = HtmlEscape(contactEmail);
            contactTr = contactEn = $"<a href=\"mailto:{safe}\">{safe}</a>";
        }
        else
        {
            (contactTr, contactEn) = (FallbackTr, FallbackEn);
        }
        // Tek geçişte yer değiştirme: adresin içindeki bir "{...}" yeniden yorumlanmaz.
        return Placeholder().Replace(Template, m => m.Groups[1].Value switch
        {
            "date" => EffectiveDate,
            "contact_tr" => contactTr,
            _ => contactEn,
        });
    }

    /// <summary>Python'un html.escape(quote=True) davranışı: &amp; &lt; &gt; " '.</summary>
    public static string HtmlEscape(string text)
    {
        var sb = new StringBuilder(text.Length + 16);
        foreach (var c in text)
        {
            sb.Append(c switch
            {
                '&' => "&amp;",
                '<' => "&lt;",
                '>' => "&gt;",
                '"' => "&quot;",
                '\'' => "&#x27;",
                _ => c.ToString(),
            });
        }
        return sb.ToString();
    }

    private static string LoadTemplate()
    {
        using var stream = typeof(PrivacyPage).Assembly.GetManifestResourceStream("QrPro.Api.Privacy.privacy.html")
                           ?? throw new InvalidOperationException("privacy.html gömülü kaynağı bulunamadı");
        using var reader = new StreamReader(stream, Encoding.UTF8);
        return reader.ReadToEnd();
    }

    [GeneratedRegex(@"\{(date|contact_tr|contact_en)\}")]
    private static partial Regex Placeholder();
}
