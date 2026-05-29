import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pptx_models.dart';
import '../platform/browser_runtime.dart' as browser;
import '../services/presenter_channel.dart';
import '../utils/animation_visibility.dart';
import '../utils/deferred_hover_state.dart';
import '../utils/quiz_slide_detector.dart';
import 'presenter_panel.dart';
import 'quiz_slide_host.dart';
import 'slide_renderer.dart';

// ── Cores de acento cicladas por slide (identidade do projeto de referência) ──
const _kAccents = [
  Color(0xFF007AFF), // blue
  Color(0xFF00C7FF), // cyan
  Color(0xFF5E5CE6), // indigo
  Color(0xFF30D158), // green
  Color(0xFFFF9F0A), // orange
];

const _kGlowAlignments = [
  Alignment.topLeft,
  Alignment.topRight,
  Alignment.bottomRight,
  Alignment.bottomLeft,
  Alignment.topCenter,
  Alignment.centerRight,
  Alignment.bottomCenter,
  Alignment.centerLeft,
];

/// Visualizador de apresentação completo com identidade visual navy/cyan.
class PresentationViewer extends StatefulWidget {
  final PresentationData presentation;
  final int initialSlide;

  const PresentationViewer({
    super.key,
    required this.presentation,
    this.initialSlide = 0,
  });

  @override
  State<PresentationViewer> createState() => _PresentationViewerState();
}

class _PresentationViewerState extends State<PresentationViewer>
    with TickerProviderStateMixin {
  late int _currentIndex;
  int _animStep = 0;
  bool _showThumbnails = true;
  bool _isFullScreen = false;
  bool _fontsReady = false;
  bool _forward = true;
  double _thumbWidth = 180;

  // ── Modo apresentador ─────────────────────────────────────────────────────
  bool _isPresenterMode = false;
  bool _swapped = false;
  bool _isAudienceFullScreen = false;
  PresenterChannel? _channel;
  StreamSubscription<PresenterMessage>? _channelSub;
  browser.AudienceWindowHandle? _audienceWindow;

  // ── Animações de chrome ───────────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _cornerCtrl;
  late final AnimationController _badgeCtrl;
  late Animation<double> _cornerAnim;
  late Animation<double> _badgeAnim;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _thumbScrollController = ScrollController();
  DateTime _lastWheelNav = DateTime.fromMillisecondsSinceEpoch(0);

  Color get _accent => _kAccents[_currentIndex % _kAccents.length];
  Color get _accent2 => _kAccents[(_currentIndex + 2) % _kAccents.length];

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.presentation.slides.length - 1;
    final persisted = browser.loadViewerState();
    final startIndex = persisted?.slideIndex ?? widget.initialSlide;
    _currentIndex = startIndex.clamp(0, maxIndex);
    _animStep = persisted?.animStep ?? 0;

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _cornerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();

    _rebuildAnims();
    _preloadFonts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _rebuildAnims() {
    _cornerAnim = CurvedAnimation(
      parent: _cornerCtrl,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    );
    _badgeAnim = CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOutBack);
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
  void dispose() {
    _channelSub?.cancel();
    _channel?.dispose();
    _focusNode.dispose();
    _thumbScrollController.dispose();
    _bgCtrl.dispose();
    _cornerCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  void _restartSlideAnims() {
    _bgCtrl.reset();
    _cornerCtrl.reset();
    _badgeCtrl.reset();
    _rebuildAnims();
    _bgCtrl.forward();
    _cornerCtrl.forward();
    _badgeCtrl.forward();
  }

  // ── Navegação ─────────────────────────────────────────────────────────────

  void _requestKeyboardFocus() {
    if (!_focusNode.hasFocus && mounted) _focusNode.requestFocus();
  }

  SlideData get _currentSlide => widget.presentation.slides[_currentIndex];

  bool get _currentSlideIsQuiz => slideHasQuizAltText(_currentSlide);

  bool get _currentSlideHasInteractiveCommand =>
      _currentSlideIsQuiz || _slideHasInteractiveCommand(_currentSlide);

  bool _slideHasInteractiveCommand(SlideData slide) {
    final commandPattern = RegExp(r'\{([^{}]+)\}');
    const interactive = {
      'arduino',
      'pyodide_code',
      'pyodide_run',
      'pyodide_awnser',
      'pyodide_answer',
    };
    bool hasCmd(String? src) {
      if (src == null || src.isEmpty) return false;
      for (final m in commandPattern.allMatches(src)) {
        if (interactive.contains(m.group(1)?.trim().toLowerCase())) {
          return true;
        }
      }
      return false;
    }

    for (final element in slide.elements) {
      if (hasCmd(element.commandText)) return true;
      switch (element) {
        case ShapeElement() when hasCmd(element.altText):
          return true;
        case ImageElement() when hasCmd(element.altText):
          return true;
        default:
          break;
      }
    }
    return false;
  }

  int get _totalSteps => _currentSlide.animSteps.length;

  void _advance() {
    if (_animStep < _totalSteps) {
      setState(() => _animStep++);
    } else {
      _goTo(_currentIndex + 1, forward: true);
      return;
    }
    _sendState();
  }

  void _retreat() {
    if (_animStep > 0) {
      setState(() => _animStep--);
    } else {
      _goTo(_currentIndex - 1, forward: false);
      return;
    }
    _sendState();
  }

  void _goTo(int index, {bool forward = true}) {
    final total = widget.presentation.slides.length;
    if (index < 0 || index >= total) return;
    setState(() {
      _forward = forward;
      _currentIndex = index;
      _animStep = 0;
    });
    _restartSlideAnims();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_thumbScrollController.hasClients) {
        _thumbScrollController.animateTo(
          index * 108.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    _sendState();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (_currentSlideHasInteractiveCommand) return;
    if (event.scrollDelta.dy.abs() < 8) return;
    final now = DateTime.now();
    if (now.difference(_lastWheelNav) < const Duration(milliseconds: 140)) {
      return;
    }
    _lastWheelNav = now;
    _requestKeyboardFocus();
    if (event.scrollDelta.dy > 0) {
      _advance();
    } else {
      _retreat();
    }
  }

  // ── Modo apresentador ─────────────────────────────────────────────────────

  void _enterPresenterMode() {
    if (!PresenterChannel.hasMultipleScreens) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo apresentador requer dois monitores conectados.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    _channel ??= PresenterChannel();
    _channelSub ??= _channel!.messages.listen(_onChannelMessage);
    _audienceWindow = PresenterChannel.openAudienceWindow();
    if (_audienceWindow == null) {
      _channelSub?.cancel();
      _channelSub = null;
      _channel?.dispose();
      _channel = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a janela da plateia.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      _isPresenterMode = true;
      _swapped = false;
    });
    Future.delayed(const Duration(milliseconds: 1500), _sendState);
  }

  void _exitPresenterMode() {
    try {
      _audienceWindow?.close();
    } catch (_) {}
    _audienceWindow = null;
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.dispose();
    _channel = null;
    setState(() {
      _isPresenterMode = false;
      _swapped = false;
    });
  }

  void _performSwap() {
    _channel?.sendSwap();
    setState(() {
      _swapped = !_swapped;
      _isAudienceFullScreen = false;
    });
  }

  void _sendState() {
    browser.saveViewerState(_currentIndex, _animStep);
    _channel?.sendState(_currentIndex, _animStep);
  }

  void _onChannelMessage(PresenterMessage msg) {
    switch (msg) {
      case PresenterStateMessage():
        break;
      case PresenterSwapMessage():
        setState(() => _swapped = !_swapped);
      case PresenterNavigateMessage(:final advance):
        if (advance) {
          _advance();
        } else {
          _retreat();
        }
    }
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    browser.requestFullscreen();
    setState(() => _isFullScreen = true);
    _sendState();
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    browser.exitFullscreen();
    setState(() => _isFullScreen = false);
    _sendState();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_currentSlideIsQuiz) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.pageDown:
        _advance();
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.pageUp:
        _retreat();
      case LogicalKeyboardKey.f5:
        _isFullScreen ? _exitFullScreen() : _enterFullScreen();
      case LogicalKeyboardKey.escape:
        if (_isPresenterMode) {
          _exitPresenterMode();
        } else if (_isFullScreen) {
          _exitFullScreen();
        }
      case LogicalKeyboardKey.home:
        _goTo(0);
      case LogicalKeyboardKey.end:
        _goTo(widget.presentation.slides.length - 1);
    }
  }

  // ── Build principal ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_fontsReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF040D18),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
        ),
      );
    }

    if (_isPresenterMode && !_swapped) {
      return PresenterPanel(
        presentation: widget.presentation,
        slideIndex: _currentIndex,
        animStep: _animStep,
        onAdvance: _advance,
        onRetreat: _retreat,
        onSwap: _performSwap,
        onExit: _exitPresenterMode,
      );
    }

    if (_isPresenterMode && _swapped) {
      return _buildAudienceSlideView();
    }

    final pres = widget.presentation;
    return Listener(
      onPointerDown: (_) => _requestKeyboardFocus(),
      onPointerSignal: _onPointerSignal,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Fundo animado (identidade visual navy/cyan)
              _buildBg(),

              // 2. Glow orbs
              _buildGlows(),

              // 3. Conteúdo principal
              _isFullScreen
                  ? _buildSlideArea(pres)
                  : LayoutBuilder(
                      builder: (ctx, constraints) {
                        if (!_showThumbnails) {
                          return _buildSlideArea(pres);
                        }
                        final tw = _thumbWidth.clamp(
                          100.0,
                          constraints.maxWidth * 0.5,
                        );
                        return Row(
                          children: [
                            SizedBox(
                              width: tw,
                              child: _buildThumbnailPanel(pres),
                            ),
                            _ThumbnailResizeHandle(
                              onDelta: (dx) => setState(() {
                                _thumbWidth = (_thumbWidth + dx).clamp(
                                  100.0,
                                  constraints.maxWidth * 0.5,
                                );
                              }),
                            ),
                            Expanded(child: _buildSlideArea(pres)),
                          ],
                        );
                      },
                    ),

              // 4. Corner accents (identidade visual)
              _buildCornerAccents(),

              // 5. Badge slide N/Total
              if (!_isFullScreen)
                Positioned(
                  top: 16,
                  left: _showThumbnails ? _thumbWidth + 10 : 16,
                  child: _buildBadge(pres),
                ),

              // 6. Barra de controles superior (direita)
              if (!_isFullScreen)
                Positioned(top: 8, right: 8, child: _buildTopControls(pres)),

              // 7. Botão sair tela cheia
              if (_isFullScreen)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _HoverButton(
                    icon: Icons.fullscreen_exit,
                    tooltip: 'Sair tela cheia',
                    onTap: _exitFullScreen,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Background animado ────────────────────────────────────────────────────

  Widget _buildBg() {
    final centers = [
      const Alignment(-0.7, -0.5),
      const Alignment(0.6, -0.4),
      const Alignment(-0.2, 0.6),
      const Alignment(0.5, 0.5),
      const Alignment(0.0, -0.8),
    ];
    final center = centers[_currentIndex % centers.length];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: 1.6,
          colors: [
            _accent.withValues(alpha: 0.12),
            _accent2.withValues(alpha: 0.04),
            Colors.black,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // ── Glow orbs ─────────────────────────────────────────────────────────────

  Widget _buildGlows() {
    final pos1 = _kGlowAlignments[_currentIndex % _kGlowAlignments.length];
    final pos2 =
        _kGlowAlignments[(_currentIndex + 4) % _kGlowAlignments.length];
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, _) {
        final t1 = CurvedAnimation(
          parent: _bgCtrl,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
        ).value;
        final t2 = CurvedAnimation(
          parent: _bgCtrl,
          curve: const Interval(0.15, 0.8, curve: Curves.easeOutBack),
        ).value;
        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: pos1,
                child: Opacity(
                  opacity: (t1 * 0.65).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.2 + t1 * 0.8,
                    child: _GlowBlob(color: _accent, size: 420),
                  ),
                ),
              ),
              Align(
                alignment: pos2,
                child: Opacity(
                  opacity: (t2 * 0.40).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.2 + t2 * 0.8,
                    child: _GlowBlob(color: _accent2, size: 320),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Corner accents ────────────────────────────────────────────────────────

  Widget _buildCornerAccents() {
    return AnimatedBuilder(
      animation: _cornerCtrl,
      builder: (context, _) {
        final t = _cornerAnim.value;
        final color = _accent.withValues(alpha: t * 0.7);
        const thickness = 2.0;
        const len = 28.0;
        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 8 + (1 - t) * -30,
                left: 8 + (1 - t) * -30,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: _Corner(
                    color: color,
                    thickness: thickness,
                    len: len,
                    quadrant: 0,
                  ),
                ),
              ),
              Positioned(
                top: 8 + (1 - t) * -30,
                right: 8 + (1 - t) * -30,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: _Corner(
                    color: color,
                    thickness: thickness,
                    len: len,
                    quadrant: 1,
                  ),
                ),
              ),
              Positioned(
                bottom: 8 + (1 - t) * -30,
                left: 8 + (1 - t) * -30,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: _Corner(
                    color: color,
                    thickness: thickness,
                    len: len,
                    quadrant: 2,
                  ),
                ),
              ),
              Positioned(
                bottom: 8 + (1 - t) * -30,
                right: 8 + (1 - t) * -30,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: _Corner(
                    color: color,
                    thickness: thickness,
                    len: len,
                    quadrant: 3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Badge slide ───────────────────────────────────────────────────────────

  Widget _buildBadge(PresentationData pres) {
    return AnimatedBuilder(
      animation: _badgeCtrl,
      builder: (context, _) {
        final t = _badgeAnim.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(-20 * (1 - t), 0),
            child: _SlideBadge(
              current: _currentIndex + 1,
              total: pres.slides.length,
              accent: _accent,
              stepInfo: _totalSteps > 0 ? '  •  $_animStep/$_totalSteps' : '',
            ),
          ),
        );
      },
    );
  }

  // ── Controles superiores ──────────────────────────────────────────────────

  Widget _buildTopControls(PresentationData pres) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlBtn(
                icon: _showThumbnails
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined,
                tooltip: 'Painel de miniaturas',
                onTap: () => setState(() => _showThumbnails = !_showThumbnails),
              ),
              _ControlBtn(
                icon: Icons.fullscreen,
                tooltip: 'Tela cheia (F5)',
                onTap: _enterFullScreen,
              ),
              if (PresenterChannel.hasMultipleScreens)
                _ControlBtn(
                  icon: Icons.present_to_all_outlined,
                  tooltip: 'Modo apresentador',
                  onTap: _enterPresenterMode,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vista plateia ─────────────────────────────────────────────────────────

  Widget _buildAudienceSlideView() {
    final pres = widget.presentation;
    final slide = pres.slides[_currentIndex];
    final quizInvocation = extractQuizInvocation(slide);
    final visibleIds = _buildVisibleIds(slide, _animStep);
    return Listener(
      onPointerDown: (_) => _requestKeyboardFocus(),
      onPointerSignal: _onPointerSignal,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: pres.canvasWidth / pres.canvasHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: pres.canvasWidth,
                      height: pres.canvasHeight,
                      child: quizInvocation != null
                          ? QuizSlideHost(
                              invocation: quizInvocation,
                              slide: slide,
                            )
                          : SlideRenderer(
                              slide: slide,
                              presentation: pres,
                              visibleIds: visibleIds,
                              animStep: _animStep,
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _HoverButton(
                  icon: _isAudienceFullScreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  tooltip: _isAudienceFullScreen
                      ? 'Sair tela cheia'
                      : 'Tela cheia',
                  onTap: () {
                    if (_isAudienceFullScreen) {
                      browser.exitFullscreen();
                      setState(() => _isAudienceFullScreen = false);
                    } else {
                      browser.requestFullscreen();
                      setState(() => _isAudienceFullScreen = true);
                    }
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 52,
                child: _HoverButton(
                  icon: Icons.swap_horiz,
                  tooltip: 'Trocar monitores',
                  onTap: _performSwap,
                ),
              ),
              Positioned(
                top: 8,
                right: 100,
                child: _HoverButton(
                  icon: Icons.close,
                  tooltip: 'Encerrar modo apresentador',
                  onTap: _exitPresenterMode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Painel de miniaturas ──────────────────────────────────────────────────

  Widget _buildThumbnailPanel(PresentationData pres) {
    return Container(
      color: const Color(0xFF0A1628),
      child: ListView.builder(
        controller: _thumbScrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: pres.slides.length,
        itemBuilder: (_, i) => _buildThumbnailItem(i, pres),
      ),
    );
  }

  Widget _buildThumbnailItem(int index, PresentationData pres) {
    final isSelected = index == _currentIndex;
    return GestureDetector(
      onTap: () => _goTo(index, forward: index > _currentIndex),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _accent : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: pres.canvasWidth / pres.canvasHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: pres.canvasWidth,
                    height: pres.canvasHeight,
                    child: slideHasQuizAltText(pres.slides[index])
                        ? const QuizSlidePlaceholder()
                        : SlideRenderer(
                            slide: pres.slides[index],
                            presentation: pres,
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Área do slide com AnimatedSwitcher + transição referência ─────────────

  Widget _buildSlideArea(PresentationData pres) {
    final slide = _currentIndex;
    final fwd = _forward;
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 780),
          transitionBuilder: (child, anim) {
            final key = child.key as ValueKey<int>;
            final incoming = key.value == slide;
            return _buildTransition(child, anim, incoming, fwd);
          },
          child: _buildSingleSlide(
            key: ValueKey<int>(slide),
            pres: pres,
            index: slide,
          ),
        ),

        // Clique esquerda/direita para navegar
        if (!_currentSlideHasInteractiveCommand)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _requestKeyboardFocus();
                      _retreat();
                    },
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _requestKeyboardFocus();
                      _advance();
                    },
                  ),
                ),
              ],
            ),
          ),

        // Botão anterior
        if (_currentIndex > 0 || _animStep > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavButton(icon: Icons.chevron_left, onTap: _retreat),
            ),
          ),

        // Botão próximo
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: _NavButton(icon: Icons.chevron_right, onTap: _advance),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleSlide({
    required Key key,
    required PresentationData pres,
    required int index,
  }) {
    final slide = pres.slides[index];
    final quizInvocation = extractQuizInvocation(slide);
    final visibleIds = _buildVisibleIds(
      slide,
      index == _currentIndex ? _animStep : 999,
    );
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: pres.canvasWidth / pres.canvasHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 60,
                  offset: const Offset(0, 24),
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: _accent.withValues(alpha: 0.12),
                  blurRadius: 70,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
                          visibleIds: visibleIds,
                          animStep: index == _currentIndex ? _animStep : 999,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Transição inspirada no projeto de referência: fade + slide + scale.
  Widget _buildTransition(
    Widget child,
    Animation<double> anim,
    bool incoming,
    bool fwd,
  ) {
    final isDiag = _currentIndex % 3 == 2;
    final dy = isDiag ? (fwd ? -0.06 : 0.06) : 0.0;

    if (incoming) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: anim, curve: const Interval(0, 0.45)),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(fwd ? 1.1 : -1.1, dy),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutQuart)),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutQuart),
            ),
            child: child,
          ),
        ),
      );
    } else {
      return FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(fwd ? -0.10 : 0.10, fwd ? dy * 0.5 : -dy * 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInQuart)),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 1.05,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInQuart)),
            child: child,
          ),
        ),
      );
    }
  }

  Set<int>? _buildVisibleIds(SlideData slide, int step) =>
      buildVisibleShapeIds(slide, step);
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets visuais do chrome (identidade navy/cyan)
// ─────────────────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: size * 0.55,
            spreadRadius: size * 0.15,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: size * 0.9,
            spreadRadius: size * 0.3,
          ),
        ],
      ),
    );
  }
}

// ── Corner bracket (quadrant: 0=TL, 1=TR, 2=BL, 3=BR) ────────────────────

class _Corner extends StatelessWidget {
  final Color color;
  final double thickness;
  final double len;
  final int quadrant;
  const _Corner({
    required this.color,
    required this.thickness,
    required this.len,
    required this.quadrant,
  });

  @override
  Widget build(BuildContext context) {
    final flipX = quadrant == 1 || quadrant == 3;
    final flipY = quadrant == 2 || quadrant == 3;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        flipX ? -1.0 : 1.0,
        flipY ? -1.0 : 1.0,
        1.0,
      ),
      child: SizedBox(
        width: len,
        height: len,
        child: CustomPaint(
          painter: _CornerPainter(color: color, thickness: thickness),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  const _CornerPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.thickness != thickness;
}

// ── Slide badge ───────────────────────────────────────────────────────────

class _SlideBadge extends StatelessWidget {
  final int current;
  final int total;
  final Color accent;
  final String stepInfo;

  const _SlideBadge({
    required this.current,
    required this.total,
    required this.accent,
    this.stepInfo = '',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$current / $total$stepInfo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botão de controle glassmorphic ─────────────────────────────────────────

class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ControlBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn>
    with DeferredHoverState<_ControlBtn> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: AnimatedOpacity(
        opacity: hovered ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 150),
        child: Tooltip(
          message: widget.tooltip,
          child: IconButton(
            icon: Icon(widget.icon, color: Colors.white, size: 20),
            onPressed: widget.onTap,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão com fade no hover (usado na vista plateia)
// ─────────────────────────────────────────────────────────────────────────────

class _HoverButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HoverButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton>
    with DeferredHoverState<_HoverButton> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: AnimatedOpacity(
        opacity: hovered ? 0.9 : 0.15,
        duration: const Duration(milliseconds: 200),
        child: Tooltip(
          message: widget.tooltip,
          child: IconButton(
            icon: Icon(widget.icon, color: Colors.white),
            onPressed: widget.onTap,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão de navegação prev/next
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with DeferredHoverState<_NavButton> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: hovered ? 0.9 : 0.2,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 40,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Handle redimensionável do painel de miniaturas
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailResizeHandle extends StatefulWidget {
  final void Function(double dx) onDelta;
  const _ThumbnailResizeHandle({required this.onDelta});

  @override
  State<_ThumbnailResizeHandle> createState() => _ThumbnailResizeHandleState();
}

class _ThumbnailResizeHandleState extends State<_ThumbnailResizeHandle>
    with DeferredHoverState<_ThumbnailResizeHandle> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => widget.onDelta(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 6,
          color: hovered
              ? const Color(0xFF00BCD4).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
          child: Center(
            child: Container(
              width: 2,
              height: 36,
              decoration: BoxDecoration(
                color: hovered ? Colors.white70 : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
