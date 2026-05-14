import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pptx_models.dart';
import '../utils/animation_visibility.dart';
import '../utils/deferred_hover_state.dart';
import 'slide_renderer.dart';

/// Painel completo do apresentador.
///
/// Exibe:
/// - Slide atual (grande, com estado de animação)
/// - Próximo slide (miniatura)
/// - Anotações do apresentador
/// - Cronômetro da apresentação
/// - Controles de navegação
/// - Botão swap e botão sair
class PresenterPanel extends StatefulWidget {
  final PresentationData presentation;
  final int slideIndex;
  final int animStep;
  final VoidCallback onAdvance;
  final VoidCallback onRetreat;
  final VoidCallback onSwap;

  /// Callback para encerrar o modo apresentador (null oculta o botão).
  final VoidCallback? onExit;

  const PresenterPanel({
    super.key,
    required this.presentation,
    required this.slideIndex,
    required this.animStep,
    required this.onAdvance,
    required this.onRetreat,
    required this.onSwap,
    this.onExit,
  });

  @override
  State<PresenterPanel> createState() => _PresenterPanelState();
}

class _PresenterPanelState extends State<PresenterPanel> {
  late final Stopwatch _stopwatch;
  late final Timer _tick;
  final FocusNode _focusNode = FocusNode();
  DateTime _lastWheelNav = DateTime.fromMillisecondsSinceEpoch(0);

  /// Fração da largura total ocupada pelo painel direito (drag horizontal).
  double _rightPanelFraction = 0.32;

  /// Fração da altura do painel direito reservada para o próximo slide (drag vertical).
  double _nextSlideFraction = 0.52;

  static const _minRightFraction = 0.12;
  static const _maxRightFraction = 0.82;
  static const _minNextSlideFraction = 0.15;
  static const _maxNextSlideFraction = 0.85;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _tick.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  String get _elapsed {
    final d = _stopwatch.elapsed;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  SlideData get _currentSlide {
    final i = widget.slideIndex.clamp(0, widget.presentation.slides.length - 1);
    return widget.presentation.slides[i];
  }

  SlideData? get _nextSlide {
    final ni = widget.slideIndex + 1;
    if (ni >= widget.presentation.slides.length) return null;
    return widget.presentation.slides[ni];
  }

  bool get _canRetreat => widget.slideIndex > 0 || widget.animStep > 0;

  bool get _canAdvance =>
      widget.slideIndex < widget.presentation.slides.length - 1 ||
      widget.animStep < _currentSlide.animSteps.length;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Set<int>? _buildVisibleIds(SlideData slide, int step) =>
      buildVisibleShapeIds(slide, step);

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.pageDown:
        widget.onAdvance();
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.pageUp:
        widget.onRetreat();
    }
  }

  void _requestKeyboardFocus() {
    if (!_focusNode.hasFocus && mounted) {
      _focusNode.requestFocus();
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (event.scrollDelta.dy.abs() < 8) return;

    final now = DateTime.now();
    if (now.difference(_lastWheelNav) < const Duration(milliseconds: 140)) {
      return;
    }
    _lastWheelNav = now;
    _requestKeyboardFocus();

    if (event.scrollDelta.dy > 0) {
      widget.onAdvance();
    } else {
      widget.onRetreat();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pres = widget.presentation;
    final total = pres.slides.length;
    final current = _currentSlide;
    final next = _nextSlide;
    final visibleIds = _buildVisibleIds(current, widget.animStep);

    return Listener(
      onPointerDown: (_) => _requestKeyboardFocus(),
      onPointerSignal: _onPointerSignal,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: Column(
            children: [
              _buildTopBar(total),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final totalW = constraints.maxWidth;
                    final rightW = (totalW * _rightPanelFraction).clamp(
                      totalW * _minRightFraction,
                      totalW * _maxRightFraction,
                    );
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Slide atual (grande) ──────────────────────────────
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                            child: Column(
                              children: [
                                Expanded(
                                  child: _buildCurrentSlide(
                                    pres,
                                    current,
                                    visibleIds,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildAnimDots(current),
                              ],
                            ),
                          ),
                        ),
                        // ── Handle horizontal (redimensiona painel direito) ───
                        _ResizeHandle(
                          onDelta: (dx) {
                            setState(() {
                              _rightPanelFraction = ((rightW - dx) / totalW)
                                  .clamp(_minRightFraction, _maxRightFraction);
                            });
                          },
                        ),
                        // ── Painel direito ───────────────────────────────────
                        SizedBox(
                          width: rightW,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 12, 0),
                            child: LayoutBuilder(
                              builder: (ctx2, c2) {
                                final h = c2.maxHeight;
                                final nextH = (h * _nextSlideFraction).clamp(
                                  h * _minNextSlideFraction,
                                  h * _maxNextSlideFraction,
                                );
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: nextH,
                                      child: _buildNextSlide(pres, next),
                                    ),
                                    // ── Handle vertical (redimensiona notas) ──
                                    _HorizontalResizeHandle(
                                      onDelta: (dy) {
                                        setState(() {
                                          _nextSlideFraction =
                                              ((nextH + dy) / h).clamp(
                                                _minNextSlideFraction,
                                                _maxNextSlideFraction,
                                              );
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildNotes(current.notes),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar (cronômetro + info + swap + exit) ─────────────────────────────

  Widget _buildTopBar(int total) {
    final stepInfo = _currentSlide.animSteps.isNotEmpty
        ? '   •   passo ${widget.animStep} / ${_currentSlide.animSteps.length}'
        : '';
    return Container(
      height: 52,
      color: const Color(0xFF13131F),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(
            _elapsed,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'Slide ${widget.slideIndex + 1} / $total$stepInfo',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const Spacer(),
          // Botão swap
          _TopBarButton(
            icon: Icons.swap_horiz,
            label: 'Trocar monitores',
            onTap: widget.onSwap,
          ),
          const SizedBox(width: 8),
          // Botão sair
          if (widget.onExit != null)
            _TopBarButton(
              icon: Icons.close,
              label: 'Encerrar modo apresentador',
              color: Colors.white38,
              onTap: widget.onExit!,
            ),
        ],
      ),
    );
  }

  // ── Slide atual ───────────────────────────────────────────────────────────

  Widget _buildCurrentSlide(
    PresentationData pres,
    SlideData slide,
    Set<int>? visibleIds,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF7C6AF7), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
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
                animStep: widget.animStep,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pontos de animação ────────────────────────────────────────────────────

  Widget _buildAnimDots(SlideData slide) {
    final total = slide.animSteps.length;
    if (total == 0) return const SizedBox(height: 14);
    return SizedBox(
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total + 1, (i) {
          final filled = i <= widget.animStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: filled ? 10 : 8,
            height: filled ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? const Color(0xFF7C6AF7) : Colors.white24,
            ),
          );
        }),
      ),
    );
  }

  // ── Próximo slide ─────────────────────────────────────────────────────────

  // _buildNextSlide: usa Expanded + FittedBox para ser height-driven.
  // Deve ser usado dentro de um SizedBox com altura definida (LayoutBuilder).
  Widget _buildNextSlide(PresentationData pres, SlideData? next) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRÓXIMO SLIDE',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: next != null
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: pres.canvasWidth,
                        height: pres.canvasHeight,
                        child: SlideRenderer(slide: next, presentation: pres),
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white10,
                  ),
                  child: const Center(
                    child: Text(
                      'Fim da apresentação',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Anotações ─────────────────────────────────────────────────────────────

  Widget _buildNotes(String? notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ANOTAÇÕES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF181828),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                notes ?? '(sem anotações)',
                style: TextStyle(
                  color: notes != null ? Colors.white : Colors.white30,
                  fontSize: 13.5,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Barra de navegação ────────────────────────────────────────────────────

  Widget _buildNavBar() {
    return Container(
      height: 60,
      color: const Color(0xFF13131F),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavButton(
            icon: Icons.chevron_left,
            label: 'Anterior',
            enabled: _canRetreat,
            onTap: _canRetreat ? widget.onRetreat : null,
          ),
          const SizedBox(width: 16),
          _NavButton(
            icon: Icons.chevron_right,
            label: 'Próximo',
            enabled: _canAdvance,
            onTap: _canAdvance ? widget.onAdvance : null,
            primary: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _TopBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final bool primary;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary
            ? const Color(0xFF7C6AF7)
            : const Color(0xFF2A2A3E),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white10,
        disabledForegroundColor: Colors.white24,
        minimumSize: const Size(140, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 22),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      onPressed: enabled ? onTap : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Handle de redimensionamento vertical (arraste horizontal)
// ─────────────────────────────────────────────────────────────────────────────

class _ResizeHandle extends StatefulWidget {
  /// Chamado com o delta de arrastar (positivo = mover para direita = diminuir painel).
  final void Function(double dx) onDelta;

  const _ResizeHandle({required this.onDelta});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle>
    with DeferredHoverState<_ResizeHandle> {
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
          width: 8,
          color: hovered
              ? const Color(0xFF7C6AF7).withAlpha(180)
              : Colors.white12,
          child: Center(
            child: Container(
              width: 2,
              height: 40,
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

// ─────────────────────────────────────────────────────────────────────────────
// Handle de redimensionamento horizontal (arraste vertical)
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalResizeHandle extends StatefulWidget {
  /// Chamado com o delta vertical (positivo = mover para baixo = ampliar próximo slide).
  final void Function(double dy) onDelta;

  const _HorizontalResizeHandle({required this.onDelta});

  @override
  State<_HorizontalResizeHandle> createState() =>
      _HorizontalResizeHandleState();
}

class _HorizontalResizeHandleState extends State<_HorizontalResizeHandle>
    with DeferredHoverState<_HorizontalResizeHandle> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => widget.onDelta(d.delta.dy),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 8,
          color: hovered
              ? const Color(0xFF7C6AF7).withAlpha(180)
              : Colors.white12,
          child: Center(
            child: Container(
              height: 2,
              width: 40,
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
