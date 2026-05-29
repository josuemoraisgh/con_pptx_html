import 'package:flutter/material.dart';
import 'package:moodle_quiz_dep/core/bootstrap/default_app_factory.dart'
    as moodle_quiz_factory;
import 'package:moodle_quiz_dep/moodle_quiz_dep.dart' as moodle_quiz;

import '../services/participants_service.dart';
import '../services/quiz_slide_question_builder.dart';
import '../models/pptx_models.dart';
import '../utils/quiz_slide_detector.dart';

class QuizSlideHost extends StatefulWidget {
  final QuizSlideInvocation invocation;
  final SlideData slide;

  const QuizSlideHost({
    super.key,
    required this.invocation,
    required this.slide,
  });

  @override
  State<QuizSlideHost> createState() => _QuizSlideHostState();
}

class _QuizSlideHostState extends State<QuizSlideHost> {
  late final Future<Widget> _appFuture = _buildQuizApp();

  Future<Widget> _buildQuizApp() async {
    final participantsAssetPath =
        widget.invocation.option(const [
          'participants_asset',
          'participants_xlsx',
          'students_asset',
          'students_xlsx',
        ]) ??
        'assets/participants.xlsx';

    final initialQuizName =
        widget.invocation.option(const ['initial_quiz_name', 'quiz_name']) ??
        'Quiz';

    final questionPayload = buildQuizPayloadFromSlide(
      slide: widget.slide,
      quizName: initialQuizName,
    );

    final participantNames = await loadParticipantNamesFromAsset(
      assetPath: participantsAssetPath,
    );
    final students = List<moodle_quiz.StudentEntity>.generate(
      participantNames.length,
      (index) => moodle_quiz.StudentEntity(
        id: index + 1,
        name: participantNames[index],
      ),
    );

    // Monta o mapa de configuração a partir das opções do slide,
    // forçando offline e single-question como padrões deste host.
    final configMap = <String, dynamic>{
      ...widget.invocation.options,
      'mode': 'offline',
      'navigation_mode': 'single',
      'initial_quiz_name': initialQuizName,
    };

    final runtimeConfig = moodle_quiz.QuizRuntimeConfig.fromMap(
      configMap,
    ).copyWith(
      students: students,
      quizzes: questionPayload.quizzes,
      questions: questionPayload.questions,
    );

    final core = await moodle_quiz_factory.buildCoreFromConfig(runtimeConfig);

    return core.createQuizScreen(
      questionMap: questionPayload.initialQuestionMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _appFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _QuizSlideMessage(
            icon: Icons.error_outline,
            title: 'Quiz offline indisponivel',
            subtitle: snapshot.error.toString(),
          );
        }

        final app = snapshot.data;
        if (app == null) {
          return const _QuizSlideMessage(
            icon: Icons.quiz_rounded,
            title: 'Carregando quiz offline',
            subtitle: 'Preparando core + quiz + participantes',
            showProgress: true,
          );
        }

        return ClipRect(child: app);
      },
    );
  }
}

class QuizSlidePlaceholder extends StatelessWidget {
  const QuizSlidePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const _QuizSlideMessage(
      icon: Icons.quiz_rounded,
      title: 'Quiz offline',
      subtitle: 'moodle_quiz_dep',
      compact: true,
    );
  }
}

class _QuizSlideMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showProgress;
  final bool compact;

  const _QuizSlideMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showProgress = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 56.0 : 72.0;
    final titleSize = compact ? 32.0 : 40.0;
    final subtitleSize = compact ? 18.0 : 20.0;

    return Container(
      color: const Color(0xFF0D0D2B),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: iconSize),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: subtitleSize),
              ),
              if (showProgress) ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
