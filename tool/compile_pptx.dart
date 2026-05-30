// FERRAMENTA DE COMPILAÇÃO PPTX → DART
//
// Uso:
//   PPTX_INPUT=caminho/para/arquivo.pptx flutter test tool/compile_pptx.dart
//
// Ou via scripts:
//   Windows: .\scripts\prepare_pptx.ps1 -PptxPath "aula.pptx"
//   Linux:   bash scripts/prepare_pptx.sh "aula.pptx"
//
// Gera: lib/generated/presentation_data.g.dart
// Depois compile: flutter build web --wasm

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:con_pptx_html/models/pptx_models.dart';
import 'package:con_pptx_html/parsers/pptx_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Compile PPTX to Dart', () async {
    // Prioridade: --dart-define > env var > .pptx_source > fallback
    const dartPptx = String.fromEnvironment('PPTX_INPUT');
    final envPptx = Platform.environment['PPTX_INPUT'];
    final sourcePptx = () {
      final f = File('.pptx_source');
      if (f.existsSync()) {
        final v = f.readAsStringSync().trim();
        if (v.isNotEmpty) return v;
      }
      return null;
    }();
    final pptxPath = dartPptx.isNotEmpty
        ? dartPptx
        : envPptx ?? sourcePptx ?? 'assets/presentation.pptx';

    final outPath = Platform.environment['DART_OUTPUT'] ??
        'lib/generated/presentation_data.g.dart';

    if (!File(pptxPath).existsSync()) {
      fail(
        'PPTX não encontrado: $pptxPath\n'
        'Uso: PPTX_INPUT=path/to/file.pptx flutter test tool/compile_pptx.dart',
      );
    }

    print('Lendo: $pptxPath');
    final bytes = File(pptxPath).readAsBytesSync();

    print('Parsing PPTX...');
    final presentation = PptxParser().parse(bytes);
    print(
      'OK — ${presentation.slides.length} slides, '
      '${presentation.embeddedFonts.length} fontes embutidas',
    );

    print('Gerando código Dart...');
    final sourceName = pptxPath.split(Platform.pathSeparator).last;
    final gen = _CodeGen(presentation, sourceName);
    final code = gen.generate();

    File(outPath).writeAsStringSync(code);
    final sizeKb = (code.length / 1024).toStringAsFixed(1);
    print('✓ Gerado: $outPath ($sizeKb KB)');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

// ─────────────────────────────────────────────────────────────────────────────
// Gerador de código
// ─────────────────────────────────────────────────────────────────────────────

class _CodeGen {
  final PresentationData pres;
  final String sourceName;
  final _binaryData = <List<int>>[];

  _CodeGen(this.pres, this.sourceName);

  // ── Registro de dados binários ────────────────────────────────────────────

  String _bin(List<int>? bytes) {
    if (bytes == null) return 'null';
    _binaryData.add(bytes);
    return '_r${_binaryData.length - 1}';
  }

  // ── Escalares ─────────────────────────────────────────────────────────────

  String _str(String s) {
    final esc = s
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return "'$esc'";
  }

  String _color(Color c) =>
      'Color(0x${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()})';

  String _textAlign(TextAlign a) {
    return switch (a) {
      TextAlign.left => 'TextAlign.left',
      TextAlign.right => 'TextAlign.right',
      TextAlign.center => 'TextAlign.center',
      TextAlign.justify => 'TextAlign.justify',
      TextAlign.start => 'TextAlign.start',
      TextAlign.end => 'TextAlign.end',
    };
  }

  String _vertAlign(VerticalAlignment a) => switch (a) {
        VerticalAlignment.top => 'VerticalAlignment.top',
        VerticalAlignment.middle => 'VerticalAlignment.middle',
        VerticalAlignment.bottom => 'VerticalAlignment.bottom',
      };

  // ── Modelos ───────────────────────────────────────────────────────────────

  String _theme(OOXMLTheme t) {
    final entries = t.colorScheme.entries
        .map((e) => '${_str(e.key)}: ${_color(e.value)}')
        .join(', ');
    return 'OOXMLTheme('
        'colorScheme: {$entries}, '
        'majorFontLatin: ${_str(t.majorFontLatin)}, '
        'minorFontLatin: ${_str(t.minorFontLatin)})';
  }

  String _fontFace(EmbeddedFontFace f) => 'EmbeddedFontFace('
      'family: ${_str(f.family)}, '
      'bold: ${f.bold}, '
      'italic: ${f.italic}, '
      'bytes: ${_bin(f.bytes)})';

  String? _fill(ShapeFill? fill) {
    if (fill == null) return null;
    return switch (fill) {
      SolidFill(:final color) => 'SolidFill(${_color(color)})',
      GradientFill(:final stops, :final angleDeg) => () {
          final s = stops
              .map((s) =>
                  'GradientStop(color: ${_color(s.color)}, position: ${s.position})')
              .join(', ');
          return 'GradientFill(stops: [$s], angleDeg: $angleDeg)';
        }(),
      PatternFill(:final foreground, :final background) =>
        'PatternFill(foreground: ${_color(foreground)}, '
            'background: ${_color(background)})',
      NoFill() => 'NoFill()',
    };
  }

  String? _line(ShapeLine? l) {
    if (l == null) return null;
    final c = l.color != null ? 'color: ${_color(l.color!)}, ' : '';
    return 'ShapeLine(${c}widthPt: ${l.widthPt})';
  }

  String? _bullet(BulletSpec? b) {
    if (b == null) return null;
    final parts = <String>[];
    if (b.char != null) parts.add('char: ${_str(b.char!)}');
    if (b.isAutoNum) parts.add('isAutoNum: true');
    if (b.color != null) parts.add('color: ${_color(b.color!)}');
    if (b.sizePct != null) parts.add('sizePct: ${b.sizePct}');
    return 'BulletSpec(${parts.join(', ')})';
  }

  String _paraProps(ParagraphProperties p) {
    final parts = <String>[];
    if (p.alignment != TextAlign.left) {
      parts.add('alignment: ${_textAlign(p.alignment)}');
    }
    if (p.spaceBeforePt != null) parts.add('spaceBeforePt: ${p.spaceBeforePt}');
    if (p.spaceBeforePct != null) {
      parts.add('spaceBeforePct: ${p.spaceBeforePct}');
    }
    if (p.spaceAfterPt != null) parts.add('spaceAfterPt: ${p.spaceAfterPt}');
    if (p.spaceAfterPct != null) parts.add('spaceAfterPct: ${p.spaceAfterPct}');
    if (p.lineSpacingPct != null) {
      parts.add('lineSpacingPct: ${p.lineSpacingPct}');
    }
    if (p.lineSpacingPt != null) parts.add('lineSpacingPt: ${p.lineSpacingPt}');
    if (p.marLeftEmu != null) parts.add('marLeftEmu: ${p.marLeftEmu}');
    if (p.level != 0) parts.add('level: ${p.level}');
    if (p.bullet != null) parts.add('bullet: ${_bullet(p.bullet)}');
    return 'ParagraphProperties(${parts.join(', ')})';
  }

  String _runProps(RunProperties r) {
    final parts = <String>[];
    if (r.fontSizePt != null) parts.add('fontSizePt: ${r.fontSizePt}');
    if (r.letterSpacingPt != null) {
      parts.add('letterSpacingPt: ${r.letterSpacingPt}');
    }
    if (r.baselinePct != null) parts.add('baselinePct: ${r.baselinePct}');
    if (r.kerningPt != null) parts.add('kerningPt: ${r.kerningPt}');
    if (r.capsType != null) parts.add('capsType: ${_str(r.capsType!)}');
    if (r.bold) parts.add('bold: true');
    if (r.italic) parts.add('italic: true');
    if (r.underline) parts.add('underline: true');
    if (r.underlineStyle != null) {
      parts.add('underlineStyle: ${_str(r.underlineStyle!)}');
    }
    if (r.underlineColor != null) {
      parts.add('underlineColor: ${_color(r.underlineColor!)}');
    }
    if (r.strikethrough) parts.add('strikethrough: true');
    if (r.doubleStrikethrough) parts.add('doubleStrikethrough: true');
    if (r.color != null) parts.add('color: ${_color(r.color!)}');
    if (r.fontFamily != null) parts.add('fontFamily: ${_str(r.fontFamily!)}');
    if (r.isPlaceholder) parts.add('isPlaceholder: true');
    return 'RunProperties(${parts.join(', ')})';
  }

  String _textRun(TextRun r) =>
      'TextRun(text: ${_str(r.text)}, props: ${_runProps(r.props)})';

  String _textParagraph(TextParagraph p) {
    final runs = p.runs.map(_textRun).join(', ');
    final end = p.endProps != null ? ', endProps: ${_runProps(p.endProps!)}' : '';
    return 'TextParagraph(runs: [$runs], props: ${_paraProps(p.props)}$end)';
  }

  String _bodyProps(TextBodyProperties b) {
    final parts = <String>[];
    if (b.vertAlign != VerticalAlignment.top) {
      parts.add('vertAlign: ${_vertAlign(b.vertAlign)}');
    }
    if (!b.wordWrap) parts.add('wordWrap: false');
    if (b.insetLeftEmu != 91440) parts.add('insetLeftEmu: ${b.insetLeftEmu}');
    if (b.insetRightEmu != 91440) {
      parts.add('insetRightEmu: ${b.insetRightEmu}');
    }
    if (b.insetTopEmu != 45720) parts.add('insetTopEmu: ${b.insetTopEmu}');
    if (b.insetBottomEmu != 45720) {
      parts.add('insetBottomEmu: ${b.insetBottomEmu}');
    }
    if (b.fontScale != 1.0) parts.add('fontScale: ${b.fontScale}');
    if (b.lineSpaceReduction != 0.0) {
      parts.add('lineSpaceReduction: ${b.lineSpaceReduction}');
    }
    return 'TextBodyProperties(${parts.join(', ')})';
  }

  String? _background(SlideBackground? bg) {
    if (bg == null) return null;
    final parts = <String>[];
    final f = _fill(bg.fill);
    if (f != null) parts.add('fill: $f');
    if (bg.imageBytes != null) {
      parts.add('imageBytes: ${_bin(bg.imageBytes)}');
    }
    return 'SlideBackground(${parts.join(', ')})';
  }

  String _element(SlideElement e) {
    final base = <String>[
      'xEmu: ${e.xEmu}',
      'yEmu: ${e.yEmu}',
      'cxEmu: ${e.cxEmu}',
      'cyEmu: ${e.cyEmu}',
      'zOrder: ${e.zOrder}',
    ];
    if (e.rotationDeg != null) base.add('rotationDeg: ${e.rotationDeg}');
    if (e.shapeId != 0) base.add('shapeId: ${e.shapeId}');
    if (e.commandText != null) {
      base.add('commandText: ${_str(e.commandText!)}');
    }

    return switch (e) {
      ShapeElement() => () {
          final p = [...base];
          if (e.presetGeometry != null) {
            p.add('presetGeometry: ${_str(e.presetGeometry!)}');
          }
          final f = _fill(e.fill);
          if (f != null) p.add('fill: $f');
          final l = _line(e.outline);
          if (l != null) p.add('outline: $l');
          final paras = e.paragraphs.map(_textParagraph).join(', ');
          p.add('paragraphs: [$paras]');
          p.add('bodyProps: ${_bodyProps(e.bodyProps)}');
          if (e.adjValue != null) p.add('adjValue: ${e.adjValue}');
          if (e.altText != null) p.add('altText: ${_str(e.altText!)}');
          if (e.placeholderType != null) {
            p.add('placeholderType: ${_str(e.placeholderType!)}');
          }
          return 'ShapeElement(${p.join(', ')})';
        }(),
      ImageElement() => () {
          final p = [...base];
          if (e.imageBytes != null) {
            p.add('imageBytes: ${_bin(e.imageBytes)}');
          }
          if (e.mimeType != null) p.add('mimeType: ${_str(e.mimeType!)}');
          if (e.altText != null) p.add('altText: ${_str(e.altText!)}');
          return 'ImageElement(${p.join(', ')})';
        }(),
      TableElement() => () {
          final rows = e.rows.map(_tableRow).join(', ');
          final p = [...base, 'rows: [$rows]'];
          if (e.colWidthsEmu.isNotEmpty) {
            p.add('colWidthsEmu: [${e.colWidthsEmu.join(', ')}]');
          }
          return 'TableElement(${p.join(', ')})';
        }(),
    };
  }

  String _tableRow(SlideTableRow r) {
    final cells = r.cells.map(_tableCell).join(', ');
    return 'SlideTableRow(cells: [$cells], heightEmu: ${r.heightEmu})';
  }

  String _tableCell(SlideTableCell c) {
    final paras = c.paragraphs.map(_textParagraph).join(', ');
    final parts = ['paragraphs: [$paras]'];
    final f = _fill(c.fill);
    if (f != null) parts.add('fill: $f');
    if (c.gridSpan != 1) parts.add('gridSpan: ${c.gridSpan}');
    return 'SlideTableCell(${parts.join(', ')})';
  }

  String _slide(SlideData s) {
    final parts = <String>['index: ${s.index}'];
    final elems = s.elements.map(_element).join(',\n      ');
    parts.add('elements: [\n      $elems,\n    ]');
    final bg = _background(s.background);
    if (bg != null) parts.add('background: $bg');
    if (s.animSteps.isNotEmpty) {
      final steps =
          s.animSteps.map((ids) => '[${ids.join(', ')}]').join(', ');
      parts.add('animSteps: [$steps]');
    }
    if (s.transitionMs != 500) parts.add('transitionMs: ${s.transitionMs}');
    if (s.notes != null) parts.add('notes: ${_str(s.notes!)}');
    return 'SlideData(\n    ${parts.join(',\n    ')},\n  )';
  }

  // ── Geração de declarações de binários ────────────────────────────────────

  String _binaryDecls() {
    if (_binaryData.isEmpty) return '';
    final sb = StringBuffer();
    for (int i = 0; i < _binaryData.length; i++) {
      final b64 = base64Encode(_binaryData[i]);
      sb.writeln('// ${_binaryData[i].length} bytes');
      sb.write('final _r$i = base64Decode(');
      // Split base64 into 76-char chunks (adjacent string literals)
      const chunk = 76;
      if (b64.length <= chunk) {
        sb.writeln("'$b64');");
      } else {
        sb.writeln();
        for (int j = 0; j < b64.length; j += chunk) {
          final end = (j + chunk).clamp(0, b64.length);
          final last = end >= b64.length;
          sb.write("  '${b64.substring(j, end)}'");
          if (last) {
            sb.writeln(');');
          } else {
            sb.writeln();
          }
        }
      }
    }
    return sb.toString();
  }

  // ── Geração do arquivo completo ───────────────────────────────────────────

  String generate() {
    // Gera o corpo da apresentação (popula _binaryData como efeito colateral)
    final slidesCodes = pres.slides.map(_slide).join(',\n  ');
    final fontsCodes = pres.embeddedFonts.map(_fontFace).join(',\n    ');
    final fontsSection = pres.embeddedFonts.isEmpty
        ? ''
        : '  embeddedFonts: [\n    $fontsCodes,\n  ],\n';

    final presCode = '''
final PresentationData kGeneratedPresentation = PresentationData(
  slideWidthEmu: ${pres.slideWidthEmu},
  slideHeightEmu: ${pres.slideHeightEmu},
  theme: ${_theme(pres.theme)},
$fontsSection  slides: [
  $slidesCodes,
  ],
);''';

    // Agora gera as declarações de binários (preenchidas durante _slide())
    final binDecls = _binaryDecls();
    final hasBinaries = binDecls.isNotEmpty;

    final header = '''
// GENERATED — DO NOT EDIT
// Fonte: $sourceName
// Gerado em: ${DateTime.now().toIso8601String()}
// ignore_for_file: lines_longer_than_80_chars, prefer_const_constructors
// ignore_for_file: unnecessary_new, use_raw_strings
${hasBinaries ? "import 'dart:convert';\nimport 'dart:typed_data';\n" : ''}
import 'package:flutter/material.dart';
import '../models/pptx_models.dart';

const String kGeneratedPptxName = ${_str(sourceName)};
''';

    return hasBinaries
        ? '$header\n$binDecls\n$presCode\n'
        : '$header\n$presCode\n';
  }
}
