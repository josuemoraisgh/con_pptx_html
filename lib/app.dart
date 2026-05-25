import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/pptx_models.dart';
import 'screens/setup_screen.dart';
import 'widgets/presentation_viewer.dart';

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
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
                const Text(
                  'Erro ao carregar o PPTX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
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

class ConPptxHtmlApp extends StatelessWidget {
  final PresentationData? presentation;
  final String? parseError;

  const ConPptxHtmlApp({super.key, this.presentation, this.parseError});

  @override
  Widget build(BuildContext context) {
    final emptyPresentation =
        presentation != null && presentation!.slides.isEmpty;

    return MaterialApp(
      title: 'PPTX → Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BCD4),
          secondary: Color(0xFF007AFF),
          surface: Color(0xFF0A1628),
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: presentation != null && !emptyPresentation
          ? PresentationViewer(presentation: presentation!)
          : parseError != null || emptyPresentation
          ? _ErrorScreen(
              error: parseError ?? 'O PPTX não contém slides renderizáveis.',
            )
          : const SetupScreen(),
    );
  }
}
