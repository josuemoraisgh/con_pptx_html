import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pptx_models.dart';
import '../utils/quiz_slide_detector.dart';
import '../widgets/quiz_slide_host.dart';
import '../widgets/slide_renderer.dart';

/// Renderiza um slide único sem nenhuma UI — usado para comparação visual.
/// Acesso via: /?view=raw&n=0  (n é o índice base 0)
class RawSlideScreen extends StatefulWidget {
  final PresentationData presentation;
  final int slideIndex;

  const RawSlideScreen({
    super.key,
    required this.presentation,
    required this.slideIndex,
  });

  @override
  State<RawSlideScreen> createState() => _RawSlideScreenState();
}

class _RawSlideScreenState extends State<RawSlideScreen> {
  bool _fontsReady = false;

  @override
  void initState() {
    super.initState();
    _preloadFonts();
  }

  Future<void> _preloadFonts() async {
    final embeddedFonts = widget.presentation.embeddedFonts;
    if (embeddedFonts.isNotEmpty) {
      final loaders = <String, FontLoader>{};
      for (final face in embeddedFonts) {
        final loader = loaders.putIfAbsent(
          face.family,
          () => FontLoader(face.family),
        );
        loader.addFont(
          Future<ByteData>.value(ByteData.sublistView(face.bytes)),
        );
      }
      for (final loader in loaders.values) {
        try {
          await loader.load();
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _fontsReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_fontsReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pres = widget.presentation;
    final idx = widget.slideIndex.clamp(0, pres.slides.length - 1);
    final slide = pres.slides[idx];
    final quizInvocation = extractQuizInvocation(slide);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: pres.canvasWidth / pres.canvasHeight,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: pres.canvasWidth,
              height: pres.canvasHeight,
              child: quizInvocation != null
                  ? QuizSlideHost(invocation: quizInvocation, slide: slide)
                  : SlideRenderer(
                      slide: slide,
                      presentation: pres,
                      visibleIds: null,
                      animStep: 0,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
