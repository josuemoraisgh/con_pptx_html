import 'package:flutter/material.dart';

import 'app.dart';
import 'generated/presentation_data.g.dart';
import 'platform/browser_runtime.dart' as browser;
import 'screens/audience_screen.dart';
import 'screens/raw_slide_screen.dart';

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Dados compilados no WASM durante o build — carregamento síncrono.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        title: 'PPTX → Web',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF040D18),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
          ),
        ),
      );
    }

    final presentation = kGeneratedPresentation;
    final hasSlides = presentation?.slides.isNotEmpty ?? false;

    if (browser.isRawView && presentation != null && hasSlides) {
      return MaterialApp(
        title: 'Raw Slide',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: RawSlideScreen(
          presentation: presentation,
          slideIndex: browser.rawSlideIndex,
        ),
      );
    }

    if (browser.isAudienceView && presentation != null && hasSlides) {
      return MaterialApp(
        title: 'Apresentação - Plateia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: AudienceScreen(presentation: presentation),
      );
    }

    return ConPptxHtmlApp(
      presentation: presentation,
      parseError: null,
    );
  }
}
