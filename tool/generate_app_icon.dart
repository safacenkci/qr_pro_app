import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

void main() {
  final outFile = File('assets/app_icon.png');
  outFile.parent.createSync(recursive: true);

  const size = 1024;
  const grid = 37; // QR-like module grid (not necessarily scannable)
  const quietModules = 4;
  final moduleSize = (size / (grid + quietModules * 2)).floor();
  final quietPx = moduleSize * quietModules;

  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  final rnd = Random(DateTime.now().millisecondsSinceEpoch);

  bool inFinder(int x, int y) {
    // Finder patterns are 7x7 modules.
    bool inTopLeft = x < 7 + quietModules && y < 7 + quietModules;
    bool inTopRight = x >= (grid - 7) && y < 7 + quietModules;
    bool inBottomLeft = x < 7 + quietModules && y >= (grid - 7);
    return inTopLeft || inTopRight || inBottomLeft;
  }

  void drawModule(int mx, int my, bool on) {
    final x0 = quietPx + mx * moduleSize;
    final y0 = quietPx + my * moduleSize;
    final x1 = min(x0 + moduleSize - 1, size - 1);
    final y1 = min(y0 + moduleSize - 1, size - 1);
    final color = on ? img.ColorRgb8(16, 24, 39) : img.ColorRgb8(255, 255, 255);
    img.fillRect(image, x1: x0, y1: y0, x2: x1, y2: y1, color: color);
  }

  // Draw finder pattern at module origin (top-left of finder).
  void drawFinder(int ox, int oy) {
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final isBorder = x == 0 || y == 0 || x == 6 || y == 6;
        final isCenter = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        final on = isBorder || isCenter;
        drawModule(ox + x, oy + y, on);
      }
    }
  }

  // Fill modules with random pattern (excluding finder areas).
  for (var y = 0; y < grid; y++) {
    for (var x = 0; x < grid; x++) {
      if (inFinder(x, y)) continue;
      // Make it "QR-like": slightly denser towards center.
      final dx = (x - grid / 2).abs() / (grid / 2);
      final dy = (y - grid / 2).abs() / (grid / 2);
      final density = 0.42 + (0.12 * (1 - (dx + dy) / 2));
      drawModule(x, y, rnd.nextDouble() < density);
    }
  }

  // Finder patterns: TL, TR, BL.
  drawFinder(0, 0);
  drawFinder(grid - 7, 0);
  drawFinder(0, grid - 7);

  // Add rounded white border for a cleaner app-icon look.
  final radius = 180;
  final mask = img.Image(width: size, height: size);
  img.fill(mask, color: img.ColorRgb8(0, 0, 0));
  img.fillRect(
    mask,
    x1: 0,
    y1: 0,
    x2: size - 1,
    y2: size - 1,
    color: img.ColorRgb8(255, 255, 255),
  );
  img.drawRect(
    mask,
    x1: 0,
    y1: 0,
    x2: size - 1,
    y2: size - 1,
    color: img.ColorRgb8(255, 255, 255),
  );
  // Soft-corner clip approximation by clearing outside quarter-circles.
  void clearCorner(int cx, int cy) {
    for (var y = 0; y < radius; y++) {
      for (var x = 0; x < radius; x++) {
        final px = (cx == 0) ? x : (size - 1 - x);
        final py = (cy == 0) ? y : (size - 1 - y);
        final dx = (x - radius).toDouble();
        final dy = (y - radius).toDouble();
        if (dx * dx + dy * dy > radius * radius) {
          image.setPixel(px, py, img.ColorRgba8(255, 255, 255, 0));
        }
      }
    }
  }

  clearCorner(0, 0);
  clearCorner(1, 0);
  clearCorner(0, 1);
  clearCorner(1, 1);

  final bytes = img.encodePng(image, level: 6);
  outFile.writeAsBytesSync(bytes);

  stdout.writeln('Generated ${outFile.path} (${outFile.lengthSync()} bytes)');
}


