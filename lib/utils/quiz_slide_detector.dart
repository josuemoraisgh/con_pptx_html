import '../models/pptx_models.dart';

const String quizAltCommand = 'quiz';

class QuizSlideInvocation {
  final String sourceText;
  final Map<String, String> options;

  const QuizSlideInvocation({
    required this.sourceText,
    this.options = const {},
  });

  String? option(List<String> keys) {
    for (final key in keys) {
      final value = options[key.toLowerCase()];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  int? intOption(List<String> keys) {
    final value = option(keys);
    return value == null ? null : int.tryParse(value);
  }

  bool? boolOption(List<String> keys) {
    final value = option(keys);
    if (value == null) return null;
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'sim':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'nao':
      case 'não':
      case 'off':
        return false;
      default:
        return null;
    }
  }

  List<int>? intListOption(List<String> keys) {
    final value = option(keys);
    if (value == null) return null;
    final parsed = value
        .split(',')
        .map((chunk) => int.tryParse(chunk.trim()))
        .whereType<int>()
        .toList();
    return parsed.isEmpty ? null : parsed;
  }
}

bool slideHasQuizAltText(SlideData slide) {
  return extractQuizInvocation(slide) != null;
}

QuizSlideInvocation? extractQuizInvocation(SlideData slide) {
  QuizSlideInvocation? firstMatch;

  for (final element in slide.elements) {
    final sources = <String>[
      if (element.commandText != null) element.commandText!,
      switch (element) {
            ShapeElement() => element.altText,
            ImageElement() => element.altText,
            _ => null,
          } ??
          '',
    ].where((s) => s.trim().isNotEmpty);

    for (final source in sources) {
      final invocation = _extractInvocationFromSource(source);
      if (invocation != null) {
        firstMatch ??= invocation;
      }
    }
  }

  return firstMatch;
}

QuizSlideInvocation? _extractInvocationFromSource(String source) {
  final sourceTrimmed = source.trim();
  if (sourceTrimmed.isEmpty) return null;

  final options = <String, String>{};
  var hasQuizMarker = false;

  for (final match in RegExp(r'\{([^{}]+)\}').allMatches(sourceTrimmed)) {
    final content = match.group(1)?.trim() ?? '';
    if (content.isEmpty) continue;

    final commandMatch = RegExp(
      r'^(quiz)(?:\s*[:;|]\s*|\s+)?(.*)$',
      caseSensitive: false,
    ).firstMatch(content);
    if (commandMatch == null) continue;

    hasQuizMarker = true;
    final inlineArgs = (commandMatch.group(2) ?? '').trim();
    if (inlineArgs.isNotEmpty) {
      options.addAll(_parseKeyValuePairs(inlineArgs));
    }
  }

  if (!hasQuizMarker) return null;

  // Compatibilidade: permite declarar opcoes fora da chave {QUIZ}
  // usando quiz_*, quiz.* ou quiz:*.
  options.addAll(_parsePrefixedQuizOptions(sourceTrimmed));

  return QuizSlideInvocation(sourceText: sourceTrimmed, options: options);
}

Map<String, String> _parsePrefixedQuizOptions(String source) {
  final result = <String, String>{};
  final regex = RegExp(
    r'''(?:^|[\s,;|])quiz[._:](?<key>[a-zA-Z0-9_\-.]+)\s*=\s*(?<value>"[^"]*"|'[^']*'|[^,;|\n\r]+)''',
    caseSensitive: false,
  );

  for (final match in regex.allMatches(source)) {
    final rawKey = match.namedGroup('key');
    final rawValue = match.namedGroup('value');
    if (rawKey == null || rawValue == null) continue;
    result[_normalizeOptionKey(rawKey)] = _normalizeOptionValue(rawValue);
  }
  return result;
}

Map<String, String> _parseKeyValuePairs(String source) {
  final result = <String, String>{};
  final regex = RegExp(
    r'''(?<key>[a-zA-Z0-9_\-.]+)\s*=\s*(?<value>"[^"]*"|'[^']*'|[^,;|]+)''',
  );

  for (final match in regex.allMatches(source)) {
    final rawKey = match.namedGroup('key');
    final rawValue = match.namedGroup('value');
    if (rawKey == null || rawValue == null) continue;
    result[_normalizeOptionKey(rawKey)] = _normalizeOptionValue(rawValue);
  }

  return result;
}

String _normalizeOptionKey(String rawKey) {
  return rawKey.trim().toLowerCase().replaceAll('-', '_').replaceAll('.', '_');
}

String _normalizeOptionValue(String rawValue) {
  final trimmed = rawValue.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }
  return trimmed;
}
