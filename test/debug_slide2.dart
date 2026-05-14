import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:con_pptx_html/parsers/pptx_parser.dart';
import 'package:con_pptx_html/models/pptx_models.dart';

void main() {
  test('debug slide 2 elements', () async {
    final bytes = await File('assets/presentation.pptx').readAsBytes();
    final parser = PptxParser();
    final pres = parser.parse(Uint8List.fromList(bytes));

    expect(pres.slides.length, greaterThan(1));
    debugPrint('=== Total slides: ${pres.slides.length} ===');
    final slide = pres.slides[1]; // slide index 1 = slide 2
    expect(slide.elements, isNotEmpty);
    debugPrint('=== Slide 2: ${slide.elements.length} elementos ===');
    debugPrint('=== animSteps: ${slide.animSteps} ===');
    for (final e in slide.elements) {
      final t = e.runtimeType;
      final pos =
          '(${e.xEmu.toInt()},${e.yEmu.toInt()}) '
          '${e.cxEmu.toInt()}x${e.cyEmu.toInt()}';
      if (e is ShapeElement) {
        final txt = e.paragraphs
            .expand((p) => p.runs)
            .map((r) => r.text)
            .join('|');
        debugPrint(
          'Shape id=${e.shapeId} z=${e.zOrder} ph=${e.placeholderType} '
          'geom=${e.presetGeometry} pos=$pos text="$txt"',
        );
      } else {
        debugPrint('$t id=${e.shapeId} z=${e.zOrder} pos=$pos');
      }
    }
  });
}
