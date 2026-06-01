import 'dart:convert';

import 'package:moodle_quiz_dep/core/utils/quiz_nav_notifier.dart';
import 'package:moodle_quiz_dep/moodle_quiz_dep.dart' as moodle_quiz;

import '../platform/browser_runtime.dart' as browser;

const _quizAuthStorageKey = 'quiz.auth.user';

Map<String, dynamic>? serializeQuizUser(moodle_quiz.LocalUserEntity? user) {
  if (user == null) return null;
  return <String, dynamic>{
    'id': user.id,
    'name': user.name,
    'isTeacher': user.isTeacher,
    'username': user.username,
    'token': user.token,
    'baseUrl': user.baseUrl,
    'courseId': user.courseId,
    'availableFunctions': user.availableFunctions.toList()..sort(),
  };
}

moodle_quiz.LocalUserEntity? deserializeQuizUser(dynamic raw) {
  if (raw is! Map) return null;
  final id = raw['id'];
  final name = raw['name'];
  final isTeacher = raw['isTeacher'];
  if (id is! num || name is! String || isTeacher is! bool) return null;

  final availableFunctionsRaw = raw['availableFunctions'];
  final availableFunctions = availableFunctionsRaw is List
      ? availableFunctionsRaw.whereType<String>().toSet()
      : const <String>{};

  return moodle_quiz.LocalUserEntity(
    id: id.toInt(),
    name: name,
    isTeacher: isTeacher,
    username: raw['username'] as String? ?? '',
    token: raw['token'] as String? ?? '',
    baseUrl: raw['baseUrl'] as String? ?? '',
    courseId: (raw['courseId'] as num?)?.toInt() ?? 0,
    availableFunctions: availableFunctions,
  );
}

void applyQuizUser(moodle_quiz.LocalUserEntity? user, {bool persist = true}) {
  if (quizGlobalUserNotifier.value == user) {
    if (persist) persistQuizUser(user);
    return;
  }
  quizGlobalUserNotifier.value = user;
  if (persist) persistQuizUser(user);
}

void persistQuizUser(moodle_quiz.LocalUserEntity? user) {
  if (user == null) {
    browser.removeSharedStorageValue(_quizAuthStorageKey);
    return;
  }
  browser.setSharedStorageValue(
    _quizAuthStorageKey,
    jsonEncode(serializeQuizUser(user)),
  );
}

void hydrateQuizUserFromStorage() {
  final raw = browser.getSharedStorageValue(_quizAuthStorageKey);
  if (raw == null || raw.isEmpty) return;

  try {
    final decoded = jsonDecode(raw);
    final user = deserializeQuizUser(decoded);
    if (user != null) {
      applyQuizUser(user, persist: false);
    }
  } catch (_) {}
}
