import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:moodle_quiz_dep/core/utils/moodle_html_parser.dart'
    as moodle_html;
import 'package:moodle_quiz_dep/core/utils/moodle_xml_quiz_parser.dart';
import 'package:moodle_quiz_dep/core/utils/question_serializer.dart';
import 'package:moodle_quiz_dep/moodle_quiz_dep.dart' as moodle_quiz;

import '../models/pptx_models.dart';

class QuizSlideQuestionPayload {
  final List<moodle_quiz.LocalQuizEntity> quizzes;
  final List<moodle_quiz.QuestionEntity> questions;
  final Map<String, dynamic>? initialQuestionMap;

  const QuizSlideQuestionPayload({
    required this.quizzes,
    required this.questions,
    this.initialQuestionMap,
  });
}

QuizSlideQuestionPayload buildQuizPayloadFromSlide({
  required SlideData slide,
  required String quizName,
}) {
  final lines = _extractOrderedSlideLines(slide);
  final xmlContent = _extractMoodleQuizXml(lines);

  if (xmlContent != null) {
    final parsed = _tryParseMoodleXml(xmlContent);
    if (parsed.isNotEmpty) {
      final xmlQuizName = _tryExtractXmlQuizName(xmlContent);
      final effectiveQuizName =
          (xmlQuizName != null && xmlQuizName.trim().isNotEmpty)
          ? xmlQuizName.trim()
          : quizName;
      final quiz = moodle_quiz.LocalQuizEntity(
        id: 1,
        name: effectiveQuizName,
        questions: parsed,
      );
      return QuizSlideQuestionPayload(
        quizzes: [quiz],
        questions: parsed,
        initialQuestionMap: parsed.isNotEmpty
            ? QuestionSerializer.toJson(parsed.first)
            : null,
      );
    }
  }

  // Detecta JSON no formato QuestionSerializer (text + choices).
  // Permite que slides com JSON embutido sejam interpretados diretamente.
  final jsonQ = _tryParseJsonQuestion(lines);
  if (jsonQ != null) {
    final quiz =
        moodle_quiz.LocalQuizEntity(id: 1, name: quizName, questions: [jsonQ]);
    return QuizSlideQuestionPayload(
      quizzes: [quiz],
      questions: [jsonQ],
      initialQuestionMap: QuestionSerializer.toJson(jsonQ),
    );
  }

  final draftQuestions = _parseDraftQuestions(lines);

  if (draftQuestions.isEmpty) {
    final fallback = _DraftQuestion(
      statement: 'Questão sem texto identificado no slide.',
      options: const ['Verdadeiro', 'Falso'],
      answerText: 'Verdadeiro',
    );
    draftQuestions.add(fallback);
  }

  final questions = <moodle_quiz.QuestionEntity>[];
  for (var i = 0; i < draftQuestions.length; i++) {
    final draft = draftQuestions[i];
    final optionTexts = draft.options.isEmpty
        ? const ['Verdadeiro', 'Falso']
        : draft.options;
    final correctIndex = _resolveCorrectIndex(draft.answerText, optionTexts);

    final choices = <moodle_html.ParsedChoice>[];
    for (var idx = 0; idx < optionTexts.length; idx++) {
      final optionText = optionTexts[idx];
      choices.add(
        moodle_html.ParsedChoice(
          value: '$idx',
          text: optionText,
          htmlText: '<p>${_escapeHtml(optionText)}</p>',
          isCorrect: idx == correctIndex,
        ),
      );
    }

    final slot = i + 1;
    final statement = draft.statement.trim().isEmpty
        ? 'Questão ${slot.toString()}'
        : draft.statement.trim();

    questions.add(
      moodle_quiz.QuestionEntity(
        slot: slot,
        page: i,
        text: statement,
        htmlText: '<p>${_escapeHtml(statement)}</p>',
        displayHtml: _buildDisplayHtml(statement, optionTexts),
        choices: choices,
        inputBaseName: 'q_slide:${slot}_answer',
        seqCheck: 'slide-seq-$slot',
        type: 'multichoice',
        generalFeedback: '',
        rightAnswerHtml: correctIndex >= 0 && correctIndex < optionTexts.length
            ? '<p>${_escapeHtml(optionTexts[correctIndex])}</p>'
            : '',
        answerControls: const [],
      ),
    );
  }

  final quiz = moodle_quiz.LocalQuizEntity(
    id: 1,
    name: quizName,
    questions: questions,
  );

  return QuizSlideQuestionPayload(
    quizzes: [quiz],
    questions: questions,
    initialQuestionMap: questions.isNotEmpty
        ? QuestionSerializer.toJson(questions.first)
        : null,
  );
}

moodle_quiz.QuestionEntity? _tryParseJsonQuestion(List<String> lines) {
  final joined = lines.join('\n');
  if (!joined.contains('"text"') || !joined.contains('"choices"')) return null;
  final match = RegExp(r'\{[\s\S]+\}').firstMatch(joined);
  if (match == null) return null;
  try {
    final decoded = jsonDecode(match.group(0)!) as Map<String, dynamic>;
    if (decoded['text'] == null || decoded['choices'] == null) return null;
    return QuestionSerializer.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

List<moodle_quiz.QuestionEntity> _tryParseMoodleXml(String xmlContent) {
  try {
    final bytes = Uint8List.fromList(utf8.encode(xmlContent));
    return MoodleXmlQuizParser.parseQuestions(bytes);
  } catch (_) {
    return const <moodle_quiz.QuestionEntity>[];
  }
}

String? _tryExtractXmlQuizName(String xmlContent) {
  final categoryMatch = RegExp(
    r'<question\s+type\s*=\s*"category"[^>]*>.*?<text>\s*\$course\$/top/(.*?)\s*</text>.*?</question>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(xmlContent);
  final categoryName = categoryMatch?.group(1)?.trim();
  if (categoryName != null && categoryName.isNotEmpty) return categoryName;

  final nameMatch = RegExp(
    r'<question\b[^>]*>.*?<name>\s*<text>(.*?)</text>\s*</name>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(xmlContent);
  final raw = nameMatch?.group(1)?.trim();
  if (raw == null || raw.isEmpty) return null;
  return _decodeCommonXmlEntities(raw);
}

String? _extractMoodleQuizXml(List<String> lines) {
  if (lines.isEmpty) return null;

  final joined = lines.join('\n');
  final normalized = _decodeCommonXmlEntities(joined);

  String? findQuizBlock(String source) {
    final match = RegExp(
      r'(<quiz\b[^>]*>[\s\S]*?</quiz>)',
      caseSensitive: false,
    ).firstMatch(source);
    final xml = match?.group(1)?.trim();
    if (xml == null || xml.isEmpty) return null;
    return xml;
  }

  final direct = findQuizBlock(normalized);
  if (direct != null) return direct;

  final fenced = RegExp(
    r'```(?:xml)?\s*([\s\S]*?)```',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (fenced != null) {
    final fencedXml = findQuizBlock(fenced.group(1) ?? '');
    if (fencedXml != null) return fencedXml;
  }

  return null;
}

String _decodeCommonXmlEntities(String input) {
  return input
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

List<String> _extractOrderedSlideLines(SlideData slide) {
  final shapes = slide.elements.whereType<ShapeElement>().toList()
    ..sort((a, b) {
      final cmpY = a.yEmu.compareTo(b.yEmu);
      return cmpY == 0 ? a.xEmu.compareTo(b.xEmu) : cmpY;
    });

  final lines = <String>[];
  for (final shape in shapes) {
    for (final paragraph in shape.paragraphs) {
      final text = paragraph.runs.map((run) => run.text).join();
      final cleaned = _cleanLine(text);
      if (cleaned.isEmpty) continue;
      if (cleaned.contains('{QUIZ}') || cleaned.contains('{quiz}')) continue;
      lines.add(cleaned);
    }
  }

  return lines;
}

List<_DraftQuestion> _parseDraftQuestions(List<String> lines) {
  final drafts = <_DraftQuestion>[];
  _DraftQuestion? current;

  bool isQuestionStart(String line) {
    final lower = line.toLowerCase();
    return lower.startsWith('questao') ||
        lower.startsWith('questão') ||
        lower.startsWith('pergunta') ||
        RegExp(r'^q\s*\d+[:\-\.)]').hasMatch(lower);
  }

  for (final line in lines) {
    final optionMatch = RegExp(
      r'^([A-Ha-h]|\d{1,2})\s*[\)\.:\-]\s*(.+)$',
    ).firstMatch(line);
    final answerMatch = RegExp(
      r'^(gabarito|resposta\s*correta|resposta|answer)\s*[:\-]\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(line);

    if (isQuestionStart(line)) {
      final statement = line.replaceFirst(
        RegExp(
          r'^(questao|questão|pergunta|q\s*\d+)\s*[:\-\.)]?\s*',
          caseSensitive: false,
        ),
        '',
      );
      if (current != null && current.hasContent) drafts.add(current);
      current = _DraftQuestion(statement: statement.trim());
      continue;
    }

    current ??= _DraftQuestion(statement: '');

    if (answerMatch != null) {
      current.answerText = (answerMatch.group(2) ?? '').trim();
      continue;
    }

    if (optionMatch != null) {
      final optionBody = (optionMatch.group(2) ?? '').trim();
      if (optionBody.isNotEmpty) current.options.add(optionBody);
      continue;
    }

    if (current.statement.trim().isEmpty) {
      current.statement = line;
    } else {
      current.statement = '${current.statement}\n$line';
    }
  }

  if (current != null && current.hasContent) drafts.add(current);
  return drafts;
}

int _resolveCorrectIndex(String? answerText, List<String> options) {
  if (options.isEmpty) return 0;
  if (answerText == null || answerText.trim().isEmpty) return 0;

  final answer = answerText.trim();
  final letterMatch = RegExp(r'^([A-Ha-h])$').firstMatch(answer);
  if (letterMatch != null) {
    final idx = letterMatch.group(1)!.toUpperCase().codeUnitAt(0) - 65;
    return idx.clamp(0, options.length - 1);
  }

  final numeric = int.tryParse(answer);
  if (numeric != null) {
    return math.max(0, math.min(options.length - 1, numeric - 1));
  }

  final normalizedAnswer = answer.toLowerCase();
  final byContent = options.indexWhere(
    (opt) => opt.toLowerCase().trim() == normalizedAnswer,
  );
  if (byContent >= 0) return byContent;

  final byContains = options.indexWhere(
    (opt) => opt.toLowerCase().contains(normalizedAnswer),
  );
  if (byContains >= 0) return byContains;

  return 0;
}

String _buildDisplayHtml(String statement, List<String> options) {
  final items = options.map((o) => '<li>${_escapeHtml(o)}</li>').join();
  return '<p>${_escapeHtml(statement)}</p><ol>$items</ol>';
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _cleanLine(String line) {
  return line.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _DraftQuestion {
  String statement;
  final List<String> options;
  String? answerText;

  _DraftQuestion({
    required this.statement,
    List<String>? options,
    this.answerText,
  }) : options = List<String>.from(options ?? const <String>[]);

  bool get hasContent =>
      statement.trim().isNotEmpty ||
      options.isNotEmpty ||
      (answerText?.trim().isNotEmpty ?? false);
}
