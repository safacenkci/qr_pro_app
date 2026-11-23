using System.Text;
using System.Text.RegularExpressions;

namespace QrPro.Api.Privacy;

/// <summary>Gizlilik politikası (privacy.html) ve veri silme (delete.html) sayfaları: Türkçe + İngilizce.</summary>
public static partial class PrivacyPage
{
    public const string EffectiveDate = "2026-11-24";

    private const string FallbackTr = "Google Play mağaza sayfasındaki geliştirici iletişim adresi";
    private const string FallbackEn = "the developer contact address on the Google Play store page";

    private static readonly string Template = LoadTemplate("privacy.html");
    private static readonly string DeleteTemplate = LoadTemplate("delete.html");

    public static string Render(string contactEmail, string developerName = AppSettings.DefaultDeveloperName) =>
        Fill(Template, contactEmail, developerName);

    public static string RenderDelete(string contactEmail, string developerName = AppSettings.DefaultDeveloperName) =>
        Fill(DeleteTemplate, contactEmail, developerName);

    private static string Fill(string template, string contactEmail, string developerName)
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
        var developer = HtmlEscape(developerName);
        return Placeholder().Replace(template, m => m.Groups[1].Value switch
        {
            "date" => EffectiveDate,
            "developer" => developer,
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

    private static string LoadTemplate(string name)
    {
        using var stream = typeof(PrivacyPage).Assembly.GetManifestResourceStream($"QrPro.Api.Privacy.{name}")
                           ?? throw new InvalidOperationException($"{name} gömülü kaynağı bulunamadı");
        using var reader = new StreamReader(stream, Encoding.UTF8);
        return reader.ReadToEnd();
    }

    [GeneratedRegex(@"\{(date|developer|contact_tr|contact_en)\}")]
    private static partial Regex Placeholder();
}
