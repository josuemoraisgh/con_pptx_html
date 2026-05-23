import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pptx_models.dart';
import '../platform/browser_runtime.dart' as browser;

/// Renderiza um único slide como widget Flutter.
class SlideRenderer extends StatelessWidget {
  final SlideData slide;
  final PresentationData presentation;

  /// IDs de shapes visíveis. null = tudo visível. shapeId==0 = sempre visível.
  final Set<int>? visibleIds;

  /// Step de animação atual (usado apenas para rebuild trigger).
  final int animStep;

  const SlideRenderer({
    super.key,
    required this.slide,
    required this.presentation,
    this.visibleIds,
    this.animStep = 0,
  });

  @override
  Widget build(BuildContext context) {
    final w = presentation.canvasWidth;
    final h = presentation.canvasHeight;
    final renderables = _buildRenderables(presentation);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _buildBackground(w, h),
          ...renderables.map(
            (entry) => switch (entry) {
              _ElementRenderable() => _buildElement(
                entry.element,
                presentation,
              ),
              _OverlayRenderable() => _buildCommandOverlay(
                entry.spec,
                presentation,
              ),
            },
          ),
        ],
      ),
    );
  }

  List<_RenderableEntry> _buildRenderables(PresentationData pres) {
    final sorted = [...slide.elements]
      ..sort((a, b) => a.zOrder.compareTo(b.zOrder));
    final overlays = _buildCommandOverlays(sorted);
    final hiddenElementKeys = overlays
        .expand((overlay) => overlay.hiddenElementKeys)
        .toSet();
    final renderables = <_RenderableEntry>[];

    for (final element in sorted) {
      if (_shouldHideForCommandOverlay(element, hiddenElementKeys)) continue;
      renderables.add(_ElementRenderable(element.zOrder.toDouble(), element));
    }

    renderables.addAll(
      overlays.map(
        (overlay) => _OverlayRenderable(overlay.zOrder + 0.5, overlay),
      ),
    );
    renderables.sort((a, b) => a.zOrder.compareTo(b.zOrder));
    return renderables;
  }

  List<_CommandOverlaySpec> _buildCommandOverlays(List<SlideElement> sorted) {
    final byShapeId = <int, List<SlideElement>>{};
    for (final element in sorted) {
      if (element.shapeId == 0) continue;
      byShapeId.putIfAbsent(element.shapeId, () => []).add(element);
    }

    final globalPyodideRunCandidates = sorted
        .where((e) => _elementHasCommand(e, _AltCommand.pyodideRun))
        .toList();
    final globalPyodideAnswerCandidates = sorted
        .where((e) => _elementHasCommand(e, _AltCommand.pyodideAnswer))
        .toList();
    final consumedGlobalPyodideElementKeys = <String>{};

    final overlays = <_CommandOverlaySpec>[];
    for (final entry in byShapeId.entries) {
      final groupElements = entry.value;
      final commands = groupElements
          .expand(_extractCommandsFromElement)
          .toSet();

      final pyodideOverlay = _buildPyodideOverlayForGroup(
        entry.key,
        groupElements,
        commands,
        globalPyodideRunCandidates: globalPyodideRunCandidates,
        globalPyodideAnswerCandidates: globalPyodideAnswerCandidates,
        consumedGlobalPyodideElementKeys: consumedGlobalPyodideElementKeys,
      );
      if (pyodideOverlay != null) {
        overlays.add(pyodideOverlay);
        continue;
      }

      final arduinoOverlay = _buildArduinoOverlayForGroup(
        entry.key,
        groupElements,
        commands,
      );
      if (arduinoOverlay != null) overlays.add(arduinoOverlay);
    }
    return overlays;
  }

  _CommandOverlaySpec? _buildArduinoOverlayForGroup(
    int shapeId,
    List<SlideElement> groupElements,
    Set<_AltCommand> commands,
  ) {
    if (!commands.contains(_AltCommand.arduino)) return null;

    final textShapes =
        groupElements
            .whereType<ShapeElement>()
            .where((shape) => shape.paragraphs.isNotEmpty)
            .toList()
          ..sort((a, b) => a.zOrder.compareTo(b.zOrder));
    if (textShapes.isEmpty) return null;

    final sourceTexts = textShapes
        .map(_extractOriginalTextPreservingLines)
        .where((text) => text.isNotEmpty)
        .toList();
    if (sourceTexts.isEmpty) return null;

    return _CommandOverlaySpec(
      command: _AltCommand.arduino,
      shapeId: shapeId,
      zOrder: groupElements.last.zOrder.toDouble(),
      bounds: _computeOverlayBounds(groupElements),
      content: _concatenateCommandTexts(sourceTexts),
      semanticsLabel: groupElements
          .map(_elementLabelText)
          .whereType<String>()
          .where((text) => text.isNotEmpty)
          .join(' '),
      hiddenElementKeys: groupElements.map(_shapeKeyFor).toSet(),
    );
  }

  _CommandOverlaySpec? _buildPyodideOverlayForGroup(
    int shapeId,
    List<SlideElement> groupElements,
    Set<_AltCommand> commands, {
    required List<SlideElement> globalPyodideRunCandidates,
    required List<SlideElement> globalPyodideAnswerCandidates,
    required Set<String> consumedGlobalPyodideElementKeys,
  }) {
    final hasAnyPyodide =
        commands.contains(_AltCommand.pyodideCode) ||
        commands.contains(_AltCommand.pyodideRun) ||
        commands.contains(_AltCommand.pyodideAnswer);
    if (!hasAnyPyodide) return null;

    final codeElements = groupElements
        .where((e) => _elementHasCommand(e, _AltCommand.pyodideCode))
        .toList();
    final runElements = groupElements
        .where((e) => _elementHasCommand(e, _AltCommand.pyodideRun))
        .toList();
    final answerElements = groupElements
        .where((e) => _elementHasCommand(e, _AltCommand.pyodideAnswer))
        .toList();
    if (codeElements.isEmpty) return null;

    SlideElement? pickGlobalElement(List<SlideElement> candidates) {
      for (final candidate in candidates) {
        final key = _shapeKeyFor(candidate);
        if (consumedGlobalPyodideElementKeys.contains(key)) continue;
        final alreadyInGroup = groupElements.any((g) => _shapeKeyFor(g) == key);
        if (alreadyInGroup) continue;
        return candidate;
      }
      return null;
    }

    if (runElements.isEmpty) {
      final globalRun = pickGlobalElement(globalPyodideRunCandidates);
      if (globalRun != null) runElements.add(globalRun);
    }
    if (answerElements.isEmpty) {
      final globalAnswer = pickGlobalElement(globalPyodideAnswerCandidates);
      if (globalAnswer != null) answerElements.add(globalAnswer);
    }

    final workspaceElementsByKey = <String, SlideElement>{
      for (final e in [...codeElements, ...runElements, ...answerElements])
        _shapeKeyFor(e): e,
    };
    final workspaceElements = workspaceElementsByKey.values.toList();

    for (final e in [...runElements, ...answerElements]) {
      final key = _shapeKeyFor(e);
      final alreadyInGroup = groupElements.any((g) => _shapeKeyFor(g) == key);
      if (!alreadyInGroup) {
        consumedGlobalPyodideElementKeys.add(key);
      }
    }

    final codeTextShapes =
        codeElements
            .whereType<ShapeElement>()
            .where((shape) => shape.paragraphs.isNotEmpty)
            .toList()
          ..sort((a, b) => a.zOrder.compareTo(b.zOrder));
    final answerTextShapes =
        answerElements
            .whereType<ShapeElement>()
            .where((shape) => shape.paragraphs.isNotEmpty)
            .toList()
          ..sort((a, b) => a.zOrder.compareTo(b.zOrder));
    final runTextShapes =
        runElements
            .whereType<ShapeElement>()
            .where((shape) => shape.paragraphs.isNotEmpty)
            .toList()
          ..sort((a, b) => a.zOrder.compareTo(b.zOrder));

    final initialCode = _concatenateCommandTexts(
      codeTextShapes
          .map(_extractOriginalTextPreservingLines)
          .where((text) => text.isNotEmpty)
          .toList(),
    );
    if (initialCode.isEmpty) return null;

    final initialOutput = answerTextShapes.isEmpty
        ? ''
        : _concatenateCommandTexts(
            answerTextShapes
                .map(_extractOriginalTextPreservingLines)
                .where((text) => text.isNotEmpty)
                .toList(),
          );
    final runLabel = runTextShapes.isEmpty
        ? 'Executar'
        : _concatenateCommandTexts(
            runTextShapes
                .map(_extractOriginalTextPreservingLines)
                .where((text) => text.isNotEmpty)
                .toList(),
          );

    final groupBounds = _computeOverlayBounds(workspaceElements);
    final codeBounds = _computeOverlayBounds(codeElements);
    final answerBounds = answerElements.isEmpty
        ? null
        : _computeOverlayBounds(answerElements);
    final runBounds = runElements.isEmpty
        ? _defaultRunBoundsForPyodide(
            groupBounds: groupBounds,
            codeBounds: codeBounds,
            answerBounds: answerBounds,
          )
        : _computeOverlayBounds(runElements);

    return _CommandOverlaySpec(
      command: _AltCommand.pyodideWorkspace,
      shapeId: shapeId,
      zOrder: workspaceElements
          .map((e) => e.zOrder)
          .reduce(math.max)
          .toDouble(),
      bounds: groupBounds,
      semanticsLabel: workspaceElements
          .map(_elementLabelText)
          .whereType<String>()
          .where((text) => text.isNotEmpty)
          .join(' '),
      hiddenElementKeys: {
        ...groupElements.map(_shapeKeyFor),
        ...workspaceElements.map(_shapeKeyFor),
      },
      pyodideLayout: _PyodideLayoutSpec(
        groupBounds: groupBounds,
        codeBounds: codeBounds,
        runBounds: runBounds,
        answerBounds: answerBounds,
        initialCode: initialCode,
        initialOutput: initialOutput,
        runLabel: runLabel.trim().isEmpty ? 'Executar' : runLabel.trim(),
      ),
    );
  }

  _OverlayBounds _defaultRunBoundsForPyodide({
    required _OverlayBounds groupBounds,
    required _OverlayBounds codeBounds,
    required _OverlayBounds? answerBounds,
  }) {
    const double gap = 25000.0;
    final buttonHeight = (codeBounds.cyEmu * 0.10)
        .clamp(90000.0, 220000.0)
        .toDouble();

    final groupBottom = groupBounds.yEmu + groupBounds.cyEmu;
    final belowTop = codeBounds.yEmu + codeBounds.cyEmu + gap;

    // Prefere abaixo do código; se não cabe no grupo, flutua na borda
    // inferior interna do code box (overlay).
    final yEmu = (belowTop + buttonHeight <= groupBottom + gap)
        ? belowTop
        : codeBounds.yEmu + codeBounds.cyEmu - buttonHeight - gap;

    return _OverlayBounds(
      xEmu: codeBounds.xEmu,
      yEmu: yEmu,
      cxEmu: codeBounds.cxEmu,
      cyEmu: buttonHeight,
    );
  }

  bool _elementHasCommand(SlideElement element, _AltCommand command) {
    return _extractCommandsFromElement(element).contains(command);
  }

  bool _shouldHideForCommandOverlay(
    SlideElement element,
    Set<String> hiddenElementKeys,
  ) {
    return hiddenElementKeys.contains(_shapeKeyFor(element));
  }

  Set<_AltCommand> _extractCommandsFromElement(SlideElement element) {
    final sourceText = [
      element.commandText,
      switch (element) {
        ShapeElement() => element.altText,
        ImageElement() => element.altText,
        TableElement() => null,
      },
    ].whereType<String>().join(' ');
    return _extractCommands(sourceText);
  }

  Set<_AltCommand> _extractCommands(String? altText) {
    if (altText == null || altText.isEmpty) return const {};
    final commands = <_AltCommand>{};
    for (final match in RegExp(r'\{([^{}]+)\}').allMatches(altText)) {
      switch (match.group(1)?.trim().toLowerCase()) {
        case 'arduino':
          commands.add(_AltCommand.arduino);
        case 'pyodide_code':
          commands.add(_AltCommand.pyodideCode);
        case 'pyodide_run':
          commands.add(_AltCommand.pyodideRun);
        case 'pyodide_awnser':
          commands.add(_AltCommand.pyodideAnswer);
        case 'pyodide_answer':
          commands.add(_AltCommand.pyodideAnswer);
      }
    }
    return commands;
  }

  _OverlayBounds _computeOverlayBounds(List<SlideElement> elements) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    for (final element in elements) {
      left = math.min(left, element.xEmu);
      top = math.min(top, element.yEmu);
      right = math.max(right, element.xEmu + element.cxEmu);
      bottom = math.max(bottom, element.yEmu + element.cyEmu);
    }

    return _OverlayBounds(
      xEmu: left.isFinite ? left : 0,
      yEmu: top.isFinite ? top : 0,
      cxEmu: left.isFinite && right.isFinite ? right - left : 0,
      cyEmu: top.isFinite && bottom.isFinite ? bottom - top : 0,
    );
  }

  String _extractOriginalTextPreservingLines(ShapeElement shape) {
    final buffer = StringBuffer();
    for (var i = 0; i < shape.paragraphs.length; i++) {
      if (i > 0) buffer.write('\n');
      for (final run in shape.paragraphs[i].runs) {
        buffer.write(run.text);
      }
    }
    return buffer.toString();
  }

  String _concatenateCommandTexts(List<String> parts) {
    final buffer = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 &&
          buffer.isNotEmpty &&
          !buffer.toString().endsWith('\n') &&
          !parts[i].startsWith('\n')) {
        buffer.write('\n');
      }
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _shapeKeyFor(SlideElement element) =>
      '${element.shapeId}:${element.zOrder}:${element.xEmu}:${element.yEmu}:${element.cxEmu}:${element.cyEmu}';

  String? _elementLabelText(SlideElement element) {
    return switch (element) {
      ShapeElement() => element.altText ?? element.commandText,
      ImageElement() => element.altText ?? element.commandText,
      TableElement() => element.commandText,
    };
  }

  // ── Fundo ────────────────────────────────────────────────────────────────

  Widget _buildBackground(double w, double h) {
    final bg = slide.background;
    if (bg == null) {
      return Positioned.fill(child: Container(color: Colors.white));
    }
    if (bg.imageBytes != null) {
      return Positioned.fill(
        child: Image.memory(bg.imageBytes!, fit: BoxFit.cover),
      );
    }
    if (bg.fill != null) {
      return Positioned.fill(
        child: Container(decoration: _fillDecoration(bg.fill!)),
      );
    }
    return Positioned.fill(child: Container(color: Colors.white));
  }

  // ── Despacho de elementos ─────────────────────────────────────────────────

  Widget _buildElement(SlideElement el, PresentationData pres) {
    final left = pres.emuToPx(el.xEmu);
    final top = pres.emuToPx(el.yEmu);
    final width = pres.emuToPx(el.cxEmu);
    final height = pres.emuToPx(el.cyEmu);

    if (width <= 0 || height <= 0) return const SizedBox.shrink();

    Widget child;
    switch (el) {
      case ShapeElement():
        child = _buildShape(el, width, height, pres);
      case ImageElement():
        child = _buildImage(el);
      case TableElement():
        child = _buildTable(el, width, height, pres);
    }

    if (el.rotationDeg != null && el.rotationDeg != 0) {
      child = Transform.rotate(
        angle: el.rotationDeg! * 3.14159265358979 / 180.0,
        child: child,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: AnimatedOpacity(
        opacity: _isVisible(el) ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeIn,
        child: child,
      ),
    );
  }

  bool _isVisible(SlideElement el) {
    final ids = visibleIds;
    if (ids == null) return true;
    if (el.shapeId == 0) {
      return true; // elementos de master/layout sempre visíveis
    }
    return ids.contains(el.shapeId);
  }

  // ── Shape ─────────────────────────────────────────────────────────────────

  Widget _buildShape(
    ShapeElement el,
    double width,
    double height,
    PresentationData pres,
  ) {
    final fill = el.fill;
    final outline = el.outline;
    final geometry = el.presetGeometry ?? 'rect';

    // Detecta modo de borda pelo alt text
    final at = (el.altText ?? '').toLowerCase();
    final _BorderMode borderMode;
    if (at.contains('border: inferiores') || at.contains('border: inferior')) {
      borderMode = _BorderMode.bottom;
    } else if (at.contains('border: superiores') ||
        at.contains('border: superior')) {
      borderMode = _BorderMode.top;
    } else if (at.contains('border: left') || at.contains('border: esquerda')) {
      borderMode = _BorderMode.left;
    } else if (at.contains('border: right') || at.contains('border: direita')) {
      borderMode = _BorderMode.right;
    } else {
      borderMode = _BorderMode.all;
    }

    final insetL = pres.emuToPx(el.bodyProps.insetLeftEmu);
    final insetR = pres.emuToPx(el.bodyProps.insetRightEmu);
    final insetT = pres.emuToPx(el.bodyProps.insetTopEmu);
    final insetB = pres.emuToPx(el.bodyProps.insetBottomEmu);

    Widget textWidget = const SizedBox.shrink();
    if (el.paragraphs.isNotEmpty) {
      final availW = (width - insetL - insetR).clamp(0.0, double.infinity);
      final availH = (height - insetT - insetB).clamp(0.0, double.infinity);
      Widget body = _buildTextBody(
        el.paragraphs,
        el.bodyProps,
        pres,
        availW,
        defaultTextColor: _resolveDefaultTextColorForShape(el),
      );
      // Encolhe automaticamente o bloco de texto para caber na área útil
      // da caixa e evitar overflow visual em layouts densos.
      body = SizedBox(
        width: availW,
        height: availH,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: _alignmentForVert(el.bodyProps.vertAlign),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: availW),
            child: body,
          ),
        ),
      );
      textWidget = Padding(
        padding: EdgeInsets.fromLTRB(insetL, insetT, insetR, insetB),
        child: body,
      );
    }

    final hasPaint = (fill != null && fill is! NoFill) || outline != null;

    Widget shapeBody;
    if (hasPaint) {
      shapeBody = CustomPaint(
        painter: _ShapePainter(
          geometry: geometry,
          fill: fill,
          outline: outline,
          adjValue: el.adjValue,
          borderMode: borderMode,
        ),
        child: textWidget,
      );
    } else {
      shapeBody = textWidget;
    }

    final label = el.altText;
    if (label != null && label.trim().isNotEmpty) {
      return Semantics(label: label.trim(), child: shapeBody);
    }
    return shapeBody;
  }

  Color? _resolveDefaultTextColorForShape(ShapeElement el) {
    final placeholder = el.placeholderType?.toLowerCase();
    final slideDark = _isDarkSlideBackground();

    if (placeholder == 'title' ||
        placeholder == 'ctrtitle' ||
        placeholder == 'subtitle') {
      return slideDark ? const Color(0xFFF0F4F8) : const Color(0xFF111827);
    }

    if (placeholder == 'body') {
      return slideDark ? const Color(0xFFCBD5E0) : const Color(0xFF1F2937);
    }

    final fill = el.fill;
    if (fill is SolidFill) {
      return _isDarkColor(fill.color)
          ? const Color(0xFFF0F4F8)
          : const Color(0xFF111827);
    }

    return slideDark ? const Color(0xFFE2E8F0) : null;
  }

  bool _isDarkSlideBackground() {
    final bg = slide.background;
    final fill = bg?.fill;
    if (fill is SolidFill) {
      return _isDarkColor(fill.color);
    }
    if (fill is GradientFill && fill.stops.isNotEmpty) {
      final avgLuminance =
          fill.stops.map((s) => s.color.computeLuminance()).reduce((a, b) => a + b) /
          fill.stops.length;
      return avgLuminance < 0.45;
    }
    return false;
  }

  bool _isDarkColor(Color color) => color.computeLuminance() < 0.45;

  Widget _buildCommandOverlay(_CommandOverlaySpec spec, PresentationData pres) {
    final left = pres.emuToPx(spec.bounds.xEmu);
    final top = pres.emuToPx(spec.bounds.yEmu);
    final width = pres.emuToPx(spec.bounds.cxEmu);
    final height = pres.emuToPx(spec.bounds.cyEmu);

    if (width <= 0 || height <= 0) return const SizedBox.shrink();

    final content = _buildCommandContent(spec);
    final child = spec.command == _AltCommand.pyodideWorkspace
        ? content
        : spec.semanticsLabel.isEmpty
        ? content
        : Semantics(label: spec.semanticsLabel, readOnly: true, child: content);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: AnimatedOpacity(
        opacity: visibleIds == null || visibleIds!.contains(spec.shapeId)
            ? 1.0
            : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeIn,
        child: child,
      ),
    );
  }

  Widget _buildCommandContent(_CommandOverlaySpec spec) {
    if (spec.command == _AltCommand.pyodideWorkspace) {
      final layout = spec.pyodideLayout;
      if (layout == null) return const SizedBox.shrink();
      return _PyodideCommandOverlay(layout: layout);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Text.rich(
              TextSpan(
                children: switch (spec.command) {
                  _AltCommand.arduino => _highlightArduinoCode(spec.content),
                  _AltCommand.pyodideWorkspace => const [TextSpan(text: '')],
                  _AltCommand.pyodideCode => const [TextSpan(text: '')],
                  _AltCommand.pyodideRun => const [TextSpan(text: '')],
                  _AltCommand.pyodideAnswer => const [TextSpan(text: '')],
                },
              ),
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Consolas',
                fontFamilyFallback: ['Courier New', 'monospace'],
                height: 1.35,
                color: Color(0xFFD4D4D4),
              ),
              textAlign: TextAlign.start,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _highlightArduinoCode(String source) {
    if (source.isEmpty) return const [TextSpan(text: '')];

    final spans = <InlineSpan>[];
    final tokenPattern = RegExp(
      r'''(//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b\d+(?:\.\d+)?\b|\b[A-Za-z_][A-Za-z0-9_]*\b|#[A-Za-z_][A-Za-z0-9_]*|\r\n|\r|\n|.)''',
      multiLine: true,
    );

    for (final match in tokenPattern.allMatches(source)) {
      final token = match.group(0)!;
      spans.add(TextSpan(text: token, style: _arduinoTokenStyle(token)));
    }
    return spans;
  }

  TextStyle _arduinoTokenStyle(String token) {
    const base = TextStyle(color: Color(0xFFD4D4D4));

    if (token.startsWith('//') || token.startsWith('/*')) {
      return base.copyWith(
        color: const Color(0xFF6A9955),
        fontStyle: FontStyle.italic,
      );
    }
    if (token.startsWith('"') || token.startsWith('\'')) {
      return base.copyWith(color: const Color(0xFFCE9178));
    }
    if (token.startsWith('#')) {
      return base.copyWith(
        color: const Color(0xFFC586C0),
        fontWeight: FontWeight.w600,
      );
    }
    if (RegExp(r'^\d').hasMatch(token)) {
      return base.copyWith(color: const Color(0xFFB5CEA8));
    }
    if (_arduinoKeywords.contains(token)) {
      return base.copyWith(
        color: const Color(0xFF569CD6),
        fontWeight: FontWeight.w600,
      );
    }
    if (_arduinoTypes.contains(token)) {
      return base.copyWith(
        color: const Color(0xFF4EC9B0),
        fontWeight: FontWeight.w600,
      );
    }
    if (_arduinoConstants.contains(token)) {
      return base.copyWith(
        color: const Color(0xFFDCDCAA),
        fontWeight: FontWeight.w600,
      );
    }
    if (_looksLikeFunctionName(token)) {
      return base.copyWith(color: const Color(0xFFDCDCAA));
    }

    return base;
  }

  bool _looksLikeFunctionName(String token) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(token) &&
        !_arduinoKeywords.contains(token) &&
        !_arduinoTypes.contains(token) &&
        !_arduinoConstants.contains(token) &&
        token[0] == token[0].toLowerCase();
  }

  // ── Corpo de texto ────────────────────────────────────────────────────────

  Widget _buildTextBody(
    List<TextParagraph> paragraphs,
    TextBodyProperties bodyProps,
    PresentationData pres,
    double availableWidth,
    {Color? defaultTextColor}
  ) {
    final fontScale = bodyProps.fontScale;
    final lineSpaceReduction = bodyProps.lineSpaceReduction;
    final autoNumberByLevel = List<int>.filled(9, 0);
    final children = <Widget>[];

    for (final paragraph in paragraphs) {
      String? autoNumber;
      if (paragraph.props.bullet?.isAutoNum ?? false) {
        final level = paragraph.props.level
            .clamp(0, autoNumberByLevel.length - 1)
            .toInt();
        autoNumberByLevel[level]++;
        for (var i = level + 1; i < autoNumberByLevel.length; i++) {
          autoNumberByLevel[i] = 0;
        }
        autoNumber = '${autoNumberByLevel[level]}.';
      }

      children.add(
        _buildParagraph(
          paragraph,
          pres,
          fontScale,
          lineSpaceReduction,
          bodyProps.wordWrap,
          autoNumber,
          defaultTextColor,
        ),
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    final alignment = switch (bodyProps.vertAlign) {
      VerticalAlignment.top => Alignment.topLeft,
      VerticalAlignment.middle => Alignment.centerLeft,
      VerticalAlignment.bottom => Alignment.bottomLeft,
    };

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: availableWidth),
        child: column,
      ),
    );
  }

  Widget _buildParagraph(
    TextParagraph para,
    PresentationData pres, [
    double fontScale = 1.0,
    double lineSpaceReduction = 0.0,
    bool wordWrap = true,
    String? autoNumber,
    Color? defaultTextColor,
  ]) {
    final props = para.props;
    final lineSpacingMultiplier = ((props.lineSpacingPct ?? 100.0) / 100.0)
        .clamp(0.5, 3.0);

    if (para.runs.isEmpty) {
      final h = props.spaceBeforePt != null ? props.spaceBeforePt! * 0.5 : 4.0;
      return SizedBox(height: h.clamp(2.0, 20.0));
    }

    final spans = <InlineSpan>[];
    for (final run in para.runs) {
      if (run.text == '\n') {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      spans.add(
        TextSpan(
          text: run.text,
          style: _runStyle(
            run.props,
            pres,
            fontScale: fontScale,
            lineSpaceReduction: lineSpaceReduction,
            lineSpacingMultiplier: lineSpacingMultiplier,
            defaultColor: defaultTextColor,
          ),
        ),
      );
    }

    Widget textWidget = RichText(
      text: TextSpan(children: spans),
      textAlign: props.alignment,
      softWrap: wordWrap,
      overflow: TextOverflow.visible,
    );

    // Recuo para listas / bullets
    if (props.bullet != null || props.marLeftEmu != null) {
      final indent = props.marLeftEmu != null
          ? pres.emuToPx(props.marLeftEmu!)
          : (props.level + 1) * 16.0;

      final bulletLabel = autoNumber ?? props.bullet?.char;
      if (bulletLabel != null) {
        final bulletStyle = _bulletRunStyle(
          para,
          pres,
          fontScale,
          lineSpaceReduction,
          lineSpacingMultiplier,
          defaultColor: defaultTextColor,
        );
        textWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: indent.clamp(8.0, 48.0),
              child: Text(bulletLabel, style: bulletStyle),
            ),
            Expanded(child: textWidget),
          ],
        );
      } else {
        textWidget = Padding(
          padding: EdgeInsets.only(left: indent.clamp(0.0, 120.0)),
          child: textWidget,
        );
      }
    }

    final topPad = (props.spaceBeforePt ?? 0) * 0.5;
    final botPad = (props.spaceAfterPt ?? 0) * 0.5;

    if (topPad > 0 || botPad > 0) {
      textWidget = Padding(
        padding: EdgeInsets.only(top: topPad, bottom: botPad),
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextStyle _runStyle(
    RunProperties rp,
    PresentationData pres,
    {
    double fontScale = 1.0,
    double lineSpaceReduction = 0.0,
    double lineSpacingMultiplier = 1.0,
    Color? defaultColor,
  }) {
    final fontSize = ((rp.fontSizePt ?? 18.0) * fontScale).clamp(6.0, 200.0);
    final family = _mapToSafeFont(_resolveFont(rp.fontFamily, pres));
    final lineHeight =
        (1.2 * lineSpacingMultiplier * (1.0 - lineSpaceReduction)).clamp(
          0.8,
          3.0,
        );

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: rp.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: rp.italic ? FontStyle.italic : FontStyle.normal,
      decoration: _textDecoration(rp),
      decorationColor: rp.color,
      color: rp.color ?? defaultColor ?? Colors.black,
      height: lineHeight,
      fontFamilyFallback: _fontFallbackFor(family),
    );

    try {
      return GoogleFonts.getFont(family, textStyle: baseStyle);
    } catch (_) {
      final f = family.toLowerCase();
      final preferredFamily =
          f.contains('consolas') ||
              f.contains('courier') ||
              f.contains('arial') ||
              f.contains('times new roman')
          ? family
          : _systemFallbackFamily(family);
      return baseStyle.copyWith(fontFamily: preferredFamily);
    }
  }

  String _systemFallbackFamily(String family) {
    final f = family.toLowerCase();
    if (f.contains('mono') || f.contains('courier') || f.contains('consolas')) {
      return 'Courier New';
    }
    if (f.contains('serif') || f.contains('lora') || f.contains('cambria')) {
      return 'Times New Roman';
    }
    return 'Arial';
  }

  List<String> _fontFallbackFor(String family) {
    final f = family.toLowerCase();
    if (f.contains('mono') || f.contains('courier') || f.contains('consolas')) {
      return const ['Consolas', 'Courier New', 'monospace'];
    }
    if (f.contains('serif') || f.contains('lora') || f.contains('cambria')) {
      return const ['Cambria', 'Times New Roman', 'Georgia', 'serif'];
    }
    return const ['Inter', 'Segoe UI', 'Arial', 'Helvetica', 'sans-serif'];
  }

  /// Mapeia fontes comuns do PPTX para equivalentes disponíveis no Google
  /// Fonts. Evita o "flash" causado por tentativas de carregar Calibri/Cambria
  /// que não existem na CDN — assim o nome resolvido sempre é baixável e o
  /// pre-load no PresentationViewer garante que tudo já está pronto.
  static const Map<String, String> _safeFontMap = {
    'calibri': 'Inter',
    'calibri light': 'Inter',
    'cambria': 'Lora',
    'cambria math': 'Lora',
    'arial': 'Inter',
    'arial black': 'Inter',
    'helvetica': 'Inter',
    'times new roman': 'Lora',
    'times': 'Lora',
    'georgia': 'Lora',
    'verdana': 'Inter',
    'tahoma': 'Inter',
    'segoe ui': 'Inter',
    'comic sans ms': 'Inter',
    'trebuchet ms': 'Inter',
  };

  static String mapToSafeFont(String name) {
    if (name.isEmpty) return 'Inter';
    return _safeFontMap[name.toLowerCase()] ?? name;
  }

  String _mapToSafeFont(String name) => mapToSafeFont(name);

  Alignment _alignmentForVert(VerticalAlignment v) {
    switch (v) {
      case VerticalAlignment.top:
        return Alignment.topLeft;
      case VerticalAlignment.middle:
        return Alignment.centerLeft;
      case VerticalAlignment.bottom:
        return Alignment.bottomLeft;
    }
  }

  TextStyle _bulletRunStyle(
    TextParagraph para,
    PresentationData pres,
    double fontScale,
    double lineSpaceReduction,
    double lineSpacingMultiplier,
    {Color? defaultColor}
  ) {
    final firstRun = para.runs.firstOrNull?.props ?? const RunProperties();
    final bulletColor = para.props.bullet?.color;
    final style = _runStyle(
      firstRun,
      pres,
      fontScale: fontScale,
      lineSpaceReduction: lineSpaceReduction,
      lineSpacingMultiplier: lineSpacingMultiplier,
      defaultColor: defaultColor,
    );
    return bulletColor != null ? style.copyWith(color: bulletColor) : style;
  }

  String _resolveFont(String? requested, PresentationData pres) {
    if (requested == null || requested.isEmpty) {
      return pres.theme.minorFontLatin;
    }
    if (requested.startsWith('+mj')) return pres.theme.majorFontLatin;
    if (requested.startsWith('+mn')) return pres.theme.minorFontLatin;
    return requested;
  }

  TextDecoration _textDecoration(RunProperties rp) {
    if (rp.underline && rp.strikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }
    if (rp.underline) return TextDecoration.underline;
    if (rp.strikethrough) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  // ── Imagem ────────────────────────────────────────────────────────────────

  Widget _buildImage(ImageElement el) {
    final isSvg = (el.mimeType ?? '').toLowerCase().contains('svg');
    final image = el.imageBytes == null
        ? Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          )
        : isSvg
        ? SvgPicture.memory(
            el.imageBytes!,
            fit: BoxFit.fill,
            placeholderBuilder: (context) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey),
              ),
            ),
          )
        : Image.memory(
            el.imageBytes!,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stack) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.broken_image)),
            ),
          );

    final label = el.altText;
    if (label != null && label.trim().isNotEmpty) {
      return Semantics(label: label.trim(), image: true, child: image);
    }

    return image;
  }

  // ── Tabela ────────────────────────────────────────────────────────────────

  Widget _buildTable(
    TableElement el,
    double width,
    double height,
    PresentationData pres,
  ) {
    if (el.rows.isEmpty) return const SizedBox.shrink();

    final maxCols = el.rows.fold<int>(0, (max, row) {
      final cols = row.cells.fold<int>(
        0,
        (sum, cell) => sum + cell.gridSpan.clamp(1, 999).toInt(),
      );
      return math.max(max, cols);
    });
    if (maxCols == 0) return const SizedBox.shrink();

    var colWidths = el.colWidthsEmu.map(pres.emuToPx).toList();
    if (colWidths.length < maxCols) {
      final fallbackWidth = width / maxCols;
      colWidths = [
        ...colWidths,
        ...List.filled(maxCols - colWidths.length, fallbackWidth),
      ];
    }

    final totalColWidth = colWidths.fold(0.0, (sum, w) => sum + w);
    if (totalColWidth > 0 && width > 0) {
      final scale = width / totalColWidth;
      colWidths = colWidths.map((w) => w * scale).toList();
    } else {
      colWidths = List.filled(maxCols, width / maxCols);
    }

    var rowHeights = el.rows.map((row) => pres.emuToPx(row.heightEmu)).toList();
    final totalRowHeight = rowHeights.fold(0.0, (sum, h) => sum + h);
    if (totalRowHeight > 0 && height > 0) {
      final scale = height / totalRowHeight;
      rowHeights = rowHeights.map((h) => h * scale).toList();
    } else {
      rowHeights = List.filled(el.rows.length, height / el.rows.length);
    }

    final rowWidgets = <Widget>[];
    for (var rowIndex = 0; rowIndex < el.rows.length; rowIndex++) {
      final row = el.rows[rowIndex];
      final rowH = rowHeights[rowIndex];
      var colIdx = 0;
      final cells = <Widget>[];
      for (final cell in row.cells) {
        final remainingCols = colWidths.length - colIdx;
        if (remainingCols <= 0) break;
        final span = cell.gridSpan.clamp(1, remainingCols).toInt();
        final cellW = colWidths
            .skip(colIdx)
            .take(span)
            .fold(0.0, (s, w) => s + w);
        colIdx += span;
        cells.add(
          Container(
            width: cellW,
            height: rowH,
            decoration: BoxDecoration(
              color: cell.fill is SolidFill
                  ? (cell.fill as SolidFill).color
                  : Colors.transparent,
              border: Border.all(color: Colors.grey.shade400, width: 0.5),
            ),
            padding: const EdgeInsets.all(4),
            child: _buildTextBody(
              cell.paragraphs,
              TextBodyProperties.defaults,
              pres,
              (cellW - 8).clamp(0.0, double.infinity),
            ),
          ),
        );
      }
      rowWidgets.add(
        SizedBox(
          height: rowH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cells,
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowWidgets,
        ),
      ),
    );
  }

  // ── Helpers de decoração ──────────────────────────────────────────────────

  BoxDecoration _fillDecoration(ShapeFill fill) {
    switch (fill) {
      case SolidFill():
        return BoxDecoration(color: fill.color);
      case GradientFill():
        return BoxDecoration(
          gradient: LinearGradient(
            colors: fill.stops.map((s) => s.color).toList(),
            stops: fill.stops.map((s) => s.position).toList(),
            transform: GradientRotation(
              fill.angleDeg * 3.14159265358979 / 180.0,
            ),
          ),
        );
      case NoFill():
        return const BoxDecoration(color: Colors.transparent);
      default:
        return const BoxDecoration(color: Colors.transparent);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controle de bordas seletivas via alt text
// ─────────────────────────────────────────────────────────────────────────────

enum _BorderMode { all, top, bottom, left, right }

enum _AltCommand {
  arduino,
  pyodideWorkspace,
  pyodideCode,
  pyodideRun,
  pyodideAnswer,
}

sealed class _RenderableEntry {
  final double zOrder;

  const _RenderableEntry(this.zOrder);
}

class _ElementRenderable extends _RenderableEntry {
  final SlideElement element;

  const _ElementRenderable(super.zOrder, this.element);
}

class _OverlayRenderable extends _RenderableEntry {
  final _CommandOverlaySpec spec;

  const _OverlayRenderable(super.zOrder, this.spec);
}

class _CommandOverlaySpec {
  final _AltCommand command;
  final int shapeId;
  final double zOrder;
  final _OverlayBounds bounds;
  final String content;
  final String semanticsLabel;
  final Set<String> hiddenElementKeys;
  final _PyodideLayoutSpec? pyodideLayout;

  const _CommandOverlaySpec({
    required this.command,
    required this.shapeId,
    required this.zOrder,
    required this.bounds,
    this.content = '',
    required this.semanticsLabel,
    required this.hiddenElementKeys,
    this.pyodideLayout,
  });
}

class _PyodideLayoutSpec {
  final _OverlayBounds groupBounds;
  final _OverlayBounds codeBounds;
  final _OverlayBounds? runBounds;
  final _OverlayBounds? answerBounds;
  final String initialCode;
  final String initialOutput;
  final String runLabel;

  const _PyodideLayoutSpec({
    required this.groupBounds,
    required this.codeBounds,
    required this.runBounds,
    required this.answerBounds,
    required this.initialCode,
    required this.initialOutput,
    required this.runLabel,
  });
}

class _OverlayBounds {
  final double xEmu;
  final double yEmu;
  final double cxEmu;
  final double cyEmu;

  const _OverlayBounds({
    required this.xEmu,
    required this.yEmu,
    required this.cxEmu,
    required this.cyEmu,
  });
}

class _PyodideCommandOverlay extends StatefulWidget {
  final _PyodideLayoutSpec layout;

  const _PyodideCommandOverlay({required this.layout});

  @override
  State<_PyodideCommandOverlay> createState() => _PyodideCommandOverlayState();
}

class _PyodideCommandOverlayState extends State<_PyodideCommandOverlay> {
  late final _PythonHighlightEditingController _codeController;
  late final ScrollController _codeScrollController;
  late final ScrollController _outputScrollController;
  late String _output;
  bool _loadingRuntime = true;
  bool _runtimeReady = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _codeController = _PythonHighlightEditingController(
      widget.layout.initialCode,
    );
    _codeScrollController = ScrollController();
    _outputScrollController = ScrollController();
    _output = widget.layout.initialOutput;
    _prepareRuntime();
  }

  Future<void> _prepareRuntime() async {
    final ready = await browser.ensurePyodideReady();
    if (!mounted) return;
    setState(() {
      _runtimeReady = ready;
      _loadingRuntime = false;
      if (!ready && _output.trim().isEmpty) {
        _output = 'Pyodide indisponivel neste ambiente.';
      }
    });
  }

  Future<void> _runCode() async {
    if (_running) return;
    setState(() => _running = true);
    final result = await browser.runPythonCode(_codeController.text);
    if (!mounted) return;
    setState(() {
      _running = false;
      _output = result;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeScrollController.dispose();
    _outputScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final group = layout.groupBounds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final codeRect = _relativeRect(layout.codeBounds, group, size);
        final answerRect = layout.answerBounds == null
            ? null
            : _relativeRect(layout.answerBounds!, group, size);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fromRect(rect: codeRect, child: _buildCodeEditor()),
            if (answerRect != null)
              Positioned.fromRect(rect: answerRect, child: _buildOutputPanel()),
          ],
        );
      },
    );
  }

  Rect _relativeRect(_OverlayBounds target, _OverlayBounds root, Size size) {
    final rootW = root.cxEmu <= 0 ? 1.0 : root.cxEmu;
    final rootH = root.cyEmu <= 0 ? 1.0 : root.cyEmu;

    final left = ((target.xEmu - root.xEmu) / rootW * size.width).clamp(
      0.0,
      size.width,
    );
    final top = ((target.yEmu - root.yEmu) / rootH * size.height).clamp(
      0.0,
      size.height,
    );
    final width = (target.cxEmu / rootW * size.width).clamp(0.0, size.width);
    final height = (target.cyEmu / rootH * size.height).clamp(0.0, size.height);
    return Rect.fromLTWH(left, top, width, height);
  }

  Widget _buildCodeEditor() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102834), Color(0xFF1B2C33)],
          ),
          border: Border.all(color: const Color(0xFF0F4C66), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF214A5D), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, color: Color(0xFF00C8FF), size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'CODIGO PYTHON',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Color(0xFF00C8FF),
                      ),
                    ),
                  ),
                  _headerIconButton(
                    icon: Icons.content_copy,
                    tooltip: 'Copiar codigo',
                    onTap: _copyCode,
                  ),
                  const SizedBox(width: 4),
                  _headerIconButton(
                    icon: Icons.fullscreen,
                    tooltip: 'Tela cheia',
                    onTap: _enterFullscreen,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF15181E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _codeScrollController,
                    child: TextField(
                      controller: _codeController,
                      scrollController: _codeScrollController,
                      readOnly: false,
                      enableInteractiveSelection: true,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      cursorColor: const Color(0xFF00E5FF),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Consolas',
                        fontFamilyFallback: ['Courier New', 'monospace'],
                        height: 1.35,
                        color: Color(0xFFD4D4D4),
                      ),
                      decoration: const InputDecoration.collapsed(hintText: ''),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _buildRunButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, color: const Color(0xFF8EA4AD), size: 18),
        ),
      ),
    );
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _codeController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Codigo copiado.')));
  }

  void _enterFullscreen() {
    browser.requestFullscreen();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Modo tela cheia ativado.')));
  }

  Widget _buildRunButton() {
    final enabled = !(_loadingRuntime || !_runtimeReady || _running);
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: enabled ? const Color(0xFF1F5533) : const Color(0xFF32453A),
          child: InkWell(
            onTap: enabled ? _runCode : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow,
                  color: enabled
                      ? const Color(0xFF25E26C)
                      : const Color(0xFF89A893),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  _running ? 'Executando...' : widget.layout.runLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: enabled
                        ? const Color(0xFF25E26C)
                        : const Color(0xFF89A893),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputPanel() {
    final title = _loadingRuntime
        ? 'Inicializando Pyodide...'
        : (_runtimeReady ? 'Saida' : 'Saida (indisponivel)');

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF62EFA0),
                ),
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _outputScrollController,
                child: SingleChildScrollView(
                  controller: _outputScrollController,
                  child: SelectableText(
                    _output,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Consolas',
                      fontFamilyFallback: ['Courier New', 'monospace'],
                      height: 1.35,
                      color: Color(0xFFD4D4D4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PythonHighlightEditingController extends TextEditingController {
  _PythonHighlightEditingController(String text) : super(text: text);

  static const TextStyle _baseStyle = TextStyle(
    color: Color(0xFFD4D4D4),
    fontSize: 20,
    fontFamily: 'Consolas',
    fontFamilyFallback: ['Courier New', 'monospace'],
    height: 1.35,
  );

  static final RegExp _tokenPattern = RegExp(
    r'''(#[^\n]*|"""[\s\S]*?"""|'{3}[\s\S]*?'{3}|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b\d+(?:\.\d+)?\b|\b[A-Za-z_][A-Za-z0-9_]*\b|\r\n|\r|\n|.)''',
    multiLine: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <InlineSpan>[];
    for (final match in _tokenPattern.allMatches(text)) {
      final token = match.group(0)!;
      spans.add(TextSpan(text: token, style: _tokenStyle(token)));
    }

    return TextSpan(style: style ?? _baseStyle, children: spans);
  }

  TextStyle _tokenStyle(String token) {
    if (token.startsWith('#')) {
      return _baseStyle.copyWith(
        color: const Color(0xFF6A9955),
        fontStyle: FontStyle.italic,
      );
    }

    if (_isStringToken(token)) {
      return _baseStyle.copyWith(color: const Color(0xFFCE9178));
    }

    if (_pythonKeywords.contains(token)) {
      return _baseStyle.copyWith(
        color: const Color(0xFF569CD6),
        fontWeight: FontWeight.w600,
      );
    }

    if (_pythonBuiltins.contains(token)) {
      return _baseStyle.copyWith(
        color: const Color(0xFF4EC9B0),
        fontWeight: FontWeight.w600,
      );
    }

    if (_pythonConstants.contains(token)) {
      return _baseStyle.copyWith(
        color: const Color(0xFFDCDCAA),
        fontWeight: FontWeight.w600,
      );
    }

    if (RegExp(r'^\d').hasMatch(token)) {
      return _baseStyle.copyWith(color: const Color(0xFFB5CEA8));
    }

    return _baseStyle;
  }

  bool _isStringToken(String token) {
    return token.startsWith('"') || token.startsWith("'");
  }
}

const Set<String> _arduinoKeywords = {
  'if',
  'else',
  'for',
  'while',
  'do',
  'switch',
  'case',
  'break',
  'continue',
  'return',
  'goto',
  'try',
  'catch',
  'throw',
  'class',
  'struct',
  'enum',
  'namespace',
  'using',
  'typedef',
  'template',
  'public',
  'private',
  'protected',
  'virtual',
  'static',
  'const',
  'constexpr',
  'volatile',
  'signed',
  'unsigned',
  'sizeof',
  'new',
  'delete',
  'this',
  'operator',
};

const Set<String> _pythonKeywords = {
  'False',
  'None',
  'True',
  'and',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'class',
  'continue',
  'def',
  'del',
  'elif',
  'else',
  'except',
  'finally',
  'for',
  'from',
  'global',
  'if',
  'import',
  'in',
  'is',
  'lambda',
  'nonlocal',
  'not',
  'or',
  'pass',
  'raise',
  'return',
  'try',
  'while',
  'with',
  'yield',
};

const Set<String> _pythonBuiltins = {
  'abs',
  'all',
  'any',
  'bool',
  'dict',
  'enumerate',
  'filter',
  'float',
  'int',
  'len',
  'list',
  'map',
  'max',
  'min',
  'print',
  'range',
  'set',
  'sorted',
  'str',
  'sum',
  'tuple',
  'zip',
};

const Set<String> _pythonConstants = {
  '__name__',
  '__main__',
  'NotImplemented',
  'Ellipsis',
};

const Set<String> _arduinoTypes = {
  'void',
  'bool',
  'boolean',
  'byte',
  'char',
  'word',
  'short',
  'int',
  'long',
  'float',
  'double',
  'size_t',
  'String',
  'HardwareSerial',
};

const Set<String> _arduinoConstants = {
  'true',
  'false',
  'HIGH',
  'LOW',
  'INPUT',
  'OUTPUT',
  'INPUT_PULLUP',
  'LED_BUILTIN',
  'HEX',
  'DEC',
  'OCT',
  'BIN',
  'FALLING',
  'RISING',
  'CHANGE',
  'LSBFIRST',
  'MSBFIRST',
  'PI',
  'NULL',
  'nullptr',
  'Serial',
  'Serial1',
  'Serial2',
  'Serial3',
};

// ─────────────────────────────────────────────────────────────────────────────
// Painter de formas geométricas
// ─────────────────────────────────────────────────────────────────────────────

class _ShapePainter extends CustomPainter {
  final String geometry;
  final ShapeFill? fill;
  final ShapeLine? outline;
  final double? adjValue;
  final _BorderMode borderMode;

  const _ShapePainter({
    required this.geometry,
    this.fill,
    this.outline,
    this.adjValue,
    this.borderMode = _BorderMode.all,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _buildPath(rect);

    if (fill != null && fill is! NoFill) {
      final paint = Paint()..style = PaintingStyle.fill;
      switch (fill) {
        case SolidFill():
          paint.color = (fill as SolidFill).color;
          canvas.drawPath(path, paint);
        case GradientFill():
          final gf = fill as GradientFill;
          paint.shader = LinearGradient(
            colors: gf.stops.map((s) => s.color).toList(),
            stops: gf.stops.map((s) => s.position).toList(),
            transform: GradientRotation(gf.angleDeg * 3.14159265358979 / 180.0),
          ).createShader(rect);
          canvas.drawPath(path, paint);
        default:
          break;
      }
    }

    if (outline != null && outline!.color != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = outline!.color!
        ..strokeWidth = outline!.widthPt;
      switch (borderMode) {
        case _BorderMode.all:
          canvas.drawPath(path, paint);
        case _BorderMode.bottom:
          canvas.drawLine(
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
            paint,
          );
        case _BorderMode.top:
          canvas.drawLine(
            Offset(rect.left, rect.top),
            Offset(rect.right, rect.top),
            paint,
          );
        case _BorderMode.left:
          canvas.drawLine(
            Offset(rect.left, rect.top),
            Offset(rect.left, rect.bottom),
            paint,
          );
        case _BorderMode.right:
          canvas.drawLine(
            Offset(rect.right, rect.top),
            Offset(rect.right, rect.bottom),
            paint,
          );
      }
    }
  }

  Path _buildPath(Rect rect) {
    switch (geometry) {
      case 'ellipse':
        return Path()..addOval(rect);
      case 'roundRect':
        final double r;
        if (adjValue != null) {
          // OOXML: raio = min(w,h) * adj / 100000
          final raw = math.min(rect.width, rect.height) * adjValue! / 100000.0;
          r = raw.clamp(0.0, math.min(rect.width, rect.height) / 2.0);
        } else {
          r = math.min(rect.width, rect.height) * 0.1;
        }
        return Path()
          ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
      case 'triangle':
        return Path()
          ..moveTo(rect.left + rect.width / 2, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case 'rtTriangle':
        return Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case 'rightArrow':
        final mid = rect.top + rect.height / 2;
        final shaft = rect.right - rect.width * 0.35;
        return Path()
          ..moveTo(rect.left, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top)
          ..lineTo(rect.right, mid)
          ..lineTo(shaft, rect.bottom)
          ..lineTo(shaft, rect.bottom - rect.height * 0.3)
          ..lineTo(rect.left, rect.bottom - rect.height * 0.3)
          ..close();
      case 'leftArrow':
        final mid = rect.top + rect.height / 2;
        final shaft = rect.left + rect.width * 0.35;
        return Path()
          ..moveTo(rect.right, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top + rect.height * 0.3)
          ..lineTo(shaft, rect.top)
          ..lineTo(rect.left, mid)
          ..lineTo(shaft, rect.bottom)
          ..lineTo(shaft, rect.bottom - rect.height * 0.3)
          ..lineTo(rect.right, rect.bottom - rect.height * 0.3)
          ..close();
      case 'pentagon':
        final cx = rect.center.dx;
        return Path()
          ..moveTo(cx, rect.top)
          ..lineTo(rect.right, rect.top + rect.height * 0.38)
          ..lineTo(rect.right - rect.width * 0.18, rect.bottom)
          ..lineTo(rect.left + rect.width * 0.18, rect.bottom)
          ..lineTo(rect.left, rect.top + rect.height * 0.38)
          ..close();
      case 'hexagon':
        final cx = rect.center.dx;
        final qw = rect.width * 0.25;
        return Path()
          ..moveTo(cx - qw, rect.top)
          ..lineTo(cx + qw, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(cx + qw, rect.bottom)
          ..lineTo(cx - qw, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
      case 'diamond':
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
      case 'parallelogram':
        final offset = rect.width * 0.2;
        return Path()
          ..moveTo(rect.left + offset, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right - offset, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case 'leftRightArrow':
        final aW = rect.width * 0.35;
        final sT = rect.top + rect.height * 0.31;
        final sB = rect.bottom - rect.height * 0.31;
        final mid = rect.center.dy;
        return Path()
          ..moveTo(rect.left + aW, rect.top)
          ..lineTo(rect.left + aW, sT)
          ..lineTo(rect.right - aW, sT)
          ..lineTo(rect.right - aW, rect.top)
          ..lineTo(rect.right, mid)
          ..lineTo(rect.right - aW, rect.bottom)
          ..lineTo(rect.right - aW, sB)
          ..lineTo(rect.left + aW, sB)
          ..lineTo(rect.left + aW, rect.bottom)
          ..lineTo(rect.left, mid)
          ..close();
      case 'upDownArrow':
        final aH = rect.height * 0.35;
        final sL = rect.left + rect.width * 0.31;
        final sR = rect.right - rect.width * 0.31;
        final midX = rect.center.dx;
        return Path()
          ..moveTo(rect.left, rect.top + aH)
          ..lineTo(sL, rect.top + aH)
          ..lineTo(sL, rect.bottom - aH)
          ..lineTo(rect.left, rect.bottom - aH)
          ..lineTo(midX, rect.bottom)
          ..lineTo(rect.right, rect.bottom - aH)
          ..lineTo(sR, rect.bottom - aH)
          ..lineTo(sR, rect.top + aH)
          ..lineTo(rect.right, rect.top + aH)
          ..lineTo(midX, rect.top)
          ..close();
      case 'line':
      case 'straightConnector1':
        return Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.bottom);
      default:
        return Path()..addRect(rect);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.geometry != geometry ||
      old.fill != fill ||
      old.outline != outline ||
      old.adjValue != adjValue ||
      old.borderMode != borderMode;
}
