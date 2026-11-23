"""Uygulama ikonu ve Google Play mağaza görsellerini üretir.

Kullanım (depo kökünden):
    python tool/generate_store_assets.py
    dart run flutter_launcher_icons

Çıktılar:
    assets/icon/app_icon.png             1024x1024, opak (eski Android ve iOS ikonu)
    assets/icon/app_icon_foreground.png  1024x1024, şeffaf (Android uyarlanabilir ikon ön yüzü)
    store/play_icon_512.png              512x512, Play Console uygulama ikonu
    store/feature_graphic_1024x500.png   Play Console öne çıkan görsel
"""

import os
import random

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = (79, 70, 229)  # AppTheme seed rengi #4F46E5
BRAND_DARK = (55, 48, 163)
INK = (17, 24, 39)
WHITE = (255, 255, 255)
GRID = 21  # QR sürüm 1 ızgarası


def qr_matrix(seed: int = 7) -> list[list[bool]]:
    """Gerçek QR'a benzeyen, sabit (deterministik) bir modül deseni."""
    rnd = random.Random(seed)
    m = [[rnd.random() < 0.45 for _ in range(GRID)] for _ in range(GRID)]

    def finder(ox: int, oy: int) -> None:
        for y in range(-1, 8):
            for x in range(-1, 8):
                gx, gy = ox + x, oy + y
                if not (0 <= gx < GRID and 0 <= gy < GRID):
                    continue
                ring = max(abs(x - 3), abs(y - 3))
                m[gy][gx] = ring in (0, 1, 3)

    finder(0, 0)
    finder(GRID - 7, 0)
    finder(0, GRID - 7)
    # Zamanlama desenleri
    for i in range(8, GRID - 8):
        m[6][i] = m[i][6] = i % 2 == 0
    return m


def draw_qr_plate(canvas: Image.Image, cx: int, cy: int, plate: int) -> None:
    """Merkezi (cx, cy) olan, kenarı `plate` piksel beyaz yuvarlak plaka + QR."""
    d = ImageDraw.Draw(canvas)
    x0, y0 = cx - plate // 2, cy - plate // 2
    d.rounded_rectangle(
        (x0, y0, x0 + plate, y0 + plate), radius=int(plate * 0.16), fill=WHITE
    )
    pad = int(plate * 0.12)
    module = (plate - 2 * pad) / GRID
    m = qr_matrix()
    finders = [(0, 0), (GRID - 7, 0), (0, GRID - 7)]

    def in_finder(gx: int, gy: int) -> bool:
        return any(fx - 1 <= gx <= fx + 7 and fy - 1 <= gy <= fy + 7 for fx, fy in finders)

    for gy in range(GRID):
        for gx in range(GRID):
            if not m[gy][gx] or in_finder(gx, gy):
                continue
            mx0 = x0 + pad + gx * module
            my0 = y0 + pad + gy * module
            d.rectangle((mx0, my0, mx0 + module + 0.5, my0 + module + 0.5), fill=INK)
    for fx, fy in finders:
        fx0 = x0 + pad + fx * module
        fy0 = y0 + pad + fy * module
        for inset, color in ((0, INK), (1, WHITE), (2, INK)):
            a = inset * module
            d.rounded_rectangle(
                (fx0 + a, fy0 + a, fx0 + 7 * module - a, fy0 + 7 * module - a),
                radius=module * (1.6 - inset * 0.45),
                fill=color,
            )
    # Tarama çizgisi vurgusu
    line_y = cy + int(plate * 0.02)
    d.rounded_rectangle(
        (x0 + pad // 2, line_y - plate * 0.018, x0 + plate - pad // 2, line_y + plate * 0.018),
        radius=plate * 0.018,
        fill=BRAND,
    )


def gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size, BRAND)
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w + y / h) / 2
            px[x, y] = tuple(int(BRAND[i] * (1 - t) + BRAND_DARK[i] * t) for i in range(3))
    return img


def font(size: int) -> ImageFont.ImageFont:
    for name in ("segoeuib.ttf", "arialbd.ttf", "DejaVuSans-Bold.ttf"):
        for base in ("C:/Windows/Fonts", "/usr/share/fonts/truetype/dejavu", ""):
            path = os.path.join(base, name) if base else name
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def main() -> None:
    os.makedirs(os.path.join(ROOT, "assets", "icon"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "store"), exist_ok=True)

    # Opak ana ikon
    icon = gradient((1024, 1024))
    draw_qr_plate(icon, 512, 512, 640)
    icon.save(os.path.join(ROOT, "assets", "icon", "app_icon.png"))
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, "store", "play_icon_512.png"))

    # Uyarlanabilir ikon ön yüzü: içerik güvenli alanda (~%66 daire) kalmalı.
    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    draw_qr_plate(fg, 512, 512, 470)
    fg.save(os.path.join(ROOT, "assets", "icon", "app_icon_foreground.png"))

    # Öne çıkan görsel 1024x500
    fgx = gradient((1024, 500))
    draw_qr_plate(fgx, 830, 250, 310)
    d = ImageDraw.Draw(fgx)
    d.text((64, 160), "QR Kod Okuyucu", font=font(64), fill=WHITE)
    d.text((68, 255), "Tara · Oluştur · Paylaş", font=font(38), fill=(224, 231, 255))
    fgx.save(os.path.join(ROOT, "store", "feature_graphic_1024x500.png"))

    print("Görseller üretildi.")


if __name__ == "__main__":
    main()
