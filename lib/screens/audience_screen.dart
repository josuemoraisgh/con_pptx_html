import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../models/pptx_models.dart';
import '../services/presenter_channel.dart';
import '../widgets/slide_renderer.dart';

// A importação é circular aparente, mas presenter_panel.dart não importa
// audience_screen.dart — sem ciclo real.
import '../widgets/presenter_panel.dart';

/// Janela da plateia: exibe o slide atual recebido via [PresenterChannel].
/// Quando ocorre um swap, exibe o painel do apresentador (modo leitura/remoto).
class AudienceScreen extends StatefulWidget {
  final PresentationData presentation;

  const AudienceScreen({super.key, required this.presentation});

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  final _channel = PresenterChannel();
  StreamSubscription<PresenterMessage>? _sub;

  int _slideIndex = 0;
  int _animStep = 0;

  /// true → esta janela exibe o painel do apresentador (após swap)
  bool _swapped = false;
  bool _isFullScreen = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _sub = _channel.messages.listen(_onMessage);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _onMessage(PresenterMessage msg) {
    switch (msg) {
      case PresenterStateMessage(:final slideIndex, :final animStep):
        setState(() {
          _slideIndex = slideIndex;
          _animStep = animStep;
        });
      case PresenterSwapMessage():
        setState(() => _swapped = !_swapped);
      case PresenterNavigateMessage():
        // Não se aplica aqui (comandos de naveg. vão para a janela controladora)
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterFullScreen() {
    web.document.documentElement?.requestFullscreen();
    setState(() => _isFullScreen = true);
  }

  void _exitFullScreen() {
    web.document.exitFullscreen();
    setState(() => _isFullScreen = false);
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.pageDown:
        _channel.sendNavigate(advance: true);
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.pageUp:
        _channel.sendNavigate(advance: false);
      case LogicalKeyboardKey.f5:
        _isFullScreen ? _exitFullScreen() : _enterFullScreen();
      case LogicalKeyboardKey.escape:
        if (_isFullScreen) _exitFullScreen();
    }
  }

  Set<int>? _buildVisibleIds(SlideData slide, int step) {
    if (slide.animSteps.isEmpty) return null;
    final allAnimated = <int>{};
    for (final s in slide.animSteps) {
      allAnimated.addAll(s);
    }
    final visible = <int>{};
    for (final el in slide.elements) {
      if (!allAnimated.contains(el.shapeId)) visible.add(el.shapeId);
    }
    for (var i = 0; i < slide.animSteps.length && i < step; i++) {
      visible.addAll(slide.animSteps[i]);
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    // Após swap: esta janela exibe o painel do apresentador (remoto)
    if (_swapped) {
      return PresenterPanel(
        presentation: widget.presentation,
        slideIndex: _slideIndex,
        animStep: _animStep,
        onAdvance: () => _channel.sendNavigate(advance: true),
        onRetreat: () => _channel.sendNavigate(advance: false),
        onSwap: () {
          _channel.sendSwap();
          setState(() => _swapped = false);
        },
        onExit: null,
      );
    }

    // Vista padrão: slide em tela cheia
    final pres = widget.presentation;
    final idx = _slideIndex.clamp(0, pres.slides.length - 1);
    final slide = pres.slides[idx];
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

            // Overlay: botão tela cheia (auto-fade)
            Positioned(
              top: 8,
              right: 8,
              child: _FadeButton(
                icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                tooltip: _isFullScreen ? 'Sair tela cheia' : 'Tela cheia',
                onTap: _isFullScreen ? _exitFullScreen : _enterFullScreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão com fade no hover
// ─────────────────────────────────────────────────────────────────────────────

class _FadeButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _FadeButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_FadeButton> createState() => _FadeButtonState();
}

class _FadeButtonState extends State<_FadeButton> {
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
