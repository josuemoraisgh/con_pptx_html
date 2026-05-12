import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../models/pptx_models.dart';

/// Utilitários para leitura de atributos XML sem namespace.
extension XmlElementExt on XmlElement {
  String? attr(String name) =>
      attributes.where((a) => a.localName == name).firstOrNull?.value;

  XmlElement? child(String localName) => children
      .whereType<XmlElement>()
      .where((e) => e.localName == localName)
      .firstOrNull;

  Iterable<XmlElement> children_(String localName) =>
      children.whereType<XmlElement>().where((e) => e.localName == localName);

  XmlElement? deep(String localName) => descendants
      .whereType<XmlElement>()
      .where((e) => e.localName == localName)
      .firstOrNull;

  Iterable<XmlElement> deepAll(String localName) => descendants
      .whereType<XmlElement>()
      .where((e) => e.localName == localName);
}

// ─────────────────────────────────────────────────────────────────────────────
// Resolução de cores
// ─────────────────────────────────────────────────────────────────────────────

class ColorResolver {
  final OOXMLTheme theme;

  const ColorResolver(this.theme);

  /// Resolve um elemento de cor OOXML (srgbClr, schemeClr, prstClr, sysClr).
  Color? resolveColorElement(XmlElement? el) {
    if (el == null) return null;

    Color? base;

    final srgb = el.child('srgbClr');
    if (srgb != null) {
      base = hexToColor(srgb.attr('val'));
    }

    final scheme = el.child('schemeClr');
    if (scheme != null) {
      final token = scheme.attr('val') ?? '';
      base = _mapSchemeToken(token);
      base = _applyMods(base, scheme);
    }

    final sys = el.child('sysClr');
    if (sys != null) {
      base = hexToColor(sys.attr('lastClr'));
    }

    final prst = el.child('prstClr');
    if (prst != null) {
      base = _presetColor(prst.attr('val') ?? '');
    }

    if (base == null) return null;
    return _applyMods(base, el);
  }

  Color _mapSchemeToken(String token) {
    // Aliases OOXML: bg1=lt1, bg2=lt2, tx1=dk1, tx2=dk2
    const aliases = {
      'bg1': 'lt1',
      'bg2': 'lt2',
      'tx1': 'dk1',
      'tx2': 'dk2',
    };
    final key = aliases[token] ?? token;
    return theme.colorScheme[key] ?? const Color(0xFF000000);
  }

  /// Aplica modificadores de cor (lumMod, lumOff, shade, tint, alpha).
  Color _applyMods(Color color, XmlElement el) {
    var r = color.r;
    var g = color.g;
    var b = color.b;
    var a = color.a;

    for (final mod in el.children.whereType<XmlElement>()) {
      final val = int.tryParse(mod.attr('val') ?? '0') ?? 0;
      final factor = val / 100000.0;

      switch (mod.localName) {
        case 'lumMod':
          // multiplica luminância
          final hsl = _rgbToHsl(r, g, b);
          final newL = (hsl.$3 * factor).clamp(0.0, 1.0);
          final rgb = _hslToRgb(hsl.$1, hsl.$2, newL);
          r = rgb.$1;
          g = rgb.$2;
          b = rgb.$3;
        case 'lumOff':
          final hsl = _rgbToHsl(r, g, b);
          final newL = (hsl.$3 + factor).clamp(0.0, 1.0);
          final rgb = _hslToRgb(hsl.$1, hsl.$2, newL);
          r = rgb.$1;
          g = rgb.$2;
          b = rgb.$3;
        case 'shade':
          r = r * factor;
          g = g * factor;
          b = b * factor;
        case 'tint':
          r = r + (1.0 - r) * factor;
          g = g + (1.0 - g) * factor;
          b = b + (1.0 - b) * factor;
        case 'alpha':
          a = factor;
      }
    }

    return Color.from(
      alpha: a,
      red: r.clamp(0.0, 1.0),
      green: g.clamp(0.0, 1.0),
      blue: b.clamp(0.0, 1.0),
    );
  }

  (double, double, double) _rgbToHsl(double r, double g, double b) {
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final l = (max + min) / 2.0;
    if (max == min) return (0, 0, l);
    final d = max - min;
    final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    double h;
    if (max == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    return (h / 6.0, s, l);
  }

  (double, double, double) _hslToRgb(double h, double s, double l) {
    if (s == 0) return (l, l, l);
    double hue2rgb(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    return (
      hue2rgb(p, q, h + 1 / 3),
      hue2rgb(p, q, h),
      hue2rgb(p, q, h - 1 / 3),
    );
  }

  static Color? hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      final v = int.tryParse(clean, radix: 16);
      if (v == null) return null;
      return Color(0xFF000000 | v);
    }
    if (clean.length == 8) {
      final v = int.tryParse(clean, radix: 16);
      if (v == null) return null;
      return Color(v);
    }
    return null;
  }

  static Color? _presetColor(String name) {
    const map = {
      'white': Color(0xFFFFFFFF),
      'black': Color(0xFF000000),
      'red': Color(0xFFFF0000),
      'green': Color(0xFF008000),
      'blue': Color(0xFF0000FF),
      'yellow': Color(0xFFFFFF00),
      'orange': Color(0xFFFFA500),
      'gray': Color(0xFF808080),
      'grey': Color(0xFF808080),
      'transparent': Color(0x00000000),
    };
    return map[name.toLowerCase()];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resolução de preenchimento
// ─────────────────────────────────────────────────────────────────────────────

ShapeFill? parseFill(XmlElement? parent, ColorResolver cr) {
  if (parent == null) return null;

  if (parent.child('noFill') != null) return NoFill();

  final solid = parent.child('solidFill');
  if (solid != null) {
    final c = cr.resolveColorElement(solid);
    if (c != null) return SolidFill(c);
  }

  final grad = parent.child('gradFill');
  if (grad != null) {
    final gsLst = grad.child('gsLst');
    if (gsLst != null) {
      final stops = gsLst
          .children_('gs')
          .map((gs) {
            final pos = (int.tryParse(gs.attr('pos') ?? '0') ?? 0) / 100000.0;
            final c = cr.resolveColorElement(gs);
            if (c == null) return null;
            return GradientStop(color: c, position: pos);
          })
          .whereType<GradientStop>()
          .toList();

      double angle = 0;
      final lin = grad.child('lin');
      if (lin != null) {
        angle = (int.tryParse(lin.attr('ang') ?? '0') ?? 0) / 60000.0;
      }
      if (stops.isNotEmpty) {
        return GradientFill(stops: stops, angleDeg: angle);
      }
    }
  }

  return null;
}

ShapeLine? parseLine(XmlElement? ln, ColorResolver cr) {
  if (ln == null) return null;
  if (ln.child('noFill') != null) return null;
  final solidFill = ln.child('solidFill');
  final color = solidFill != null ? cr.resolveColorElement(solidFill) : null;
  final wAttr = ln.attr('w');
  final widthPt = wAttr != null ? (int.tryParse(wAttr) ?? 12700) / 12700.0 : 1.0;
  if (color == null && solidFill == null) return null;
  return ShapeLine(color: color, widthPt: widthPt);
}
