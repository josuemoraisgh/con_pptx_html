import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

import '../models/pptx_models.dart';
import '../services/presenter_channel.dart';
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
  web.Window? _audienceWindow;
  // ─────────────────────────────────────────────────────────────────────────

  final FocusNode _focusNode = FocusNode();
  final PageController _pageController = PageController();
  final ScrollController _thumbScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialSlide;
    _preloadFonts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  /// Pré-carrega todas as fontes Google usadas na apresentação para evitar
  /// layout shift quando as fontes chegam assincronamente. Mapeia nomes de
  /// fontes do PPTX (Calibri, Cambria, etc.) para fontes equivalentes que
  /// existem no Google Fonts e baixa todas as variantes usadas (regular,
  /// bold, italic, boldItalic).
  Future<void> _preloadFonts() async {
    final pres = widget.presentation;

    // Coleta nomes brutos + variantes (bold/italic) realmente usadas.
    final variants = <String, Set<int>>{}; // family -> bitmask: 1=bold, 2=italic

    void register(String? raw, {bool bold = false, bool italic = false}) {
      if (raw == null || raw.isEmpty) return;
      // Resolve +mj-lt / +mn-lt
      String resolved = raw;
      if (raw.startsWith('+mj')) resolved = pres.theme.majorFontLatin;
      if (raw.startsWith('+mn')) resolved = pres.theme.minorFontLatin;
      final mapped = SlideRenderer.mapToSafeFont(resolved);
      final mask = (bold ? 1 : 0) | (italic ? 2 : 0);
      variants.putIfAbsent(mapped, () => <int>{}).add(mask);
    }

    register(pres.theme.majorFontLatin);
    register(pres.theme.majorFontLatin, bold: true);
    register(pres.theme.minorFontLatin);
    register(pres.theme.minorFontLatin, bold: true);

    for (final slide in pres.slides) {
      for (final el in slide.elements) {
        if (el is ShapeElement) {
          for (final para in el.paragraphs) {
            for (final run in para.runs) {
              register(run.props.fontFamily,
                  bold: run.props.bold, italic: run.props.italic);
            }
          }
        }
      }
    }

    // Dispara o download de cada (family, weight, style) e aguarda.
    for (final entry in variants.entries) {
      final family = entry.key;
      for (final mask in entry.value) {
        final weight = (mask & 1) != 0 ? FontWeight.w700 : FontWeight.w400;
        final style =
            (mask & 2) != 0 ? FontStyle.italic : FontStyle.normal;
        try {
          GoogleFonts.getFont(
            family,
            textStyle: TextStyle(fontWeight: weight, fontStyle: style),
          );
        } catch (_) {}
      }
    }

    try {
      await GoogleFonts.pendingFonts();
    } catch (_) {}
    if (mounted) setState(() => _fontsReady = true);
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
    _channel?.sendState(_currentIndex, _animStep);
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
    return KeyboardListener(
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
    );
  }

  /// Vista minimalista do slide usado quando esta janela é a "plateia" (swapped).
  Widget _buildAudienceSlideView() {
    final pres = widget.presentation;
    final slide = pres.slides[_currentIndex];
    final visibleIds = _buildVisibleIds(slide, _animStep);
    return KeyboardListener(
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
                    web.document.exitFullscreen();
                    setState(() => _isAudienceFullScreen = false);
                  } else {
                    web.document.documentElement?.requestFullscreen();
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
        // Botão modo apresentador (ativa apenas com 2 monitores)
        IconButton(
          icon: const Icon(
            Icons.present_to_all_outlined,
            color: Colors.white70,
          ),
          tooltip: 'Modo apresentador (requer 2 monitores)',
          onPressed: _enterPresenterMode,
        ),
        IconButton(
          icon: const Icon(Icons.fullscreen, color: Colors.white70),
          tooltip: 'Tela cheia (F5)',
          onPressed: _enterFullScreen,
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

        // Toque/clique na metade direita avança, esquerda recua
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _retreat,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _advance,
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

        // Indicador de progresso
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: _buildProgressIndicator(pres.slides.length),
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
  Set<int>? _buildVisibleIds(SlideData slide, int step) {
    if (!_isPresenterMode) return null;
    if (slide.animSteps.isEmpty) return null;

    // Coleta todos os IDs que aparecem em algum step
    final allAnimatedIds = <int>{};
    for (final s in slide.animSteps) {
      allAnimatedIds.addAll(s);
    }

    // IDs visíveis = os que não têm animação + os que já foram revelados
    final visible = <int>{};
    for (final el in slide.elements) {
      // Placeholders de título/subtítulo sempre visíveis (não ocultados por animação)
      if (el is ShapeElement && _isTitlePlaceholder(el.placeholderType)) {
        visible.add(el.shapeId);
      } else if (!allAnimatedIds.contains(el.shapeId)) {
        visible.add(el.shapeId);
      }
    }
    // Adiciona os que foram revelados até o step atual
    for (var i = 0; i < slide.animSteps.length && i < step; i++) {
      visible.addAll(slide.animSteps[i]);
    }
    return visible;
  }

  bool _isTitlePlaceholder(String? type) =>
      type == 'title' || type == 'ctrTitle' || type == 'subTitle';

  Widget _buildProgressIndicator(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total > 30 ? 1 : total, (i) {
        if (total > 30) {
          return Text(
            '${_currentIndex + 1} / $total',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          );
        }
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _currentIndex
                ? const Color(0xFF7C6AF7)
                : Colors.white24,
          ),
        );
      }),
    );
  }

  // ── Tela cheia ────────────────────────────────────────────────────────────

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    web.document.documentElement?.requestFullscreen();
    setState(() => _isFullScreen = true);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    web.document.exitFullscreen();
    setState(() => _isFullScreen = false);
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

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedOpacity(
        opacity: _hovered ? 0.9 : 0.15,
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

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _hovered ? 1.0 : 0.3,
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

class _ThumbnailResizeHandleState extends State<_ThumbnailResizeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => widget.onDelta(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 6,
          color: _hovered
              ? const Color(0xFF7C6AF7).withAlpha(200)
              : Colors.white10,
          child: Center(
            child: Container(
              width: 2,
              height: 36,
              decoration: BoxDecoration(
                color: _hovered ? Colors.white70 : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
