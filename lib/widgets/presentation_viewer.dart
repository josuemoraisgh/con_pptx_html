import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pptx_models.dart';
import '../platform/browser_runtime.dart' as browser;
import '../services/presenter_channel.dart';
import '../utils/animation_visibility.dart';
import '../utils/deferred_hover_state.dart';
import 'presenter_panel.dart';
import 'slide_renderer.dart';

/// Visualizador de apresentação completo com navegação por teclado/click.
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

class _PresentationViewerState extends State<PresentationViewer> {
  late int _currentIndex;

  /// Step atual de animação dentro do slide (0 = tudo visível desde o início).
  int _animStep = 0;
  bool _showThumbnails = true;
  bool _isFullScreen = false;

  /// true enquanto as fontes Google estão sendo pré-carregadas.
  bool _fontsReady = false;

  /// Largura do painel de miniaturas (redimensionável por drag).
  double _thumbWidth = 180;

  // ── Modo apresentador ─────────────────────────────────────────────────────
  bool _isPresenterMode = false;

  /// true = esta janela exibe o slide (plateia) e a popup exibe o painel.
  bool _swapped = false;

  /// Tela cheia quando esta janela está no modo plateia (swapped).
  bool _isAudienceFullScreen = false;

  PresenterChannel? _channel;
  StreamSubscription<PresenterMessage>? _channelSub;
  browser.AudienceWindowHandle? _audienceWindow;
  // ─────────────────────────────────────────────────────────────────────────

  final FocusNode _focusNode = FocusNode();
  late final PageController _pageController;
  final ScrollController _thumbScrollController = ScrollController();
  DateTime _lastWheelNav = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.presentation.slides.length - 1;
    final persisted = browser.loadViewerState();
    final startIndex = persisted?.slideIndex ?? widget.initialSlide;
    _currentIndex = startIndex.clamp(0, maxIndex);
    _animStep = persisted?.animStep ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    _preloadFonts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _restoreSlidePosition(_currentIndex, _animStep);
    });
  }

  /// Mantém o gate inicial para sincronizar a primeira renderização.
  /// A fonte usada agora segue diretamente o nome vindo do OOXML.
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
        } catch (_) {
          // Mantém fallback para fontes do sistema quando o face embutido falhar.
        }
      }
    }
    if (mounted) setState(() => _fontsReady = true);
  }

  void _requestKeyboardFocus() {
    if (!_focusNode.hasFocus && mounted) {
      _focusNode.requestFocus();
    }
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

  @override
  void dispose() {
    _channelSub?.cancel();
    _channel?.dispose();
    _focusNode.dispose();
    _pageController.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  SlideData get _currentSlide => widget.presentation.slides[_currentIndex];

  bool get _currentSlideHasInteractiveCommand =>
      _slideHasInteractiveCommand(_currentSlide);

  bool _slideHasInteractiveCommand(SlideData slide) {
    final commandPattern = RegExp(r'\{([^{}]+)\}');
    const interactive = {
      'arduino',
      'pyodide_code',
      'pyodide_run',
      'pyodide_awnser',
      'pyodide_answer',
    };

    bool hasInteractiveCommand(String? source) {
      if (source == null || source.isEmpty) return false;
      for (final match in commandPattern.allMatches(source)) {
        if (interactive.contains(match.group(1)?.trim().toLowerCase())) {
          return true;
        }
      }
      return false;
    }

    for (final element in slide.elements) {
      if (hasInteractiveCommand(element.commandText)) return true;
      switch (element) {
        case ShapeElement() when hasInteractiveCommand(element.altText):
          return true;
        case ImageElement() when hasInteractiveCommand(element.altText):
          return true;
        case TableElement():
          break;
        case ShapeElement():
          break;
        case ImageElement():
          break;
      }
    }
    return false;
  }

  /// Número total de cliques necessários para ver todos os elementos do slide.
  int get _totalSteps => _currentSlide.animSteps.length;

  /// Avança: se há mais steps no slide, avança step; senão, vai ao próximo slide.
  void _advance() {
    if (_animStep < _totalSteps) {
      setState(() => _animStep++);
    } else {
      _goTo(_currentIndex + 1);
      return;
    }
    _sendState();
  }

  /// Recua: se há steps anteriores, recua; senão, vai ao slide anterior.
  void _retreat() {
    if (_animStep > 0) {
      setState(() => _animStep--);
    } else {
      _goTo(_currentIndex - 1);
      return;
    }
    _sendState();
  }

  void _goTo(int index) {
    final total = widget.presentation.slides.length;
    if (index < 0 || index >= total) return;
    final ms = widget.presentation.slides[index].transitionMs;
    setState(() {
      _currentIndex = index;
      _animStep = 0;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: ms),
        curve: Curves.easeInOut,
      );
    }
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
    // Aguarda a popup carregar antes de enviar o estado inicial
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
      _isAudienceFullScreen = false; // reset fullscreen ao trocar
    });
  }

  void _sendState() {
    browser.saveViewerState(_currentIndex, _animStep);
    _channel?.sendState(_currentIndex, _animStep);
  }

  void _restoreSlidePosition(int index, int step) {
    final total = widget.presentation.slides.length;
    final safeIndex = index.clamp(0, total - 1);
    if (!mounted) return;

    setState(() {
      _currentIndex = safeIndex;
      _animStep = step;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(safeIndex);
    });
  }

  void _onChannelMessage(PresenterMessage msg) {
    switch (msg) {
      case PresenterStateMessage():
        break; // Esta janela não recebe estado
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_fontsReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C6AF7)),
        ),
      );
    }

    // Modo apresentador ativo + não swapped → exibe o painel do apresentador
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

    // Modo apresentador ativo + swapped → esta janela exibe o slide (plateia)
    if (_isPresenterMode && _swapped) {
      return _buildAudienceSlideView();
    }

    // Modo normal
    final pres = widget.presentation;
    return Listener(
      onPointerDown: (_) => _requestKeyboardFocus(),
      onPointerSignal: _onPointerSignal,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: const Color(0xFF1E1E2E),
          appBar: _isFullScreen ? null : _buildAppBar(pres),
          body: _isFullScreen
              ? _buildSlideArea(pres)
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    final maxW = constraints.maxWidth;
                    if (!_showThumbnails) return _buildSlideArea(pres);
                    final tw = _thumbWidth.clamp(100.0, maxW * 0.5);
                    return Row(
                      children: [
                        SizedBox(width: tw, child: _buildThumbnailPanel(pres)),
                        // Handle de redimensionamento
                        _ThumbnailResizeHandle(
                          onDelta: (dx) => setState(() {
                            _thumbWidth = (_thumbWidth + dx).clamp(
                              100.0,
                              maxW * 0.5,
                            );
                          }),
                        ),
                        Expanded(child: _buildSlideArea(pres)),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// Vista minimalista do slide usado quando esta janela é a "plateia" (swapped).
  Widget _buildAudienceSlideView() {
    final pres = widget.presentation;
    final slide = pres.slides[_currentIndex];
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
                      child: SlideRenderer(
                        slide: slide,
                        presentation: pres,
                        visibleIds: visibleIds,
                        animStep: _animStep,
                      ),
                    ),
                  ),
                ),
              ),
              // Overlay: botões com auto-fade
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

  PreferredSizeWidget _buildAppBar(PresentationData pres) {
    final stepInfo = _totalSteps > 0
        ? '  •  clique $_animStep/$_totalSteps'
        : '';
    return AppBar(
      backgroundColor: const Color(0xFF13131F),
      foregroundColor: Colors.white,
      title: Text(
        'Slide ${_currentIndex + 1} / ${pres.slides.length}$stepInfo',
        style: const TextStyle(fontSize: 14, color: Colors.white70),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showThumbnails ? Icons.view_sidebar : Icons.view_sidebar_outlined,
            color: Colors.white70,
          ),
          tooltip: 'Painel de miniaturas',
          onPressed: () => setState(() => _showThumbnails = !_showThumbnails),
        ),
        // Botão tela cheia (F5)
        IconButton(
          icon: const Icon(Icons.fullscreen, color: Colors.white70),
          tooltip: 'Tela cheia (F5)',
          onPressed: _enterFullScreen,
        ),
        // Botão modo apresentador: visível apenas quando há 2 monitores
        if (PresenterChannel.hasMultipleScreens)
          IconButton(
            icon: const Icon(
              Icons.present_to_all_outlined,
              color: Colors.white70,
            ),
            tooltip: 'Modo apresentador (requer 2 monitores)',
            onPressed: _enterPresenterMode,
          ),
      ],
    );
  }

  // ── Painel de miniaturas ───────────────────────────────────────────────────

  Widget _buildThumbnailPanel(PresentationData pres) {
    return Container(
      color: const Color(0xFF13131F),
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
    final aspectRatio = pres.canvasWidth / pres.canvasHeight;

    return GestureDetector(
      onTap: () => _goTo(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF7C6AF7) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: pres.canvasWidth,
                    height: pres.canvasHeight,
                    // Miniaturas mostram o slide completo (sem filtro de animação)
                    child: SlideRenderer(
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
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Área do slide principal ───────────────────────────────────────────────

  Widget _buildSlideArea(PresentationData pres) {
    return Stack(
      children: [
        // PageView com fade entre slides
        PageView.builder(
          controller: _pageController,
          itemCount: pres.slides.length,
          physics: const NeverScrollableScrollPhysics(), // só via código
          onPageChanged: (i) => setState(() {
            _currentIndex = i;
            _animStep = 0;
          }),
          itemBuilder: (_, i) {
            final slide = pres.slides[i];
            // Calcula o conjunto de IDs visíveis neste step
            final visibleIds = _buildVisibleIds(
              slide,
              i == _currentIndex ? _animStep : 999,
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: pres.canvasWidth / pres.canvasHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: pres.canvasWidth,
                      height: pres.canvasHeight,
                      child: SlideRenderer(
                        slide: slide,
                        presentation: pres,
                        visibleIds: visibleIds,
                        animStep: i == _currentIndex ? _animStep : 999,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Toque/clique na metade direita avança, esquerda recua.
        // Em slides com comando interativo (ex.: {arduino}), essa camada
        // é desativada para não bloquear scroll e interação no conteúdo.
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

        // Botão sair tela cheia
        if (_isFullScreen)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white70),
              onPressed: _exitFullScreen,
            ),
          ),
      ],
    );
  }

  /// Constrói o Set de shapeIds visíveis no step atual.
  /// Em modo viewer normal (não-apresentador) retorna null (= tudo visível),
  /// preservando as animações apenas no modo apresentador.
  Set<int>? _buildVisibleIds(SlideData slide, int step) =>
      _isPresenterMode ? buildVisibleShapeIds(slide, step) : null;

  // ── Tela cheia ────────────────────────────────────────────────────────────

  void _enterFullScreen() {
    final keepIndex = _currentIndex;
    final keepStep = _animStep;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    browser.requestFullscreen();
    setState(() => _isFullScreen = true);
    _restoreSlidePosition(keepIndex, keepStep);
    _sendState();
  }

  void _exitFullScreen() {
    final keepIndex = _currentIndex;
    final keepStep = _animStep;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    browser.exitFullscreen();
    setState(() => _isFullScreen = false);
    _restoreSlidePosition(keepIndex, keepStep);
    _sendState();
  }

  // ── Teclado ───────────────────────────────────────────────────────────────

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
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
        if (_isFullScreen) {
          _exitFullScreen();
        } else {
          _enterFullScreen();
        }
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
// Botão de navegação
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
          opacity: hovered ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 40,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 32),
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
              ? const Color(0xFF7C6AF7).withAlpha(200)
              : Colors.white10,
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
