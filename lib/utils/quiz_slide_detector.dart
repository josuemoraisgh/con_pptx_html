import '../models/pptx_models.dart';

const String quizAltCommand = 'quiz';

bool slideHasQuizAltText(SlideData slide) {
  for (final element in slide.elements) {
    if (_hasCommand(element.commandText, quizAltCommand)) return true;

    final altText = switch (element) {
      ShapeElement() => element.altText,
      ImageElement() => element.altText,
      _ => null,
    };
    if (_hasCommand(altText, quizAltCommand)) return true;
  }
  return false;
}

bool _hasCommand(String? source, String command) {
  if (source == null || source.isEmpty) return false;
  for (final match in RegExp(r'\{([^{}]+)\}').allMatches(source)) {
    if (match.group(1)?.trim().toLowerCase() == command) {
      return true;
    }
  }
  return false;
}
