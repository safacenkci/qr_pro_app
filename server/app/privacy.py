"""QR Pro gizlilik politikası: Türkçe ve İngilizce, tek HTML sayfası."""

from html import escape

EFFECTIVE_DATE = "2026-11-23"

_FALLBACK_TR = "Google Play mağaza sayfasındaki geliştirici iletişim adresi"
_FALLBACK_EN = "the developer contact address on the Google Play store page"

_TEMPLATE = """<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>QR Pro – Gizlilik Politikası / Privacy Policy</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; line-height: 1.6;
         max-width: 44rem; margin: 0 auto; padding: 1.25rem; font-size: 1.05rem; }}
  h1 {{ font-size: 1.5rem; margin-bottom: .25rem; }}
  h2 {{ font-size: 1.25rem; margin-top: 2.5rem; padding-top: 1rem; border-top: 1px solid #8884; }}
  h3 {{ font-size: 1.05rem; margin: 1.5rem 0 .25rem; }}
  p, li {{ margin: .4rem 0; }}
  ul {{ padding-left: 1.25rem; }}
  nav a {{ margin-right: 1rem; }}
  .meta {{ opacity: .75; font-size: .95rem; }}
  a {{ word-break: break-word; }}
</style>
</head>
<body>
<h1>QR Pro</h1>
<p class="meta">Yürürlük tarihi / Effective date: {date}</p>
<nav><a href="#tr">Türkçe</a><a href="#en" lang="en">English</a></nav>

<section id="tr">
<h2>Gizlilik Politikası</h2>
<p>Bu politika, Android için QR Pro uygulamasının (“Uygulama”) hangi bilgileri nasıl kullandığını açıklar.</p>

<h3>İzinler</h3>
<ul>
  <li><strong>Kamera:</strong> Yalnızca QR kod taramak için kullanılır. Görüntüler cihazınızda işlenir;
      hiçbir yere gönderilmez ve saklanmaz.</li>
  <li><strong>Fotoğraflar / galeri:</strong> Yalnızca galeriden seçtiğiniz bir görseldeki QR kodu okumak ve
      oluşturduğunuz QR kodu galeriye kaydetmek için kullanılır.</li>
  <li><strong>Konum:</strong> Yalnızca Android 12 ve daha eski sürümlerde, bir Wi‑Fi QR koduyla ağa
      bağlanırken Android bu izni zorunlu tuttuğu için istenir. Konumunuz toplanmaz ve gönderilmez.</li>
</ul>

<h3>Cihazda kalan veriler</h3>
<p>Tarama ve oluşturma geçmişiniz yalnızca cihazınızda saklanır; bize gönderilmez.
   Uygulamayı kaldırdığınızda ya da uygulama verilerini sildiğinizde bu geçmiş de silinir.</p>

<h3>Premium satın alımı</h3>
<p>Ödemeyi Google Play işler; kart ve ödeme bilgileriniz bize ulaşmaz. Premium satın aldığınızda,
   satın alımı doğrulamak için Google Play satın alma jetonu (purchase token), ürün kimliği ve sipariş
   numarası bu sunucuya gönderilir ve doğrulama kaydı olarak saklanır.</p>

<h3>Toplamadığımız bilgiler</h3>
<ul>
  <li>Adınız, e-posta adresiniz ya da başka kişisel bilgileriniz toplanmaz.</li>
  <li>Reklam, analitik ya da üçüncü taraf izleme araçları yoktur.</li>
</ul>

<h3>Silme talebi ve iletişim</h3>
<p>Satın alma kaydınızın silinmesini istemek ya da soru sormak için {contact_tr} üzerinden bize
   yazabilirsiniz. Talebinizde sipariş numaranızı belirtmeniz kaydı bulmamızı kolaylaştırır.</p>

<h3>Değişiklikler</h3>
<p>Bu politika değişirse güncel sürüm bu sayfada yayımlanır ve yürürlük tarihi güncellenir.</p>
</section>

<section id="en" lang="en">
<h2>Privacy Policy</h2>
<p>This policy explains what information the QR Pro app for Android (“the App”) uses and how.</p>

<h3>Permissions</h3>
<ul>
  <li><strong>Camera:</strong> Used only to scan QR codes. Images are processed on your device; they are
      never sent anywhere or stored.</li>
  <li><strong>Photos / gallery:</strong> Used only to read a QR code from an image you pick from your gallery
      and to save a QR code you create to your gallery.</li>
  <li><strong>Location:</strong> Requested only on Android 12 and earlier, because Android requires it to
      connect to a network from a Wi‑Fi QR code. Your location is not collected or sent.</li>
</ul>

<h3>Data that stays on your device</h3>
<p>Your scan and creation history is stored only on your device and is never sent to us.
   Uninstalling the App or clearing its data deletes this history.</p>

<h3>Premium purchase</h3>
<p>Payments are processed by Google Play; your card and payment details never reach us. When you buy
   Premium, the Google Play purchase token, product ID and order number are sent to this server to verify
   the purchase and are stored as a verification record.</p>

<h3>What we do not collect</h3>
<ul>
  <li>We do not collect your name, email address or any other personal information.</li>
  <li>There are no ads, no analytics and no third-party tracking.</li>
</ul>

<h3>Deletion requests and contact</h3>
<p>To ask for your purchase record to be deleted, or for any question, write to us at {contact_en}.
   Including your order number helps us find the record.</p>

<h3>Changes</h3>
<p>If this policy changes, the current version will be published on this page with an updated effective
   date.</p>
</section>
</body>
</html>
"""


def render_privacy(contact_email: str) -> str:
    if contact_email:
        safe = escape(contact_email)
        link = f'<a href="mailto:{safe}">{safe}</a>'
        contact_tr = contact_en = link
    else:
        contact_tr, contact_en = _FALLBACK_TR, _FALLBACK_EN
    return _TEMPLATE.format(date=EFFECTIVE_DATE, contact_tr=contact_tr, contact_en=contact_en)
