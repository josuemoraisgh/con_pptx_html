import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'models/pptx_models.dart';
import 'parsers/pptx_parser.dart';
import 'platform/browser_runtime.dart' as browser;
import 'screens/audience_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  PresentationData? _presentation;
  String? _parseError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPresentation();
  }

  Future<void> _loadPresentation() async {
    PresentationData? presentation;
    String? parseError;
    try {
      final data = await rootBundle.load('assets/presentation.pptx');
      presentation = PptxParser().parse(data.buffer.asUint8List());
    } catch (e, st) {
      parseError = '$e\n$st';
      debugPrint('PPTX parse error: $e\n$st');
    }

    if (!mounted) return;
    setState(() {
      _presentation = presentation;
      _parseError = parseError;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        title: 'PPTX -> Web',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const Scaffold(
          backgroundColor: Color(0xFF0F0F1A),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF7C6AF7)),
          ),
        ),
      );
    }

    final presentation = _presentation;
    final isAudience = browser.isAudienceView;
    final hasSlides = presentation?.slides.isNotEmpty ?? false;

    return isAudience && presentation != null && hasSlides
        ? _AudienceApp(presentation: presentation)
        : ConPptxHtmlApp(presentation: presentation, parseError: _parseError);
  }
}

class _AudienceApp extends StatelessWidget {
  final PresentationData presentation;

  const _AudienceApp({required this.presentation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apresentacao - Plateia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AudienceScreen(presentation: presentation),
    );
  }
}
