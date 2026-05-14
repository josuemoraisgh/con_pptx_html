import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pptx_models.dart';

/// Renderiza um único slide como widget Flutter.
class SlideRenderer extends StatelessWidget {
  final SlideData slide;
  final PresentationData presentation;

  /// IDs de shapes visíveis. null = tudo visível. shapeId==0 = sempre visível.
  final Set<int>? visibleIds;

  /// Step de animação atual (usado apenas para rebuild trigger).
  final int animStep;

  const SlideRenderer({
    super.key,
    required this.slide,
    required this.presentation,
    this.visibleIds,
    this.animStep = 0,
  });

  @override
  Widget build(BuildContext context) {
    final w = presentation.canvasWidth;
    final h = presentation.canvasHeight;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _buildBackground(w, h),
          ...([...slide.elements]..sort((a, b) => a.zOrder.compareTo(b.zOrder)))
              .map((e) => _buildElement(e, presentation)),
        ],
      ),
    );
  }

  // ── Fundo ────────────────────────────────────────────────────────────────

  Widget _buildBackground(double w, double h) {
    final bg = slide.background;
    if (bg == null) {
      return Positioned.fill(child: Container(color: Colors.white));
    }
    if (bg.imageBytes != null) {
      return Positioned.fill(
        child: Image.memory(bg.imageBytes!, fit: BoxFit.cover),
      );
    }
    if (bg.fill != null) {
      return Positioned.fill(
        child: Container(decoration: _fillDecoration(bg.fill!)),
      );
    }
    return Positioned.fill(child: Container(color: Colors.white));
  }

  // ── Despacho de elementos ─────────────────────────────────────────────────

  Widget _buildElement(SlideElement el, PresentationData pres) {
    final left = pres.emuToPx(el.xEmu);
    final top = pres.emuToPx(el.yEmu);
    final width = pres.emuToPx(el.cxEmu);
    final height = pres.emuToPx(el.cyEmu);

    if (width <= 0 || height <= 0) return const SizedBox.shrink();

    Widget child;
    switch (el) {
      case ShapeElement():
        child = _buildShape(el, width, height, pres);
      case ImageElement():
        child = _buildImage(el);
      case TableElement():
        child = _buildTable(el, width, height, pres);
    }

    if (el.rotationDeg != null && el.rotationDeg != 0) {
      child = Transform.rotate(
        angle: el.rotationDeg! * 3.14159265358979 / 180.0,
        child: child,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: AnimatedOpacity(
        opacity: _isVisible(el) ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeIn,
        child: child,
      ),
    );
  }

  bool _isVisible(SlideElement el) {
    final ids = visibleIds;
    if (ids == null) return true;
    if (el.shapeId == 0) {
      return true; // elementos de master/layout sempre visíveis
    }
    return ids.contains(el.shapeId);
  }

  // ── Shape ─────────────────────────────────────────────────────────────────

  Widget _buildShape(
    ShapeElement el,
    double width,
    double height,
    PresentationData pres,
  ) {
    final fill = el.fill;
    final outline = el.outline;
    final geometry = el.presetGeometry ?? 'rect';

    // Detecta modo de borda pelo alt text
    final at = el.altText ?? '';
    final _BorderMode borderMode;
    if (at.contains('Border: inferiores')) {
      borderMode = _BorderMode.bottom;
    } else if (at.contains('Border: superiores')) {
      borderMode = _BorderMode.top;
    } else if (at.contains('Border: left')) {
      borderMode = _BorderMode.left;
    } else if (at.contains('Border: right')) {
      borderMode = _BorderMode.right;
    } else {
      borderMode = _BorderMode.all;
    }

    final insetL = pres.emuToPx(el.bodyProps.insetLeftEmu);
    final insetR = pres.emuToPx(el.bodyProps.insetRightEmu);
    final insetT = pres.emuToPx(el.bodyProps.insetTopEmu);
    final insetB = pres.emuToPx(el.bodyProps.insetBottomEmu);

    Widget textWidget = const SizedBox.shrink();
    if (el.paragraphs.isNotEmpty) {
      final availW = (width - insetL - insetR).clamp(0.0, double.infinity);
      final availH = (height - insetT - insetB).clamp(0.0, double.infinity);
      Widget body = _buildTextBody(el.paragraphs, el.bodyProps, pres, availW);
      // Títulos: encolhe automaticamente para caber na caixa, evitando
      // que "Comunicação Serial com ESP32" estoure o cabeçalho.
      if (_isTitlePlaceholder(el.placeholderType)) {
        body = SizedBox(
          width: availW,
          height: availH,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: _alignmentForVert(el.bodyProps.vertAlign),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: availW),
              child: body,
            ),
          ),
        );
      }
      textWidget = Padding(
        padding: EdgeInsets.fromLTRB(insetL, insetT, insetR, insetB),
        child: body,
      );
    }

    final hasPaint = (fill != null && fill is! NoFill) || outline != null;

    if (hasPaint) {
      return CustomPaint(
        painter: _ShapePainter(
          geometry: geometry,
          fill: fill,
          outline: outline,
          adjValue: el.adjValue,
          borderMode: borderMode,
        ),
        child: textWidget,
      );
    }
    return textWidget;
  }

  // ── Corpo de texto ────────────────────────────────────────────────────────

  Widget _buildTextBody(
    List<TextParagraph> paragraphs,
    TextBodyProperties bodyProps,
    PresentationData pres,
    double availableWidth,
  ) {
    final fontScale = bodyProps.fontScale;
    final lineSpaceReduction = bodyProps.lineSpaceReduction;
    final autoNumberByLevel = List<int>.filled(9, 0);
    final children = <Widget>[];

    for (final paragraph in paragraphs) {
      String? autoNumber;
      if (paragraph.props.bullet?.isAutoNum ?? false) {
        final level = paragraph.props.level
            .clamp(0, autoNumberByLevel.length - 1)
            .toInt();
        autoNumberByLevel[level]++;
        for (var i = level + 1; i < autoNumberByLevel.length; i++) {
          autoNumberByLevel[i] = 0;
        }
        autoNumber = '${autoNumberByLevel[level]}.';
      }

      children.add(
        _buildParagraph(
          paragraph,
          pres,
          fontScale,
          lineSpaceReduction,
          bodyProps.wordWrap,
          autoNumber,
        ),
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    final alignment = switch (bodyProps.vertAlign) {
      VerticalAlignment.top => Alignment.topLeft,
      VerticalAlignment.middle => Alignment.centerLeft,
      VerticalAlignment.bottom => Alignment.bottomLeft,
    };

    return OverflowBox(
      alignment: alignment,
      maxWidth: availableWidth,
      minHeight: 0,
      maxHeight: double.infinity,
      child: column,
    );
  }

  Widget _buildParagraph(
    TextParagraph para,
    PresentationData pres, [
    double fontScale = 1.0,
    double lineSpaceReduction = 0.0,
    bool wordWrap = true,
    String? autoNumber,
  ]) {
    final props = para.props;
    final lineSpacingMultiplier = ((props.lineSpacingPct ?? 100.0) / 100.0)
        .clamp(0.5, 3.0);

    if (para.runs.isEmpty) {
      final h = props.spaceBeforePt != null ? props.spaceBeforePt! * 0.5 : 4.0;
      return SizedBox(height: h.clamp(2.0, 20.0));
    }

    final spans = <InlineSpan>[];
    for (final run in para.runs) {
      if (run.text == '\n') {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      spans.add(
        TextSpan(
          text: run.text,
          style: _runStyle(
            run.props,
            pres,
            fontScale,
            lineSpaceReduction,
            lineSpacingMultiplier,
          ),
        ),
      );
    }

    Widget textWidget = RichText(
      text: TextSpan(children: spans),
      textAlign: props.alignment,
      softWrap: wordWrap,
      overflow: TextOverflow.visible,
    );

    // Recuo para listas / bullets
    if (props.bullet != null || props.marLeftEmu != null) {
      final indent = props.marLeftEmu != null
          ? pres.emuToPx(props.marLeftEmu!)
          : (props.level + 1) * 16.0;

      final bulletLabel = autoNumber ?? props.bullet?.char;
      if (bulletLabel != null) {
        final bulletStyle = _bulletRunStyle(
          para,
          pres,
          fontScale,
          lineSpaceReduction,
          lineSpacingMultiplier,
        );
        textWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: indent.clamp(8.0, 48.0),
              child: Text(bulletLabel, style: bulletStyle),
            ),
            Expanded(child: textWidget),
          ],
        );
      } else {
        textWidget = Padding(
          padding: EdgeInsets.only(left: indent.clamp(0.0, 120.0)),
          child: textWidget,
        );
      }
    }

    final topPad = (props.spaceBeforePt ?? 0) * 0.5;
    final botPad = (props.spaceAfterPt ?? 0) * 0.5;

    if (topPad > 0 || botPad > 0) {
      textWidget = Padding(
        padding: EdgeInsets.only(top: topPad, bottom: botPad),
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextStyle _runStyle(
    RunProperties rp,
    PresentationData pres, [
    double fontScale = 1.0,
    double lineSpaceReduction = 0.0,
    double lineSpacingMultiplier = 1.0,
  ]) {
    final fontSize = ((rp.fontSizePt ?? 18.0) * fontScale).clamp(6.0, 200.0);
    final family = _mapToSafeFont(_resolveFont(rp.fontFamily, pres));
    final lineHeight =
        (1.2 * lineSpacingMultiplier * (1.0 - lineSpaceReduction)).clamp(
          0.8,
          3.0,
        );

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: rp.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: rp.italic ? FontStyle.italic : FontStyle.normal,
      decoration: _textDecoration(rp),
      decorationColor: rp.color,
      color: rp.color ?? Colors.black,
      height: lineHeight,
    );

    try {
      return GoogleFonts.getFont(family, textStyle: baseStyle);
    } catch (_) {
      return baseStyle;
    }
  }

  /// Mapeia fontes comuns do PPTX para equivalentes disponíveis no Google
  /// Fonts. Evita o "flash" causado por tentativas de carregar Calibri/Cambria
  /// que não existem na CDN — assim o nome resolvido sempre é baixável e o
  /// pre-load no PresentationViewer garante que tudo já está pronto.
  static const Map<String, String> _safeFontMap = {
    'calibri': 'Inter',
    'calibri light': 'Inter',
    'cambria': 'Lora',
    'cambria math': 'Lora',
    'arial': 'Inter',
    'arial black': 'Inter',
    'helvetica': 'Inter',
    'times new roman': 'Lora',
    'times': 'Lora',
    'georgia': 'Lora',
    'verdana': 'Inter',
    'tahoma': 'Inter',
    'segoe ui': 'Inter',
    'consolas': 'JetBrains Mono',
    'courier new': 'JetBrains Mono',
    'courier': 'JetBrains Mono',
    'comic sans ms': 'Inter',
    'trebuchet ms': 'Inter',
  };

  static String mapToSafeFont(String name) {
    if (name.isEmpty) return 'Inter';
    return _safeFontMap[name.toLowerCase()] ?? name;
  }

  String _mapToSafeFont(String name) => mapToSafeFont(name);

  bool _isTitlePlaceholder(String? t) =>
      t == 'title' || t == 'ctrTitle' || t == 'subTitle';

  Alignment _alignmentForVert(VerticalAlignment v) {
    switch (v) {
      case VerticalAlignment.top:
        return Alignment.topLeft;
      case VerticalAlignment.middle:
        return Alignment.centerLeft;
      case VerticalAlignment.bottom:
        return Alignment.bottomLeft;
    }
  }

  TextStyle _bulletRunStyle(
    TextParagraph para,
    PresentationData pres,
    double fontScale,
    double lineSpaceReduction,
    double lineSpacingMultiplier,
  ) {
    final firstRun = para.runs.firstOrNull?.props ?? const RunProperties();
    final bulletColor = para.props.bullet?.color;
    final style = _runStyle(
      firstRun,
      pres,
      fontScale,
      lineSpaceReduction,
      lineSpacingMultiplier,
    );
    return bulletColor != null ? style.copyWith(color: bulletColor) : style;
  }

  String _resolveFont(String? requested, PresentationData pres) {
    if (requested == null || requested.isEmpty) {
      return pres.theme.minorFontLatin;
    }
    if (requested.startsWith('+mj')) return pres.theme.majorFontLatin;
    if (requested.startsWith('+mn')) return pres.theme.minorFontLatin;
    return requested;
  }

  TextDecoration _textDecoration(RunProperties rp) {
    if (rp.underline && rp.strikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }
    if (rp.underline) return TextDecoration.underline;
    if (rp.strikethrough) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  // ── Imagem ────────────────────────────────────────────────────────────────

  Widget _buildImage(ImageElement el) {
    if (el.imageBytes == null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return Image.memory(
      el.imageBytes!,
      fit: BoxFit.fill,
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }

  // ── Tabela ────────────────────────────────────────────────────────────────

  Widget _buildTable(
    TableElement el,
    double width,
    double height,
    PresentationData pres,
  ) {
    if (el.rows.isEmpty) return const SizedBox.shrink();

    final maxCols = el.rows.fold<int>(0, (max, row) {
      final cols = row.cells.fold<int>(
        0,
        (sum, cell) => sum + cell.gridSpan.clamp(1, 999).toInt(),
      );
      return math.max(max, cols);
    });
    if (maxCols == 0) return const SizedBox.shrink();

    var colWidths = el.colWidthsEmu.map(pres.emuToPx).toList();
    if (colWidths.length < maxCols) {
      final fallbackWidth = width / maxCols;
      colWidths = [
        ...colWidths,
        ...List.filled(maxCols - colWidths.length, fallbackWidth),
      ];
    }

    final totalColWidth = colWidths.fold(0.0, (sum, w) => sum + w);
    if (totalColWidth > 0 && width > 0) {
      final scale = width / totalColWidth;
      colWidths = colWidths.map((w) => w * scale).toList();
    } else {
      colWidths = List.filled(maxCols, width / maxCols);
    }

    var rowHeights = el.rows.map((row) => pres.emuToPx(row.heightEmu)).toList();
    final totalRowHeight = rowHeights.fold(0.0, (sum, h) => sum + h);
    if (totalRowHeight > 0 && height > 0) {
      final scale = height / totalRowHeight;
      rowHeights = rowHeights.map((h) => h * scale).toList();
    } else {
      rowHeights = List.filled(el.rows.length, height / el.rows.length);
    }

    final rowWidgets = <Widget>[];
    for (var rowIndex = 0; rowIndex < el.rows.length; rowIndex++) {
      final row = el.rows[rowIndex];
      final rowH = rowHeights[rowIndex];
      var colIdx = 0;
      final cells = <Widget>[];
      for (final cell in row.cells) {
        final remainingCols = colWidths.length - colIdx;
        if (remainingCols <= 0) break;
        final span = cell.gridSpan.clamp(1, remainingCols).toInt();
        final cellW = colWidths
            .skip(colIdx)
            .take(span)
            .fold(0.0, (s, w) => s + w);
        colIdx += span;
        cells.add(
          Container(
            width: cellW,
            height: rowH,
            decoration: BoxDecoration(
              color: cell.fill is SolidFill
                  ? (cell.fill as SolidFill).color
                  : Colors.transparent,
              border: Border.all(color: Colors.grey.shade400, width: 0.5),
            ),
            padding: const EdgeInsets.all(4),
            child: _buildTextBody(
              cell.paragraphs,
              TextBodyProperties.defaults,
              pres,
              (cellW - 8).clamp(0.0, double.infinity),
            ),
          ),
        );
      }
      rowWidgets.add(
        SizedBox(
          height: rowH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cells,
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowWidgets,
        ),
      ),
    );
  }

  // ── Helpers de decoração ──────────────────────────────────────────────────

  BoxDecoration _fillDecoration(ShapeFill fill) {
    switch (fill) {
      case SolidFill():
        return BoxDecoration(color: fill.color);
      case GradientFill():
        return BoxDecoration(
          gradient: LinearGradient(
            colors: fill.stops.map((s) => s.color).toList(),
            stops: fill.stops.map((s) => s.position).toList(),
            transform: GradientRotation(
              fill.angleDeg * 3.14159265358979 / 180.0,
            ),
          ),
        );
      case NoFill():
        return const BoxDecoration(color: Colors.transparent);
      default:
        return const BoxDecoration(color: Colors.transparent);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controle de bordas seletivas via alt text
// ─────────────────────────────────────────────────────────────────────────────

enum _BorderMode { all, top, bottom, left, right }

// ─────────────────────────────────────────────────────────────────────────────
// Painter de formas geométricas
// ─────────────────────────────────────────────────────────────────────────────

class _ShapePainter extends CustomPainter {
  final String geometry;
  final ShapeFill? fill;
  final ShapeLine? outline;
  final double? adjValue;
  final _BorderMode borderMode;

  const _ShapePainter({
    required this.geometry,
    this.fill,
    this.outline,
    this.adjValue,
    this.borderMode = _BorderMode.all,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _buildPath(rect);

    if (fill != null && fill is! NoFill) {
      final paint = Paint()..style = PaintingStyle.fill;
      switch (fill) {
        case SolidFill():
          paint.color = (fill as SolidFill).color;
          canvas.drawPath(path, paint);
        case GradientFill():
          final gf = fill as GradientFill;
          paint.shader = LinearGradient(
            colors: gf.stops.map((s) => s.color).toList(),
            stops: gf.stops.map((s) => s.position).toList(),
            transform: GradientRotation(gf.angleDeg * 3.14159265358979 / 180.0),
          ).createShader(rect);
          canvas.drawPath(path, paint);
        default:
          break;
      }
    }

    if (outline != null && outline!.color != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = outline!.color!
        ..strokeWidth = outline!.widthPt;
      switch (borderMode) {
        case _BorderMode.all:
          canvas.drawPath(path, paint);
        case _BorderMode.bottom:
          canvas.drawLine(
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
            paint,
          );
        case _BorderMode.top:
          canvas.drawLine(
            Offset(rect.left, rect.top),
            Offset(rect.right, rect.top),
            paint,
          );
        case _BorderMode.left:
          canvas.drawLine(
            Offset(rect.left, rect.top),
            Offset(rect.left, rect.bottom),
            paint,
          );
        case _BorderMode.right:
          canvas.drawLine(
            Offset(rect.right, rect.top),
            Offset(rect.right, rect.bottom),
            paint,
          );
      }
    }
  }

  Path _buildPath(Rect rect) {
    switch (geometry) {
      case 'ellipse':
        return Path()..addOval(rect);
      case 'roundRect':
        final double r;
        if (adjValue != null) {
          // OOXML: raio = min(w,h) * adj / 100000
          final raw = math.min(rect.width, rect.height) * adjValue! / 100000.0;
          r = raw.clamp(0.0, math.min(rect.width, rect.height) / 2.0);
        } else {
          r = math.min(rect.width, rect.height) * 0.1;
        }
        return Path()
          ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
      case 'triangle':
        return Path()
          ..moveTo(rect.left + rect.width / 2, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case 'rtTriangle':
        return Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case 'rightArrow':
        final mid = rect.top + rect.height / 2;
        final shaft = rect.right - rect.width * 0.35;
        return Path()
          ..moveTo(rect.left, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top)
          ..lineTo(rect.right, mid)
          ..lineTo(shaft, rect.bottom)
          ..lineTo(shaft, rect.bottom - rect.height * 0.3)
          ..lineTo(rect.left, rect.bottom - rect.height * 0.3)
          ..close();
      case 'leftArrow':
        final mid = rect.top + rect.height / 2;
        final shaft = rect.left + rect.width * 0.35;
        return Path()
          ..moveTo(rect.right, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top)
          ..lineTo(rect.left, mid)
          ..lineTo(shaft, rect.bottom)
          ..lineTo(shaft, rect.bottom - rect.height * 0.3)
          ..lineTo(rect.right, rect.bottom - rect.height * 0.3)
          ..close();
      case 'pentagon':
        final cx = rect.center.dx;
        return Path()
          ..moveTo(cx, rect.top)
          ..lineTo(rect.right, rect.top + rect.height * 0.38)
          ..lineTo(rect.right - rect.width * 0.18, rect.bottom)
          ..lineTo(rect.left + rect.width * 0.18, rect.bottom)
          ..lineTo(rect.left, rect.top + rect.height * 0.38)
          ..close();
      case 'hexagon':
        final cx = rect.center.dx;
        final qw = rect.width * 0.25;
        return Path()
          ..moveTo(cx - qw, rect.top)
          ..lineTo(cx + qw, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(cx + qw, rect.bottom)
          ..lineTo(cx - qw, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
      case 'diamond':
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
      case 'parallelogram':
        final offset = rect.width * 0.2;
        return Path()
          ..moveTo(rect.left + offset, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right - offset, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case 'leftRightArrow':
        final aW = rect.width * 0.35;
        final sT = rect.top + rect.height * 0.31;
        final sB = rect.bottom - rect.height * 0.31;
        final mid = rect.center.dy;
        return Path()
          ..moveTo(rect.left + aW, rect.top)
          ..lineTo(rect.left + aW, sT)
          ..lineTo(rect.right - aW, sT)
          ..lineTo(rect.right - aW, rect.top)
          ..lineTo(rect.right, mid)
          ..lineTo(rect.right - aW, rect.bottom)
          ..lineTo(rect.right - aW, sB)
          ..lineTo(rect.left + aW, sB)
          ..lineTo(rect.left + aW, rect.bottom)
          ..lineTo(rect.left, mid)
          ..close();
      case 'upDownArrow':
        final aH = rect.height * 0.35;
        final sL = rect.left + rect.width * 0.31;
        final sR = rect.right - rect.width * 0.31;
        final midX = rect.center.dx;
        return Path()
          ..moveTo(rect.left, rect.top + aH)
          ..lineTo(sL, rect.top + aH)
          ..lineTo(sL, rect.bottom - aH)
          ..lineTo(rect.left, rect.bottom - aH)
          ..lineTo(midX, rect.bottom)
          ..lineTo(rect.right, rect.bottom - aH)
          ..lineTo(sR, rect.bottom - aH)
          ..lineTo(sR, rect.top + aH)
          ..lineTo(rect.right, rect.top + aH)
          ..lineTo(midX, rect.top)
          ..close();
      case 'line':
      case 'straightConnector1':
        return Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.bottom);
      default:
        return Path()..addRect(rect);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.geometry != geometry ||
      old.fill != fill ||
      old.outline != outline ||
      old.adjValue != adjValue ||
      old.borderMode != borderMode;
}
