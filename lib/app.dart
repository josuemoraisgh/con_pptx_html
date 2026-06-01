import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodle_quiz_dep/core/utils/quiz_nav_notifier.dart';

import 'models/pptx_models.dart';
import 'screens/setup_screen.dart';
import 'widgets/presentation_viewer.dart';

// ── Temas do app externo ──────────────────────────────────────────────────────

ThemeData _buildDarkTheme() {
  return ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00BCD4),
      secondary: Color(0xFF007AFF),
      surface: Color(0xFF0A1628),
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: Colors.black,
  );
}

ThemeData _buildLightTheme() {
  return ThemeData.light().copyWith(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF007AFF),
      secondary: Color(0xFF00BCD4),
      surface: Color(0xFFF0F4FF),
      onSurface: Color(0xFF1A1A2E),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    scaffoldBackgroundColor: const Color(0xFFF0F4FF),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar o PPTX',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(80)),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App raiz — escuta [quizThemeModeNotifier] para aplicar dark/light em TODOS
/// os slides e na interface de apresentação.
class ConPptxHtmlApp extends StatefulWidget {
  final PresentationData? presentation;
  final String? parseError;

  const ConPptxHtmlApp({super.key, this.presentation, this.parseError});

  @override
  State<ConPptxHtmlApp> createState() => _ConPptxHtmlAppState();
}

class _ConPptxHtmlAppState extends State<ConPptxHtmlApp> {
  @override
  void initState() {
    super.initState();
    quizThemeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    quizThemeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final emptyPresentation =
        widget.presentation != null && widget.presentation!.slides.isEmpty;

    return MaterialApp(
      title: 'PPTX → Web',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: quizThemeModeNotifier.value,
      home: widget.presentation != null && !emptyPresentation
          ? PresentationViewer(presentation: widget.presentation!)
          : widget.parseError != null || emptyPresentation
          ? _ErrorScreen(
              error: widget.parseError ??
                  'O PPTX não contém slides renderizáveis.',
            )
          : const SetupScreen(),
    );
  }
}
