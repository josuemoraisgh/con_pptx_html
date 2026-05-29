import 'package:flutter/material.dart';
import 'package:moodle_quiz_dep/core/bootstrap/default_app_factory.dart'
    as moodle_quiz_factory;
import 'package:moodle_quiz_dep/moodle_quiz_dep.dart' as moodle_quiz;

class QuizSlideHost extends StatefulWidget {
  const QuizSlideHost({super.key});

  @override
  State<QuizSlideHost> createState() => _QuizSlideHostState();
}

class _QuizSlideHostState extends State<QuizSlideHost> {
  late final Future<Widget> _appFuture = _buildOfflineQuizApp();

  Future<Widget> _buildOfflineQuizApp() {
    return moodle_quiz_factory.buildAppFromConfig(
      moodle_quiz.QuizRuntimeConfig.offline(
        settings: const moodle_quiz.AppSettingsEntity(
          teacherPassword: '',
          studentPassword: '',
          quizTitle: 'Quiz Presencial',
          defaultDurationSeconds: 30,
          durationOptions: [15, 20, 30, 45, 60, 90, 120],
        ),
        navigationMode: moodle_quiz.QuestionNavigationMode.list,
        initialQuizName: 'Quiz',
        localServerPort: 8080,
      ),
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
            subtitle: 'Preparando moodle_quiz_dep',
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
