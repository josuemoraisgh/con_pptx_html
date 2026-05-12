import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'models/pptx_models.dart';
import 'parsers/pptx_parser.dart';
import 'screens/audience_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PresentationData? presentation;
  String? parseError;
  try {
    final data = await rootBundle.load('assets/presentation.pptx');
    presentation = PptxParser().parse(data.buffer.asUint8List());
  } catch (e, st) {
    parseError = '$e\n$st';
    debugPrint('PPTX parse error: $e\n$st');
  }

  // Detecta se esta janela é a janela da plateia (?view=audience)
  final isAudience =
      Uri.tryParse(web.window.location.href)?.queryParameters['view'] ==
      'audience';

  runApp(
    isAudience && presentation != null
        ? _AudienceApp(presentation: presentation)
        : ConPptxHtmlApp(presentation: presentation, parseError: parseError),
  );
}

/// App minimalista para a janela da plateia (sem MaterialApp completo do tema).
class _AudienceApp extends StatelessWidget {
  final PresentationData presentation;
  const _AudienceApp({required this.presentation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apresentação — Plateia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AudienceScreen(presentation: presentation),
    );
  }
}
