import 'dart:typed_data';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Apresentação
// ─────────────────────────────────────────────────────────────────────────────

class PresentationData {
  final List<SlideData> slides;
  final double slideWidthEmu;
  final double slideHeightEmu;
  final OOXMLTheme theme;

  const PresentationData({
    required this.slides,
    required this.slideWidthEmu,
    required this.slideHeightEmu,
    required this.theme,
  });

  // Largura de canvas normalizada para 960 px
  double get canvasWidth => 960.0;

  double get canvasHeight => slideWidthEmu > 0
      ? canvasWidth * slideHeightEmu / slideWidthEmu
      : canvasWidth * 9 / 16;

  double emuToPx(double emu) =>
      slideWidthEmu > 0 ? emu * canvasWidth / slideWidthEmu : 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tema OOXML
// ─────────────────────────────────────────────────────────────────────────────

class OOXMLTheme {
  final Map<String, Color> colorScheme;
  final String majorFontLatin;
  final String minorFontLatin;

  const OOXMLTheme({
    required this.colorScheme,
    this.majorFontLatin = 'Calibri',
    this.minorFontLatin = 'Calibri',
  });

  Color resolveSchemeColor(String token) {
    return colorScheme[token] ?? const Color(0xFF000000);
  }

  static OOXMLTheme get defaultTheme => OOXMLTheme(
    colorScheme: {
      'dk1': const Color(0xFF000000),
      'lt1': const Color(0xFFFFFFFF),
      'dk2': const Color(0xFF1F497D),
      'lt2': const Color(0xFFEEECE1),
      'accent1': const Color(0xFF4F81BD),
      'accent2': const Color(0xFFC0504D),
      'accent3': const Color(0xFF9BBB59),
      'accent4': const Color(0xFF8064A2),
      'accent5': const Color(0xFF4BACC6),
      'accent6': const Color(0xFFF79646),
      'hlink': const Color(0xFF0000FF),
      'folHlink': const Color(0xFF800080),
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide
// ─────────────────────────────────────────────────────────────────────────────

class SlideData {
  final int index;
  final List<SlideElement> elements;
  final SlideBackground? background;

  /// Cada item é um conjunto de shapeIds que aparecem no mesmo clique.
  /// Índice 0 = elementos sempre visíveis (sem animação ou autoStart).
  final List<List<int>> animSteps;

  /// Duração da transição de entrada em ms (0 = sem transição).
  final int transitionMs;

  /// Anotações do apresentador extraídas do notesSlide.
  final String? notes;

  const SlideData({
    required this.index,
    required this.elements,
    this.background,
    this.animSteps = const [],
    this.transitionMs = 500,
    this.notes,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Fundo do slide
// ─────────────────────────────────────────────────────────────────────────────

class SlideBackground {
  final ShapeFill? fill;
  final Uint8List? imageBytes;

  const SlideBackground({this.fill, this.imageBytes});
}

// ─────────────────────────────────────────────────────────────────────────────
// Elementos do slide (sealed class)
// ─────────────────────────────────────────────────────────────────────────────

sealed class SlideElement {
  final double xEmu;
  final double yEmu;
  final double cxEmu;
  final double cyEmu;
  final int zOrder;
  final double? rotationDeg;

  /// ID do shape no OOXML (cNvPr/@id). Usado para mapeamento de animações.
  final int shapeId;

  const SlideElement({
    required this.xEmu,
    required this.yEmu,
    required this.cxEmu,
    required this.cyEmu,
    required this.zOrder,
    this.rotationDeg,
    this.shapeId = 0,
  });
}

/// Shape com ou sem texto (retângulo, elipse, etc.)
class ShapeElement extends SlideElement {
  final String? presetGeometry;
  final ShapeFill? fill;
  final ShapeLine? outline;
  final List<TextParagraph> paragraphs;
  final TextBodyProperties bodyProps;

  /// Valor adj para geometrias como roundRect (em unidades 1/100 000).
  final double? adjValue;

  /// Texto alternativo (cNvPr/@descr). Usado para controle de bordas seletivas.
  final String? altText;

  /// Tipo do placeholder OOXML (p:ph/@type): "title", "ctrTitle", "subTitle",
  /// "body", "dt", "ftr", "sldNum", etc. null = não é placeholder.
  final String? placeholderType;

  const ShapeElement({
    required super.xEmu,
    required super.yEmu,
    required super.cxEmu,
    required super.cyEmu,
    required super.zOrder,
    super.rotationDeg,
    super.shapeId,
    this.presetGeometry,
    this.fill,
    this.outline,
    required this.paragraphs,
    required this.bodyProps,
    this.adjValue,
    this.altText,
    this.placeholderType,
  });
}

/// Imagem (p:pic)
class ImageElement extends SlideElement {
  final Uint8List? imageBytes;
  final String? mimeType;

  const ImageElement({
    required super.xEmu,
    required super.yEmu,
    required super.cxEmu,
    required super.cyEmu,
    required super.zOrder,
    super.rotationDeg,
    super.shapeId,
    this.imageBytes,
    this.mimeType,
  });
}

/// Tabela (p:graphicFrame com tbl)
class TableElement extends SlideElement {
  final List<SlideTableRow> rows;
  final List<double> colWidthsEmu;

  const TableElement({
    required super.xEmu,
    required super.yEmu,
    required super.cxEmu,
    required super.cyEmu,
    required super.zOrder,
    super.shapeId,
    required this.rows,
    this.colWidthsEmu = const [],
  });
}

class SlideTableRow {
  final List<SlideTableCell> cells;
  final double heightEmu;
  const SlideTableRow({required this.cells, required this.heightEmu});
}

class SlideTableCell {
  final List<TextParagraph> paragraphs;
  final ShapeFill? fill;
  final int gridSpan;
  const SlideTableCell({
    required this.paragraphs,
    this.fill,
    this.gridSpan = 1,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelos de texto
// ─────────────────────────────────────────────────────────────────────────────

class TextParagraph {
  final List<TextRun> runs;
  final ParagraphProperties props;

  const TextParagraph({required this.runs, required this.props});
}

class TextRun {
  final String text;
  final RunProperties props;

  const TextRun({required this.text, required this.props});
}

class ParagraphProperties {
  final TextAlign alignment;
  final double? spaceBeforePt;
  final double? spaceAfterPt;
  final double? lineSpacingPct; // percentual: 100 = normal
  final double? marLeftEmu;
  final int level; // para listas (0-8)
  final BulletSpec? bullet;

  const ParagraphProperties({
    this.alignment = TextAlign.left,
    this.spaceBeforePt,
    this.spaceAfterPt,
    this.lineSpacingPct,
    this.marLeftEmu,
    this.level = 0,
    this.bullet,
  });
}

class RunProperties {
  final double? fontSizePt;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final Color? color;
  final String? fontFamily;
  final bool isPlaceholder; // run sem formatação herdará do layout/master

  const RunProperties({
    this.fontSizePt,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.color,
    this.fontFamily,
    this.isPlaceholder = false,
  });

  static const RunProperties empty = RunProperties();
}

class BulletSpec {
  final String? char;
  final bool isAutoNum;
  final Color? color;
  final double? sizePct;

  const BulletSpec({
    this.char,
    this.isAutoNum = false,
    this.color,
    this.sizePct,
  });
}

class TextBodyProperties {
  final VerticalAlignment vertAlign;
  final bool wordWrap;
  final double insetLeftEmu;
  final double insetRightEmu;
  final double insetTopEmu;
  final double insetBottomEmu;

  /// Escala aplicada à fonte (OOXML normAutofit/@fontScale, 1.0 = sem escala).
  final double fontScale;

  /// Redução de espaçamento entre linhas (OOXML normAutofit/@lnSpcReduction, 0.0 = sem redução).
  final double lineSpaceReduction;

  const TextBodyProperties({
    this.vertAlign = VerticalAlignment.top,
    this.wordWrap = true,
    this.insetLeftEmu = 91440,
    this.insetRightEmu = 91440,
    this.insetTopEmu = 45720,
    this.insetBottomEmu = 45720,
    this.fontScale = 1.0,
    this.lineSpaceReduction = 0.0,
  });

  static const TextBodyProperties defaults = TextBodyProperties();
}

enum VerticalAlignment { top, middle, bottom }

// ─────────────────────────────────────────────────────────────────────────────
// Modelos de preenchimento e linha
// ─────────────────────────────────────────────────────────────────────────────

sealed class ShapeFill {}

class SolidFill extends ShapeFill {
  final Color color;
  SolidFill(this.color);
}

class GradientFill extends ShapeFill {
  final List<GradientStop> stops;
  final double angleDeg;
  GradientFill({required this.stops, this.angleDeg = 0});
}

class GradientStop {
  final Color color;
  final double position; // 0.0 – 1.0
  const GradientStop({required this.color, required this.position});
}

class PatternFill extends ShapeFill {
  final Color foreground;
  final Color background;
  PatternFill({required this.foreground, required this.background});
}

class NoFill extends ShapeFill {}

class ShapeLine {
  final Color? color;
  final double widthPt;
  const ShapeLine({this.color, this.widthPt = 1.0});
}
