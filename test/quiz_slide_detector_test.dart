import 'package:con_pptx_html/models/pptx_models.dart';
import 'package:con_pptx_html/utils/quiz_slide_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects quiz marker from shape alt text', () {
    final slide = _slideWith(_shape(altText: '{QUIZ}'));

    expect(slideHasQuizAltText(slide), isTrue);
  });

  test('detects quiz marker propagated from grouped object alt text', () {
    final slide = _slideWith(_shape(commandText: 'Button {quiz}'));

    expect(slideHasQuizAltText(slide), isTrue);
  });

  test('ignores non quiz slides', () {
    final slide = _slideWith(_shape(altText: 'title'));

    expect(slideHasQuizAltText(slide), isFalse);
  });
}

SlideData _slideWith(SlideElement element) {
  return SlideData(index: 0, elements: [element]);
}

ShapeElement _shape({String? altText, String? commandText}) {
  return ShapeElement(
    xEmu: 0,
    yEmu: 0,
    cxEmu: 100,
    cyEmu: 100,
    zOrder: 0,
    commandText: commandText,
    paragraphs: const [],
    bodyProps: TextBodyProperties.defaults,
    altText: altText,
  );
}
