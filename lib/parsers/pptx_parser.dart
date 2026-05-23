import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../models/pptx_models.dart';
import 'ooxml_helpers.dart';

/// Analisa um arquivo .pptx (bytes) e retorna [PresentationData].
class PptxParser {
  // ── Mapa de arquivo dentro do ZIP ──────────────────────────────────────────
  final Map<String, Uint8List> _files = {};

  // ── Mapa de posições de placeholders (herança layout/master) ──────────────
  // Chave: idx ou type do ph. Valor: posição em EMU.
  final Map<String, ({double x, double y, double cx, double cy})> _phMap = {};

  // Contexto de herança de estilos de texto (master/layout -> slide).
  _TextStyleContext? _textStyleContext;

  // ── Relacionamentos ────────────────────────────────────────────────────────
  /// Retorna o mapa { rId → target } para um arquivo-pai.
  Map<String, String> _rels(String parentPath) {
    final dir = parentPath.contains('/')
        ? parentPath.substring(0, parentPath.lastIndexOf('/'))
        : '';
    final name = parentPath.contains('/')
        ? parentPath.substring(parentPath.lastIndexOf('/') + 1)
        : parentPath;
    final relsPath = dir.isEmpty ? '_rels/$name.rels' : '$dir/_rels/$name.rels';
    final bytes = _files[relsPath];
    if (bytes == null) return {};
    final doc = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
    final result = <String, String>{};
    for (final rel in doc.rootElement.children_('Relationship')) {
      final id = rel.attr('Id') ?? '';
      var target = rel.attr('Target') ?? '';
      if (target.startsWith('/')) {
        target = target.substring(1);
      } else if (dir.isNotEmpty && !target.startsWith('ppt')) {
        target = _resolveRelative(dir, target);
      }
      result[id] = target;
    }
    return result;
  }

  String _resolveRelative(String base, String rel) {
    final parts = '$base/$rel'.split('/');
    final result = <String>[];
    for (final p in parts) {
      if (p == '..') {
        if (result.isNotEmpty) result.removeLast();
      } else if (p != '.') {
        result.add(p);
      }
    }
    return result.join('/');
  }

  XmlDocument? _parseXml(String path) {
    final b = _files[path];
    if (b == null) return null;
    try {
      return XmlDocument.parse(utf8.decode(b, allowMalformed: true));
    } catch (_) {
      return null;
    }
  }

  // ── Ponto de entrada ───────────────────────────────────────────────────────

  PresentationData parse(Uint8List pptxBytes) {
    _files.clear();
    _phMap.clear();

    // 1. Extrai ZIP
    final archive = ZipDecoder().decodeBytes(pptxBytes);
    for (final f in archive.files) {
      if (f.isFile) {
        _files[f.name] = f.content;
      }
    }

    // 2. Localiza presentation.xml via _rels/.rels
    final rootRels = _rels('');
    final presentationPath = rootRels.values.firstWhere(
      (v) => v.endsWith('.xml') && v.contains('presentation'),
      orElse: () => 'ppt/presentation.xml',
    );

    // 3. Lê dimensões do slide + lista de slides
    final presDoc = _parseXml(presentationPath);
    if (presDoc == null) throw Exception('presentation.xml não encontrado');
    final presRoot = presDoc.rootElement;

    final sldSz = presRoot.deep('sldSz');
    final slideWidthEmu =
        double.tryParse(sldSz?.attr('cx') ?? '9144000') ?? 9144000;
    final slideHeightEmu =
        double.tryParse(sldSz?.attr('cy') ?? '6858000') ?? 6858000;

    // 4. Resolve tema
    final presRels = _rels(presentationPath);
    final themePath = presRels.values.firstWhere(
      (v) => v.contains('theme'),
      orElse: () => '',
    );
    final theme = themePath.isNotEmpty
        ? _parseTheme(themePath)
        : OOXMLTheme.defaultTheme;
    final embeddedFonts = _parseEmbeddedFonts(
      presRoot,
      presentationRels: presRels,
    );

    final cr = ColorResolver(theme);

    // 5. Parseia cada slide
    final sldIdLst = presRoot.deep('sldIdLst');
    final slideIds = sldIdLst?.children_('sldId').toList() ?? [];

    final slides = <SlideData>[];
    for (var i = 0; i < slideIds.length; i++) {
      // O atributo de relacionamento é r:id (com namespace), não o id numérico.
      // Filtramos pelo prefixo de namespace para distinguir dos dois atributos "id".
      final actualRid = slideIds[i].attributes
          .where(
            (a) =>
                a.localName == 'id' &&
                (a.name.prefix == 'r' ||
                    (a.namespaceUri?.contains('relationships') ?? false)),
          )
          .map((a) => a.value)
          .firstOrNull;
      if (actualRid == null) continue;

      final slidePath = presRels[actualRid];
      if (slidePath == null) continue;

      final slide = _parseSlide(i, slidePath, cr);
      if (slide != null) slides.add(slide);
    }

    return PresentationData(
      slides: slides,
      slideWidthEmu: slideWidthEmu,
      slideHeightEmu: slideHeightEmu,
      theme: theme,
      embeddedFonts: embeddedFonts,
    );
  }

  // ── Tema ──────────────────────────────────────────────────────────────────

  OOXMLTheme _parseTheme(String path) {
    final doc = _parseXml(path);
    if (doc == null) return OOXMLTheme.defaultTheme;

    final colorScheme = <String, Color>{};
    final clrScheme = doc.rootElement.deep('clrScheme');
    if (clrScheme != null) {
      final tokenNames = [
        'dk1',
        'lt1',
        'dk2',
        'lt2',
        'accent1',
        'accent2',
        'accent3',
        'accent4',
        'accent5',
        'accent6',
        'hlink',
        'folHlink',
      ];
      for (final token in tokenNames) {
        final el = clrScheme.child(token);
        if (el == null) continue;
        Color? c;
        final srgb = el.child('srgbClr');
        if (srgb != null) c = ColorResolver.hexToColor(srgb.attr('val'));
        final sys = el.child('sysClr');
        if (sys != null) c = ColorResolver.hexToColor(sys.attr('lastClr'));
        if (c != null) colorScheme[token] = c;
      }
    }

    String majorFont = 'Calibri';
    String minorFont = 'Calibri';
    final fontScheme = doc.rootElement.deep('fontScheme');
    if (fontScheme != null) {
      final major = fontScheme.child('majorFont')?.child('latin');
      final minor = fontScheme.child('minorFont')?.child('latin');
      if (major != null) majorFont = major.attr('typeface') ?? majorFont;
      if (minor != null) minorFont = minor.attr('typeface') ?? minorFont;
    }

    final defaults = OOXMLTheme.defaultTheme.colorScheme;
    for (final e in defaults.entries) {
      colorScheme.putIfAbsent(e.key, () => e.value);
    }

    return OOXMLTheme(
      colorScheme: colorScheme,
      majorFontLatin: majorFont,
      minorFontLatin: minorFont,
    );
  }

  List<EmbeddedFontFace> _parseEmbeddedFonts(
    XmlElement presentationRoot, {
    required Map<String, String> presentationRels,
  }) {
    final faces = <EmbeddedFontFace>[];
    final dedup = <String>{};

    void collectFrom(XmlElement root, Map<String, String> rels) {
      final embeddedFontLst = root.deep('embeddedFontLst');
      if (embeddedFontLst == null) return;

      for (final embedded in embeddedFontLst.children_('embeddedFont')) {
        final family = embedded.child('font')?.attr('typeface')?.trim() ?? '';
        if (family.isEmpty) continue;

        final sharedKey = _extractFontKey(embedded);
        final variants = [
          ('regular', false, false),
          ('embedRegular', false, false),
          ('bold', true, false),
          ('embedBold', true, false),
          ('italic', false, true),
          ('embedItalic', false, true),
          ('boldItalic', true, true),
          ('embedBoldItalic', true, true),
        ];

        for (final (tag, bold, italic) in variants) {
          final variant = embedded.child(tag);
          if (variant == null) continue;

          final rid = _extractRid(variant);
          if (rid == null) continue;

          final target = rels[rid];
          if (target == null || target.isEmpty) continue;

          final raw = _files[target];
          if (raw == null || raw.isEmpty) continue;

          final key = _extractFontKey(variant) ?? sharedKey;
          final decoded = _decodeEmbeddedFontPart(
            raw,
            target: target,
            key: key,
          );

          final dedupKey =
              '${family.toLowerCase()}|${bold ? 1 : 0}|${italic ? 1 : 0}|$target';
          if (!dedup.add(dedupKey)) continue;

          faces.add(
            EmbeddedFontFace(
              family: family,
              bold: bold,
              italic: italic,
              bytes: decoded,
            ),
          );
        }
      }
    }

    collectFrom(presentationRoot, presentationRels);

    final fontTablePath = presentationRels.values.firstWhere(
      (v) => v.contains('fontTable'),
      orElse: () => '',
    );
    if (fontTablePath.isNotEmpty) {
      final fontTableDoc = _parseXml(fontTablePath);
      if (fontTableDoc != null) {
        collectFrom(fontTableDoc.rootElement, _rels(fontTablePath));
      }
    }

    return faces;
  }

  String? _extractRid(XmlElement element) {
    return element.attributes
        .where(
          (a) =>
              a.localName == 'id' &&
              (a.name.prefix == 'r' ||
                  (a.namespaceUri?.contains('relationships') ?? false)),
        )
        .map((a) => a.value)
        .firstOrNull;
  }

  String? _extractFontKey(XmlElement element) {
    final direct = element.attr('fontKey') ?? element.attr('key');
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();

    final keyChild = element.child('fontKey');
    final keyVal = keyChild?.attr('val') ?? keyChild?.attr('fontKey');
    if (keyVal != null && keyVal.trim().isNotEmpty) return keyVal.trim();

    return null;
  }

  Uint8List _decodeEmbeddedFontPart(
    Uint8List bytes, {
    required String target,
    required String? key,
  }) {
    if (!target.toLowerCase().endsWith('.odttf')) return bytes;
    final guid = _guidToBytes(key);
    if (guid == null) return bytes;

    final result = Uint8List.fromList(bytes);
    final reversed = guid.reversed.toList(growable: false);
    final limit = result.length < 32 ? result.length : 32;
    for (var i = 0; i < limit; i++) {
      result[i] = result[i] ^ reversed[i % 16];
    }
    return result;
  }

  List<int>? _guidToBytes(String? key) {
    if (key == null || key.isEmpty) return null;
    final clean = key.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (clean.length != 32) return null;
    final bytes = <int>[];
    for (var i = 0; i < 32; i += 2) {
      final value = int.tryParse(clean.substring(i, i + 2), radix: 16);
      if (value == null) return null;
      bytes.add(value);
    }
    return bytes;
  }

  // ── Slide ─────────────────────────────────────────────────────────────────

  SlideData? _parseSlide(int index, String slidePath, ColorResolver cr) {
    final doc = _parseXml(slidePath);
    if (doc == null) return null;

    final slideRels = _rels(slidePath);

    final layoutPath = slideRels.values.firstWhere(
      (v) => v.contains('slideLayout'),
      orElse: () => '',
    );
    final layoutDoc = layoutPath.isNotEmpty ? _parseXml(layoutPath) : null;

    String masterPath = '';
    if (layoutPath.isNotEmpty) {
      final layoutRels = _rels(layoutPath);
      masterPath = layoutRels.values.firstWhere(
        (v) => v.contains('slideMaster'),
        orElse: () => '',
      );
    }
    final masterDoc = masterPath.isNotEmpty ? _parseXml(masterPath) : null;

    // ── Fundo ──────────────────────────────────────────────────────────────
    final background = _parseBackground(
      doc.rootElement,
      layoutDoc,
      masterDoc,
      cr,
      slideRels,
      layoutPath.isNotEmpty ? _rels(layoutPath) : {},
      masterPath.isNotEmpty ? _rels(masterPath) : {},
    );

    // ── Elementos do slide master (decorações permanentes) ──────────────────
    final masterRels = masterPath.isNotEmpty
        ? _rels(masterPath)
        : <String, String>{};
    final masterElements = <SlideElement>[];
    if (masterDoc != null) {
      final masterSpTree = masterDoc.rootElement.deep('spTree');
      if (masterSpTree != null) {
        var z = 0;
        for (final child in masterSpTree.children.whereType<XmlElement>()) {
          if (_isPlaceholder(child)) continue;
          final els = _parseSpTreeChildList(
            child,
            z,
            cr,
            masterRels,
            textStyleContext: null,
          );
          masterElements.addAll(els);
          z += els.length;
        }
      }
    }

    // ── Elementos do slide layout (decorações de layout) ──────────────────────
    final layoutRels = layoutPath.isNotEmpty
        ? _rels(layoutPath)
        : <String, String>{};
    final layoutElements = <SlideElement>[];
    if (layoutDoc != null) {
      final layoutSpTree = layoutDoc.rootElement.deep('spTree');
      if (layoutSpTree != null) {
        var z = 1000;
        for (final child in layoutSpTree.children.whereType<XmlElement>()) {
          if (_isPlaceholder(child)) continue;
          final els = _parseSpTreeChildList(
            child,
            z,
            cr,
            layoutRels,
            textStyleContext: null,
          );
          layoutElements.addAll(els);
          z += els.length;
        }
      }
    }

    // ── Mapa de posições de placeholders (herança do layout e master) ──────────
    _buildPhMap(masterDoc, layoutDoc);

    // ── Elementos do slide (conteúdo principal) ───────────────────────────────
    final spTree = doc.rootElement.deep('spTree');
    final slideElements = <SlideElement>[];
    var zOrder = 2000;

    _textStyleContext = _TextStyleContext(
      colorResolver: cr,
      masterTxStyles: masterDoc?.rootElement.deep('txStyles'),
      masterSpTree: masterDoc?.rootElement.deep('spTree'),
      layoutSpTree: layoutDoc?.rootElement.deep('spTree'),
    );

    if (spTree != null) {
      for (final child in spTree.children.whereType<XmlElement>()) {
        final els = _parseSpTreeChildList(
          child,
          zOrder,
          cr,
          slideRels,
          textStyleContext: _textStyleContext,
        );
        slideElements.addAll(els);
        zOrder += els.length;
      }
    }

    final allElements = [
      ...masterElements.map(_zeroShapeId),
      ...layoutElements.map(_zeroShapeId),
      ...slideElements,
    ];

    // ── Transição ─────────────────────────────────────────────────────────
    final transition = doc.rootElement.deep('transition');
    int transitionMs = 500;
    if (transition != null) {
      final dur = transition.attr('dur');
      if (dur != null) {
        transitionMs = (int.tryParse(dur) ?? 500).clamp(100, 3000);
      }
    }

    // ── Animações (timing) ────────────────────────────────────────────────
    final animSteps = _parseTiming(doc.rootElement);

    // ── Anotações do apresentador ──────────────────────────────────────────
    final notes = _parseNotes(slidePath, slideRels);

    return SlideData(
      index: index,
      elements: allElements,
      background: background,
      animSteps: animSteps,
      transitionMs: transitionMs,
      notes: notes,
    );
  }

  // ── Herança de posição de placeholders ──────────────────────────────────

  /// Constrói [_phMap] a partir dos placeholders do master e layout.
  /// Layout tem prioridade (processa por último, sobrescreve master).
  void _buildPhMap(XmlDocument? masterDoc, XmlDocument? layoutDoc) {
    _phMap.clear();
    for (final doc in [masterDoc, layoutDoc]) {
      if (doc == null) continue;
      final spTree = doc.rootElement.deep('spTree');
      if (spTree == null) continue;
      for (final sp in spTree.children_('sp')) {
        final ph = sp.child('nvSpPr')?.child('nvPr')?.child('ph');
        if (ph == null) continue;
        final idx = ph.attr('idx') ?? '0';
        final type = ph.attr('type') ?? '';
        final xfrm = _parseXfrm(sp);
        if (xfrm.cx > 0 || xfrm.cy > 0) {
          final pos = (x: xfrm.x, y: xfrm.y, cx: xfrm.cx, cy: xfrm.cy);
          _phMap[idx] = pos;
          if (type.isNotEmpty) _phMap[type] = pos;
        }
      }
    }
  }

  // ── Anotações do apresentador ─────────────────────────────────────────────

  /// Extrai o texto das anotações do slide (notesSlide*.xml).
  String? _parseNotes(String slidePath, Map<String, String> slideRels) {
    final notesPath = slideRels.values.firstWhere(
      (v) => v.contains('notesSlide'),
      orElse: () => '',
    );
    if (notesPath.isEmpty) return null;

    final doc = _parseXml(notesPath);
    if (doc == null) return null;

    final spTree = doc.rootElement.deep('cSld')?.deep('spTree');
    if (spTree == null) return null;

    final preferred = StringBuffer();
    final fallback = StringBuffer();

    void appendParagraphs(StringBuffer target, XmlElement txBody) {
      for (final p in txBody.children_('p')) {
        final line = p
            .children_('r')
            .map((r) => r.child('t')?.innerText ?? '')
            .join('');
        if (line.isNotEmpty) {
          if (target.isNotEmpty) target.write('\n');
          target.write(line);
        }
      }
    }

    for (final sp in spTree.children_('sp')) {
      final ph = sp.child('nvSpPr')?.child('nvPr')?.child('ph');
      final txBody = sp.deep('txBody');
      if (txBody == null) continue;

      final idx = ph?.attr('idx');
      final type = ph?.attr('type');
      if (idx == '1' || type == 'body') {
        appendParagraphs(preferred, txBody);
      } else if (type != 'dt' && type != 'ftr' && type != 'sldNum') {
        appendParagraphs(fallback, txBody);
      }
    }

    final result = preferred.isNotEmpty ? preferred : fallback;
    return result.isEmpty ? null : result.toString();
  }

  // ── Fundo ────────────────────────────────────────────────────────────────

  SlideBackground? _parseBackground(
    XmlElement slideRoot,
    XmlDocument? layoutDoc,
    XmlDocument? masterDoc,
    ColorResolver cr,
    Map<String, String> slideRels,
    Map<String, String> layoutRels,
    Map<String, String> masterRels,
  ) {
    for (final entry in [
      (slideRoot, slideRels),
      if (layoutDoc != null) (layoutDoc.rootElement, layoutRels),
      if (masterDoc != null) (masterDoc.rootElement, masterRels),
    ]) {
      final source = entry.$1;
      final rels = entry.$2;
      final bg = source.child('bg') ?? source.deep('bg');
      if (bg == null) continue;

      final bgPr = bg.child('bgPr');
      if (bgPr != null) {
        final fill = parseFill(bgPr, cr);
        if (fill != null) return SlideBackground(fill: fill);

        final blipFill = bgPr.child('blipFill');
        if (blipFill != null) {
          final blip = blipFill.child('blip');
          if (blip != null) {
            final embedAttr = blip.attributes
                .where((a) => a.localName == 'embed')
                .firstOrNull;
            if (embedAttr != null) {
              final imgPath = rels[embedAttr.value];
              if (imgPath != null) {
                final bytes = _files[imgPath];
                if (bytes != null) return SlideBackground(imageBytes: bytes);
              }
            }
          }
        }
      }

      final bgRef = bg.child('bgRef');
      if (bgRef != null) {
        final fill = cr.resolveColorElement(bgRef);
        if (fill != null) return SlideBackground(fill: SolidFill(fill));
      }
    }
    return null;
  }

  // ── Dispatch de elementos ─────────────────────────────────────────────────

  List<SlideElement> _parseSpTreeChildList(
    XmlElement el,
    int zOrder,
    ColorResolver cr,
    Map<String, String> rels, {
    _TextStyleContext? textStyleContext,
  }) {
    switch (el.localName) {
      case 'sp':
        final e = _parseSp(el, zOrder, cr, textStyleContext: textStyleContext);
        return e != null ? [e] : [];
      case 'cxnSp': // conector — trata como shape sem texto
        final e = _parseCxnSp(el, zOrder, cr);
        return e != null ? [e] : [];
      case 'pic':
        final e = _parsePic(el, zOrder, rels);
        return e != null ? [e] : [];
      case 'graphicFrame':
        final e = _parseGraphicFrame(el, zOrder, cr);
        return e != null ? [e] : [];
      case 'grpSp':
        return _parseGrpSp(
          el,
          zOrder,
          cr,
          rels,
          textStyleContext: textStyleContext,
        );
      default:
        return [];
    }
  }

  // ── Transform helper ──────────────────────────────────────────────────────

  ({double x, double y, double cx, double cy, double? rot}) _parseXfrm(
    XmlElement parent,
  ) {
    final xfrm = parent.deep('xfrm');
    if (xfrm == null) return (x: 0, y: 0, cx: 0, cy: 0, rot: null);
    final off = xfrm.child('off');
    final ext = xfrm.child('ext');
    final x = double.tryParse(off?.attr('x') ?? '0') ?? 0;
    final y = double.tryParse(off?.attr('y') ?? '0') ?? 0;
    final cx = double.tryParse(ext?.attr('cx') ?? '0') ?? 0;
    final cy = double.tryParse(ext?.attr('cy') ?? '0') ?? 0;
    final rotRaw = xfrm.attr('rot');
    final rot = rotRaw != null ? (int.tryParse(rotRaw) ?? 0) / 60000.0 : null;
    return (x: x, y: y, cx: cx, cy: cy, rot: rot);
  }

  String? _extractAltText(XmlElement? cNvPr) {
    if (cNvPr == null) return null;
    final descr = cNvPr.attr('descr');
    if (descr != null && descr.trim().isNotEmpty) return descr.trim();
    final title = cNvPr.attr('title');
    if (title != null && title.trim().isNotEmpty) return title.trim();
    final name = cNvPr.attr('name');
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return null;
  }

  // ── Shape (p:sp) ──────────────────────────────────────────────────────────

  ShapeElement? _parseSp(
    XmlElement sp,
    int zOrder,
    ColorResolver cr, {
    _TextStyleContext? textStyleContext,
  }) {
    final spPr = sp.child('spPr');
    var xfrm = _parseXfrm(sp);
    final cNvPr = sp.child('nvSpPr')?.child('cNvPr');
    final shapeId = int.tryParse(cNvPr?.attr('id') ?? '') ?? 0;
    final altText = _extractAltText(cNvPr);

    final ph = sp.child('nvSpPr')?.child('nvPr')?.child('ph');
    final placeholderType = ph?.attr('type');
    final placeholderIdx = ph?.attr('idx') ?? '0';

    // Herança de posição: placeholder sem xfrm próprio usa posição do layout/master
    if ((xfrm.cx == 0 && xfrm.cy == 0) && _phMap.isNotEmpty) {
      if (ph != null) {
        final idx = ph.attr('idx') ?? '0';
        final type = ph.attr('type') ?? '';
        final pos = (type.isNotEmpty ? _phMap[type] : null) ?? _phMap[idx];
        if (pos != null) {
          xfrm = (x: pos.x, y: pos.y, cx: pos.cx, cy: pos.cy, rot: xfrm.rot);
        }
      }
    }

    final prstGeomEl = spPr?.child('prstGeom');
    final prstGeom = prstGeomEl?.attr('prst');
    // Lê adj do avLst (ex.: roundRect corner radius)
    final adjGd = prstGeomEl
        ?.child('avLst')
        ?.children_('gd')
        .where((g) => g.attr('name') == 'adj')
        .firstOrNull;
    final adjFmla = adjGd?.attr('fmla'); // ex.: "val 25000"
    final adjValue = adjFmla != null
        ? double.tryParse(adjFmla.replaceFirst('val ', '').trim())
        : null;

    final fill = parseFill(spPr, cr);
    final outline = parseLine(spPr?.child('ln'), cr);
    final txBody = sp.child('txBody');
    final textDefaults = txBody != null
        ? _resolveTextDefaults(
            txBody,
            placeholderType: placeholderType,
            placeholderIdx: placeholderIdx,
            context: textStyleContext,
          )
        : null;
    final paragraphs = txBody != null
        ? _parseTxBody(txBody, cr, defaults: textDefaults)
        : <TextParagraph>[];
    final bodyPrEl = txBody?.child('bodyPr');
    final bodyProps = _resolveBodyProps(
      bodyPrEl,
      placeholderType: placeholderType,
      placeholderIdx: placeholderIdx,
      context: textStyleContext,
    );

    return ShapeElement(
      xEmu: xfrm.x,
      yEmu: xfrm.y,
      cxEmu: xfrm.cx,
      cyEmu: xfrm.cy,
      zOrder: zOrder,
      rotationDeg: xfrm.rot,
      shapeId: shapeId,
      commandText: null,
      presetGeometry: prstGeom,
      fill: fill,
      outline: outline,
      paragraphs: paragraphs,
      bodyProps: bodyProps,
      adjValue: adjValue,
      altText: altText,
      placeholderType: placeholderType,
    );
  }

  // ── Conector (p:cxnSp) ────────────────────────────────────────────────────

  ShapeElement? _parseCxnSp(XmlElement cxn, int zOrder, ColorResolver cr) {
    final spPr = cxn.child('spPr');
    final xfrm = _parseXfrm(cxn);
    final shapeId =
        int.tryParse(
          cxn.child('nvCxnSpPr')?.child('cNvPr')?.attr('id') ?? '',
        ) ??
        0;
    final prstGeom = spPr?.child('prstGeom')?.attr('prst') ?? 'line';
    final outline = parseLine(spPr?.child('ln'), cr);

    return ShapeElement(
      xEmu: xfrm.x,
      yEmu: xfrm.y,
      cxEmu: xfrm.cx,
      cyEmu: xfrm.cy,
      zOrder: zOrder,
      rotationDeg: xfrm.rot,
      shapeId: shapeId,
      commandText: null,
      presetGeometry: prstGeom,
      fill: NoFill(),
      outline: outline,
      paragraphs: const [],
      bodyProps: TextBodyProperties.defaults,
    );
  }

  // ── Imagem (p:pic) ────────────────────────────────────────────────────────

  ImageElement? _parsePic(
    XmlElement pic,
    int zOrder,
    Map<String, String> rels,
  ) {
    final xfrm = _parseXfrm(pic);
    final cNvPr = pic.child('nvPicPr')?.child('cNvPr');
    final shapeId = int.tryParse(cNvPr?.attr('id') ?? '') ?? 0;
    final altText = _extractAltText(cNvPr);
    final blipFill = pic.child('blipFill');
    final blip = blipFill?.child('blip');
    if (blip == null) return null;

    final embedAttr = blip.attributes
        .where((a) => a.localName == 'embed')
        .firstOrNull;
    final svgBlip = blip.deep('svgBlip');
    final svgEmbedAttr = svgBlip?.attributes
        .where((a) => a.localName == 'embed')
        .firstOrNull;
    final relId = embedAttr?.value ?? svgEmbedAttr?.value;
    final imgPath = relId != null ? rels[relId] : null;
    var bytes = imgPath != null ? _files[imgPath] : null;
    final mimeType = _detectImageMimeType(imgPath, bytes);
    if (bytes != null && mimeType == 'image/svg+xml') {
      bytes = _normalizeSvgBytes(bytes);
    }

    return ImageElement(
      xEmu: xfrm.x,
      yEmu: xfrm.y,
      cxEmu: xfrm.cx,
      cyEmu: xfrm.cy,
      zOrder: zOrder,
      rotationDeg: xfrm.rot,
      shapeId: shapeId,
      commandText: null,
      imageBytes: bytes,
      mimeType: mimeType,
      altText: altText,
    );
  }

  Uint8List _normalizeSvgBytes(Uint8List original) {
    try {
      final svg = utf8.decode(original, allowMalformed: true);
      final fillMatch = RegExp(
        r'\.iconFill\s*\{\s*fill\s*:\s*(#[0-9A-Fa-f]{3,8})\s*;?\s*\}',
      ).firstMatch(svg);
      if (fillMatch == null) return original;

      final fill = fillMatch.group(1);
      if (fill == null || fill.isEmpty) return original;

      final normalized = svg
          .replaceAll('class="iconFill"', 'class="iconFill" fill="$fill"')
          .replaceAll("class='iconFill'", "class='iconFill' fill='$fill'")
          .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>'), '');

      return Uint8List.fromList(utf8.encode(normalized));
    } catch (_) {
      return original;
    }
  }

  String? _detectImageMimeType(String? path, Uint8List? bytes) {
    if (path != null) {
      final lower = path.toLowerCase();
      if (lower.endsWith('.svg')) return 'image/svg+xml';
      if (lower.endsWith('.png')) return 'image/png';
      if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        return 'image/jpeg';
      }
      if (lower.endsWith('.gif')) return 'image/gif';
      if (lower.endsWith('.webp')) return 'image/webp';
      if (lower.endsWith('.bmp')) return 'image/bmp';
    }
    if (bytes == null || bytes.length < 8) return null;

    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    final headLen = bytes.length < 64 ? bytes.length : 64;
    final head = String.fromCharCodes(bytes.sublist(0, headLen)).toLowerCase();
    if (head.contains('<svg')) return 'image/svg+xml';

    return null;
  }

  // ── Graphic Frame (tabela, gráfico) ───────────────────────────────────────

  SlideElement? _parseGraphicFrame(
    XmlElement gf,
    int zOrder,
    ColorResolver cr,
  ) {
    final xfrm = _parseXfrm(gf);
    final shapeId =
        int.tryParse(
          gf.child('nvGraphicFramePr')?.child('cNvPr')?.attr('id') ?? '',
        ) ??
        0;
    final tbl = gf.deep('tbl');
    if (tbl != null) {
      return _parseTable(tbl, xfrm, zOrder, cr, shapeId: shapeId);
    }
    return null;
  }

  TableElement _parseTable(
    XmlElement tbl,
    ({double x, double y, double cx, double cy, double? rot}) xfrm,
    int zOrder,
    ColorResolver cr, {
    int shapeId = 0,
  }) {
    // Larguras de colunas do tblGrid
    final tblGrid = tbl.child('tblGrid');
    final colWidthsEmu =
        tblGrid
            ?.children_('gridCol')
            .map((c) => double.tryParse(c.attr('w') ?? '0') ?? 0.0)
            .toList() ??
        <double>[];

    final rows = tbl.children_('tr').map((tr) {
      final heightEmu = double.tryParse(tr.attr('h') ?? '0') ?? 0;
      final cells = tr
          .children_('tc')
          .map((tc) {
            // tc contém txBody → não passar tc diretamente
            final txBodyEl = tc.child('txBody');
            final paras = txBodyEl != null
                ? _parseTxBody(txBodyEl, cr)
                : <TextParagraph>[];
            final tcPr = tc.child('tcPr');
            final fill = parseFill(tcPr, cr);
            final gridSpan = int.tryParse(tc.attr('gridSpan') ?? '1') ?? 1;
            final vMerge = tc.attr('vMerge') != null;
            if (vMerge) return null; // células fundidas verticalmente: pula
            return SlideTableCell(
              paragraphs: paras,
              fill: fill,
              gridSpan: gridSpan,
            );
          })
          .whereType<SlideTableCell>()
          .toList();
      return SlideTableRow(cells: cells, heightEmu: heightEmu);
    }).toList();

    return TableElement(
      xEmu: xfrm.x,
      yEmu: xfrm.y,
      cxEmu: xfrm.cx,
      cyEmu: xfrm.cy,
      zOrder: zOrder,
      shapeId: shapeId,
      commandText: null,
      rows: rows,
      colWidthsEmu: colWidthsEmu,
    );
  }

  // ── Grupo (p:grpSp) ───────────────────────────────────────────────────────

  List<SlideElement> _parseGrpSp(
    XmlElement grp,
    int zOrderStart,
    ColorResolver cr,
    Map<String, String> rels, {
    _TextStyleContext? textStyleContext,
  }) {
    // ID do grupo (cNvPr/@id) — os filhos herdam este ID para que animações
    // que referenciam o grupo (spTgt spid="N") funcionem corretamente.
    final groupAltText = _extractAltText(
      grp.child('nvGrpSpPr')?.child('cNvPr'),
    );
    final groupId =
        int.tryParse(
          grp.child('nvGrpSpPr')?.child('cNvPr')?.attr('id') ?? '0',
        ) ??
        0;

    // Lê o transform do grupo para mapear coordenadas dos filhos
    final grpSpPr = grp.child('grpSpPr');
    final grpXfrm = grpSpPr?.child('xfrm') ?? grpSpPr?.deep('xfrm');

    double grpX = 0, grpY = 0, grpCx = 0, grpCy = 0;
    double chOffX = 0, chOffY = 0, chExtCx = 0, chExtCy = 0;

    if (grpXfrm != null) {
      final off = grpXfrm.child('off');
      final ext = grpXfrm.child('ext');
      final chOff = grpXfrm.child('chOff');
      final chExt = grpXfrm.child('chExt');
      grpX = double.tryParse(off?.attr('x') ?? '0') ?? 0;
      grpY = double.tryParse(off?.attr('y') ?? '0') ?? 0;
      grpCx = double.tryParse(ext?.attr('cx') ?? '0') ?? 0;
      grpCy = double.tryParse(ext?.attr('cy') ?? '0') ?? 0;
      chOffX = double.tryParse(chOff?.attr('x') ?? '0') ?? 0;
      chOffY = double.tryParse(chOff?.attr('y') ?? '0') ?? 0;
      chExtCx = double.tryParse(chExt?.attr('cx') ?? '0') ?? 0;
      chExtCy = double.tryParse(chExt?.attr('cy') ?? '0') ?? 0;
    }

    final scaleX = chExtCx > 0 ? grpCx / chExtCx : 1.0;
    final scaleY = chExtCy > 0 ? grpCy / chExtCy : 1.0;

    final result = <SlideElement>[];
    var zOrder = zOrderStart;

    for (final child in grp.children.whereType<XmlElement>()) {
      if (child.localName == 'grpSpPr' || child.localName == 'nvGrpSpPr') {
        continue;
      }
      final els = _parseSpTreeChildList(
        child,
        zOrder,
        cr,
        rels,
        textStyleContext: textStyleContext,
      );
      for (final el in els) {
        result.add(
          _withCommandText(
            _applyGroupTransform(
              el,
              grpX,
              grpY,
              chOffX,
              chOffY,
              scaleX,
              scaleY,
              zOrder,
            ),
            groupAltText,
          ),
        );
        zOrder++;
      }
    }
    // Propaga o ID do grupo para todos os filhos. Isso permite que animações
    // que referenciam o grupo (spTgt spid) encontrem os elementos corretos.
    if (groupId != 0) {
      return result.map((el) => _withShapeId(el, groupId)).toList();
    }
    return result;
  }

  /// Aplica o transform do grupo às coordenadas de um elemento filho.
  SlideElement _applyGroupTransform(
    SlideElement el,
    double grpX,
    double grpY,
    double chOffX,
    double chOffY,
    double scaleX,
    double scaleY,
    int zOrder,
  ) {
    final newX = grpX + (el.xEmu - chOffX) * scaleX;
    final newY = grpY + (el.yEmu - chOffY) * scaleY;
    final newCx = el.cxEmu * scaleX;
    final newCy = el.cyEmu * scaleY;

    switch (el) {
      case ShapeElement():
        return ShapeElement(
          xEmu: newX,
          yEmu: newY,
          cxEmu: newCx,
          cyEmu: newCy,
          zOrder: zOrder,
          rotationDeg: el.rotationDeg,
          shapeId: el.shapeId,
          commandText: el.commandText,
          presetGeometry: el.presetGeometry,
          fill: el.fill,
          outline: el.outline,
          paragraphs: el.paragraphs,
          bodyProps: el.bodyProps,
          adjValue: el.adjValue,
          altText: el.altText,
          placeholderType: el.placeholderType,
        );
      case ImageElement():
        return ImageElement(
          xEmu: newX,
          yEmu: newY,
          cxEmu: newCx,
          cyEmu: newCy,
          zOrder: zOrder,
          rotationDeg: el.rotationDeg,
          shapeId: el.shapeId,
          commandText: el.commandText,
          imageBytes: el.imageBytes,
          mimeType: el.mimeType,
          altText: el.altText,
        );
      case TableElement():
        return TableElement(
          xEmu: newX,
          yEmu: newY,
          cxEmu: newCx,
          cyEmu: newCy,
          zOrder: zOrder,
          shapeId: el.shapeId,
          commandText: el.commandText,
          rows: el.rows,
          colWidthsEmu: el.colWidthsEmu,
        );
    }
  }

  // ── Placeholder check ─────────────────────────────────────────────────────

  /// Retorna true se o elemento é um placeholder (preenchido pelo slide).
  bool _isPlaceholder(XmlElement el) {
    if (el.localName != 'sp') return false;
    final ph = el.child('nvSpPr')?.child('nvPr')?.child('ph');
    return ph != null;
  }

  // ── Timing / Animações ────────────────────────────────────────────────────

  /// Parseia p:timing e retorna lista de steps de animação.
  /// Cada step é uma lista de shapeIds que aparecem naquele clique.
  /// Steps[0] = elementos já visíveis no início (sem animação ou autoStart).
  /// Parseia p:timing e retorna lista de steps de animação indexada por clique.
  /// Índice 0 = primeiro clique, índice 1 = segundo clique, etc.
  List<List<int>> _parseTiming(XmlElement slideRoot) {
    final timing = slideRoot.deep('timing');
    if (timing == null) return [];

    // Encontra a seq principal (mainSeq)
    final seq = timing.deep('seq');
    if (seq == null) return [];

    final seqChildren = seq.child('cTn')?.child('childTnLst');
    if (seqChildren == null) return [];

    final clickSteps = <List<int>>[];

    for (final clickPar in seqChildren.children.whereType<XmlElement>()) {
      // Cada p:par no mainSeq = um grupo de clique.
      // No OOXML gerado pelo PowerPoint, o gatilho é:
      //   delay="indefinite" → aguarda avanço da seq (via clique no modo slideshow)
      //   evt="onClick"      → variante alternativa (alguns geradores)
      // Aceita qualquer uma das formas.
      final cond = clickPar.child('cTn')?.child('stCondLst')?.child('cond');
      final delay = cond?.attr('delay');
      final evt = cond?.attr('evt');
      final isClickTriggered = (delay == 'indefinite') || (evt == 'onClick');
      if (!isClickTriggered) continue;

      // Coleta todos os spTgt (shape targets) dentro deste grupo, inclusive aninhados
      final spIds = <int>{};
      for (final spTgt in clickPar.deepAll('spTgt')) {
        final id = int.tryParse(spTgt.attr('spid') ?? '');
        if (id != null) spIds.add(id);
      }
      if (spIds.isNotEmpty) {
        clickSteps.add(spIds.toList());
      }
    }

    return clickSteps;
  }

  /// Retorna cópia do elemento com shapeId = 0 para elementos de master/layout.
  SlideElement _zeroShapeId(SlideElement el) => _withShapeId(el, 0);

  /// Retorna cópia do elemento com o shapeId especificado.
  SlideElement _withShapeId(SlideElement el, int id) {
    if (el.shapeId == id) return el;
    switch (el) {
      case ShapeElement():
        return ShapeElement(
          xEmu: el.xEmu,
          yEmu: el.yEmu,
          cxEmu: el.cxEmu,
          cyEmu: el.cyEmu,
          zOrder: el.zOrder,
          rotationDeg: el.rotationDeg,
          shapeId: id,
          commandText: el.commandText,
          presetGeometry: el.presetGeometry,
          fill: el.fill,
          outline: el.outline,
          paragraphs: el.paragraphs,
          bodyProps: el.bodyProps,
          adjValue: el.adjValue,
          altText: el.altText,
          placeholderType: el.placeholderType,
        );
      case ImageElement():
        return ImageElement(
          xEmu: el.xEmu,
          yEmu: el.yEmu,
          cxEmu: el.cxEmu,
          cyEmu: el.cyEmu,
          zOrder: el.zOrder,
          rotationDeg: el.rotationDeg,
          shapeId: id,
          commandText: el.commandText,
          imageBytes: el.imageBytes,
          mimeType: el.mimeType,
          altText: el.altText,
        );
      case TableElement():
        return TableElement(
          xEmu: el.xEmu,
          yEmu: el.yEmu,
          cxEmu: el.cxEmu,
          cyEmu: el.cyEmu,
          zOrder: el.zOrder,
          shapeId: id,
          commandText: el.commandText,
          rows: el.rows,
          colWidthsEmu: el.colWidthsEmu,
        );
    }
  }

  SlideElement _withCommandText(SlideElement el, String? commandText) {
    final merged = _mergeCommandText(el.commandText, commandText);
    if (merged == el.commandText) return el;
    switch (el) {
      case ShapeElement():
        return ShapeElement(
          xEmu: el.xEmu,
          yEmu: el.yEmu,
          cxEmu: el.cxEmu,
          cyEmu: el.cyEmu,
          zOrder: el.zOrder,
          rotationDeg: el.rotationDeg,
          shapeId: el.shapeId,
          commandText: merged,
          presetGeometry: el.presetGeometry,
          fill: el.fill,
          outline: el.outline,
          paragraphs: el.paragraphs,
          bodyProps: el.bodyProps,
          adjValue: el.adjValue,
          altText: el.altText,
          placeholderType: el.placeholderType,
        );
      case ImageElement():
        return ImageElement(
          xEmu: el.xEmu,
          yEmu: el.yEmu,
          cxEmu: el.cxEmu,
          cyEmu: el.cyEmu,
          zOrder: el.zOrder,
          rotationDeg: el.rotationDeg,
          shapeId: el.shapeId,
          commandText: merged,
          imageBytes: el.imageBytes,
          mimeType: el.mimeType,
          altText: el.altText,
        );
      case TableElement():
        return TableElement(
          xEmu: el.xEmu,
          yEmu: el.yEmu,
          cxEmu: el.cxEmu,
          cyEmu: el.cyEmu,
          zOrder: el.zOrder,
          shapeId: el.shapeId,
          commandText: merged,
          rows: el.rows,
          colWidthsEmu: el.colWidthsEmu,
        );
    }
  }

  String? _mergeCommandText(String? current, String? incoming) {
    final a = current?.trim();
    final b = incoming?.trim();
    if (b == null || b.isEmpty) return a;
    if (a == null || a.isEmpty) return b;
    if (a.contains(b)) return a;
    if (b.contains(a)) return b;
    return '$a $b';
  }

  // ── Corpo de texto ────────────────────────────────────────────────────────

  List<TextParagraph> _parseTxBody(
    XmlElement txBody,
    ColorResolver cr, {
    _ResolvedTextDefaults? defaults,
  }) {
    return txBody
        .children_('p')
        .map((p) => _parseParagraph(p, cr, defaults: defaults))
        .toList();
  }

  TextParagraph _parseParagraph(
    XmlElement p,
    ColorResolver cr, {
    _ResolvedTextDefaults? defaults,
  }) {
    final pPr = p.child('pPr');
    final level = int.tryParse(pPr?.attr('lvl') ?? '') ?? 0;
    final inheritedPPr = defaults?.paragraphByLevel[level];
    final props = _parsePPr(pPr, cr, inherit: inheritedPPr);
    final inheritedRun = defaults?.runByLevel[level];
    final paraRun = _parseRPr(pPr?.child('defRPr'), cr, inherit: inheritedRun);
    final runs = <TextRun>[];

    for (final child in p.children.whereType<XmlElement>()) {
      switch (child.localName) {
        case 'r':
          final rPr = child.child('rPr');
          final t = child.child('t');
          if (t != null) {
            runs.add(
              TextRun(
                text: t.innerText,
                props: _parseRPr(rPr, cr, inherit: paraRun),
              ),
            );
          }
        case 'br':
          runs.add(TextRun(text: '\n', props: paraRun));
        case 'fld':
          final t = child.child('t');
          if (t != null) {
            runs.add(
              TextRun(
                text: t.innerText,
                props: _parseRPr(child.child('rPr'), cr, inherit: paraRun),
              ),
            );
          }
      }
    }

    // Parágrafos vazios: usar endParaRPr para preservar altura da linha
    // Preservar props do endParaRPr para calcular altura de parágrafos vazios
    RunProperties? endParaProps;
    if (runs.isEmpty) {
      final endParaRPr = p.child('endParaRPr');
      if (endParaRPr != null) {
        endParaProps = _parseRPr(endParaRPr, cr, inherit: paraRun);
      }
    }

    return TextParagraph(runs: runs, props: props, endProps: endParaProps);
  }

  ParagraphProperties _parsePPr(
    XmlElement? pPr,
    ColorResolver cr, {
    ParagraphProperties? inherit,
    int? forcedLevel,
  }) {
    final base = inherit ?? const ParagraphProperties();
    if (pPr == null && forcedLevel == null) return base;

    var alignment = base.alignment;
    switch (pPr?.attr('algn')) {
      case 'ctr':
        alignment = TextAlign.center;
      case 'r':
        alignment = TextAlign.right;
      case 'just':
      case 'dist':
        alignment = TextAlign.justify;
    }

    final lvl =
        forcedLevel ??
        int.tryParse(pPr?.attr('lvl') ?? '${base.level}') ??
        base.level;
    final marL = pPr?.attr('marL') != null
        ? double.tryParse(pPr?.attr('marL') ?? '')
        : base.marLeftEmu;

    final spcBef = pPr?.child('spcBef');
    final spcAft = pPr?.child('spcAft');
    final lnSpc = pPr?.child('lnSpc');

    var spaceBefore = base.spaceBeforePt;
    var spaceBeforePct = base.spaceBeforePct;
    if (spcBef != null) {
      final spcPts = spcBef.child('spcPts');
      final spcPct = spcBef.child('spcPct');
      if (spcPts != null) {
        spaceBefore = (int.tryParse(spcPts.attr('val') ?? '0') ?? 0) / 100.0;
        spaceBeforePct = null;
      } else if (spcPct != null) {
        spaceBefore = null;
        spaceBeforePct =
            (int.tryParse(spcPct.attr('val') ?? '100000') ?? 100000) / 1000.0;
      }
    }

    var spaceAfter = base.spaceAfterPt;
    var spaceAfterPct = base.spaceAfterPct;
    if (spcAft != null) {
      final spcPts = spcAft.child('spcPts');
      final spcPct = spcAft.child('spcPct');
      if (spcPts != null) {
        spaceAfter = (int.tryParse(spcPts.attr('val') ?? '0') ?? 0) / 100.0;
        spaceAfterPct = null;
      } else if (spcPct != null) {
        spaceAfter = null;
        spaceAfterPct =
            (int.tryParse(spcPct.attr('val') ?? '100000') ?? 100000) / 1000.0;
      }
    }

    var lineSpacingPct = base.lineSpacingPct;
    var lineSpacingPt = base.lineSpacingPt;
    if (lnSpc != null) {
      final spcPct = lnSpc.child('spcPct');
      final spcPts = lnSpc.child('spcPts');
      if (spcPct != null) {
        lineSpacingPct =
            (int.tryParse(spcPct.attr('val') ?? '100000') ?? 100000) / 1000.0;
        lineSpacingPt = null;
      } else if (spcPts != null) {
        lineSpacingPt = (int.tryParse(spcPts.attr('val') ?? '0') ?? 0) / 100.0;
        lineSpacingPct = null;
      }
    }

    var bullet = base.bullet;
    final buChar = pPr?.child('buChar');
    final buNone = pPr?.child('buNone');
    final buAutoNum = pPr?.child('buAutoNum');
    final buClrTx = pPr?.child('buClr');
    Color? bulletColor;
    if (buClrTx != null) bulletColor = cr.resolveColorElement(buClrTx);

    if (buNone != null) {
      bullet = null;
    } else {
      if (buChar != null) {
        bullet = BulletSpec(
          char: buChar.attr('char') ?? '•',
          color: bulletColor ?? bullet?.color,
        );
      } else if (buAutoNum != null) {
        bullet = BulletSpec(
          isAutoNum: true,
          color: bulletColor ?? bullet?.color,
        );
      } else if (bulletColor != null && bullet != null) {
        bullet = BulletSpec(
          char: bullet.char,
          isAutoNum: bullet.isAutoNum,
          color: bulletColor,
          sizePct: bullet.sizePct,
        );
      }
    }

    return ParagraphProperties(
      alignment: alignment,
      spaceBeforePt: spaceBefore,
      spaceBeforePct: spaceBeforePct,
      spaceAfterPt: spaceAfter,
      spaceAfterPct: spaceAfterPct,
      lineSpacingPct: lineSpacingPct,
      lineSpacingPt: lineSpacingPt,
      marLeftEmu: marL,
      level: lvl,
      bullet: bullet,
    );
  }

  RunProperties _parseRPr(
    XmlElement? rPr,
    ColorResolver cr, {
    RunProperties? inherit,
  }) {
    final base = inherit ?? const RunProperties();
    if (rPr == null) return base;

    final szAttr = rPr.attr('sz');
    final parsedSize = szAttr != null
        ? (int.tryParse(szAttr) ?? 0) / 100.0
        : null;
    final fontSizePt = (parsedSize == 0 ? null : parsedSize) ?? base.fontSizePt;

    final spcAttr = rPr.attr('spc');
    final parsedSpc = spcAttr == null
        ? null
        : (int.tryParse(spcAttr) ?? 0) / 100.0;
    final letterSpacingPt = parsedSpc ?? base.letterSpacingPt;

    final baselineAttr = rPr.attr('baseline');
    final parsedBaseline = baselineAttr == null
        ? null
        : (int.tryParse(baselineAttr) ?? 0) / 1000.0;
    final baselinePct = parsedBaseline ?? base.baselinePct;

    final kernAttr = rPr.attr('kern');
    final parsedKern = kernAttr == null
        ? null
        : (int.tryParse(kernAttr) ?? 0) / 100.0;
    final kerningPt = parsedKern ?? base.kerningPt;

    var capsType = base.capsType;
    final capVal = rPr.attr('cap');
    if (capVal != null) {
      capsType = capVal;
    }

    var bold = base.bold;
    final bVal = rPr.attr('b');
    if (bVal != null) bold = bVal == '1' || bVal == 'true';

    var italic = base.italic;
    final iVal = rPr.attr('i');
    if (iVal != null) italic = iVal == '1' || iVal == 'true';

    var underline = base.underline;
    var underlineStyle = base.underlineStyle;
    var underlineColor = base.underlineColor;
    final uVal = rPr.attr('u');
    if (uVal != null) {
      underline = uVal != 'none';
      underlineStyle = uVal;
    }

    final uFill = rPr.child('uFill');
    if (uFill != null) {
      final solidFill = uFill.child('solidFill');
      if (solidFill != null) {
        underlineColor = cr.resolveColorElement(solidFill) ?? underlineColor;
      }
    } else {
      final uLn = rPr.child('uLn');
      if (uLn != null) {
        final solidFill = uLn.child('solidFill');
        if (solidFill != null) {
          underlineColor = cr.resolveColorElement(solidFill) ?? underlineColor;
        }
      }
    }

    var strike = base.strikethrough;
    var doubleStrike = base.doubleStrikethrough;
    final strikeVal = rPr.attr('strike');
    if (strikeVal != null) {
      strike = strikeVal != 'noStrike';
      doubleStrike = strikeVal == 'dblStrike';
    }

    var color = base.color;
    final solidFill = rPr.child('solidFill');
    if (solidFill != null) {
      color = cr.resolveColorElement(solidFill) ?? color;
    }

    var fontFamily = base.fontFamily;
    final latin = rPr.child('latin');
    final ea = rPr.child('ea');
    final typeface = latin?.attr('typeface') ?? ea?.attr('typeface');
    if (typeface != null && typeface.isNotEmpty) fontFamily = typeface;

    return RunProperties(
      fontSizePt: fontSizePt,
      letterSpacingPt: letterSpacingPt,
      baselinePct: baselinePct,
      kerningPt: kerningPt,
      capsType: capsType,
      bold: bold,
      italic: italic,
      underline: underline,
      underlineStyle: underlineStyle,
      underlineColor: underlineColor,
      strikethrough: strike,
      doubleStrikethrough: doubleStrike,
      color: color,
      fontFamily: fontFamily,
      isPlaceholder: inherit != null,
    );
  }

  _ResolvedTextDefaults _resolveTextDefaults(
    XmlElement txBody, {
    required String? placeholderType,
    required String? placeholderIdx,
    required _TextStyleContext? context,
  }) {
    final cr = context?.colorResolver;
    final paragraphByLevel = <int, ParagraphProperties>{
      for (var i = 0; i < 9; i++) i: ParagraphProperties(level: i),
    };
    final runByLevel = <int, RunProperties>{
      for (var i = 0; i < 9; i++) i: const RunProperties(),
    };

    void applyPPr(XmlElement pPr, ColorResolver resolver, {int? level}) {
      final resolvedLevel = (level ?? _levelFromPPrTag(pPr.localName) ?? 0)
          .clamp(0, 8)
          .toInt();
      paragraphByLevel[resolvedLevel] = _parsePPr(
        pPr,
        resolver,
        inherit: paragraphByLevel[resolvedLevel],
        forcedLevel: resolvedLevel,
      );
      runByLevel[resolvedLevel] = _parseRPr(
        pPr.child('defRPr'),
        resolver,
        inherit: runByLevel[resolvedLevel],
      );
    }

    void applyLstStyle(XmlElement? lstStyle, ColorResolver resolver) {
      if (lstStyle == null) return;
      final defPPr = lstStyle.child('defPPr');
      if (defPPr != null) applyPPr(defPPr, resolver, level: 0);

      for (final child in lstStyle.children.whereType<XmlElement>()) {
        if (!child.localName.endsWith('pPr')) continue;
        final level = _levelFromPPrTag(child.localName);
        if (level != null) applyPPr(child, resolver, level: level);
      }
    }

    void applyPlaceholderShape(XmlElement? shape, ColorResolver resolver) {
      if (shape == null) return;
      final tx = shape.child('txBody');
      if (tx == null) return;
      applyLstStyle(tx.child('lstStyle'), resolver);
      for (final p in tx.children_('p')) {
        final pPr = p.child('pPr');
        if (pPr == null) continue;
        final level = int.tryParse(pPr.attr('lvl') ?? '0') ?? 0;
        applyPPr(pPr, resolver, level: level);
      }
    }

    if (context != null && cr != null) {
      final txStyles = context.masterTxStyles;
      if (txStyles != null) {
        final styleNode = _pickMasterStyleNode(txStyles, placeholderType);
        if (styleNode != null) {
          applyLstStyle(styleNode, cr);
        }
      }

      final masterPlaceholder = _findPlaceholderShape(
        context.masterSpTree,
        placeholderType: placeholderType,
        placeholderIdx: placeholderIdx,
      );
      applyPlaceholderShape(masterPlaceholder, cr);

      final layoutPlaceholder = _findPlaceholderShape(
        context.layoutSpTree,
        placeholderType: placeholderType,
        placeholderIdx: placeholderIdx,
      );
      applyPlaceholderShape(layoutPlaceholder, cr);

      applyLstStyle(txBody.child('lstStyle'), cr);
    }

    final localResolver = cr ?? (context?.colorResolver);
    if (localResolver != null) {
      for (final p in txBody.children_('p')) {
        final pPr = p.child('pPr');
        if (pPr == null) continue;
        final level = int.tryParse(pPr.attr('lvl') ?? '0') ?? 0;
        applyPPr(pPr, localResolver, level: level);
      }
    }

    return _ResolvedTextDefaults(
      paragraphByLevel: paragraphByLevel,
      runByLevel: runByLevel,
    );
  }

  int? _levelFromPPrTag(String localName) {
    final m = RegExp(r'^lvl(\d+)pPr$').firstMatch(localName);
    if (m == null) return null;
    final oneBased = int.tryParse(m.group(1) ?? '');
    if (oneBased == null) return null;
    return (oneBased - 1).clamp(0, 8);
  }

  XmlElement? _pickMasterStyleNode(
    XmlElement txStyles,
    String? placeholderType,
  ) {
    final type = (placeholderType ?? '').toLowerCase();
    if (type == 'title' || type == 'ctrtitle') {
      return txStyles.child('titleStyle') ?? txStyles.child('otherStyle');
    }
    if (type == 'subtitle' || type == 'body' || type == 'obj') {
      return txStyles.child('bodyStyle') ?? txStyles.child('otherStyle');
    }
    return txStyles.child('otherStyle') ?? txStyles.child('bodyStyle');
  }

  XmlElement? _findPlaceholderShape(
    XmlElement? spTree, {
    required String? placeholderType,
    required String? placeholderIdx,
  }) {
    if (spTree == null) return null;
    XmlElement? byType;

    for (final sp in spTree.children_('sp')) {
      final ph = sp.child('nvSpPr')?.child('nvPr')?.child('ph');
      if (ph == null) continue;
      final idx = ph.attr('idx') ?? '0';
      final type = (ph.attr('type') ?? '').toLowerCase();
      if ((placeholderIdx ?? '').isNotEmpty && idx == placeholderIdx) {
        return sp;
      }
      if ((placeholderType ?? '').toLowerCase() == type && byType == null) {
        byType = sp;
      }
    }
    return byType;
  }

  TextBodyProperties _resolveBodyProps(
    XmlElement? localBodyPr, {
    required String? placeholderType,
    required String? placeholderIdx,
    required _TextStyleContext? context,
  }) {
    var resolved = TextBodyProperties.defaults;

    if (context != null) {
      final masterShape = _findPlaceholderShape(
        context.masterSpTree,
        placeholderType: placeholderType,
        placeholderIdx: placeholderIdx,
      );
      resolved = _parseBodyPr(
        masterShape?.child('txBody')?.child('bodyPr'),
        inherit: resolved,
      );

      final layoutShape = _findPlaceholderShape(
        context.layoutSpTree,
        placeholderType: placeholderType,
        placeholderIdx: placeholderIdx,
      );
      resolved = _parseBodyPr(
        layoutShape?.child('txBody')?.child('bodyPr'),
        inherit: resolved,
      );
    }

    resolved = _parseBodyPr(localBodyPr, inherit: resolved);
    return resolved;
  }

  TextBodyProperties _parseBodyPr(
    XmlElement? bodyPr, {
    TextBodyProperties? inherit,
  }) {
    final base = inherit ?? TextBodyProperties.defaults;
    if (bodyPr == null) return base;

    var vertAlign = base.vertAlign;
    final anchor = bodyPr.attr('anchor');
    if (anchor != null) {
      switch (anchor) {
        case 'ctr':
          vertAlign = VerticalAlignment.middle;
        case 'b':
          vertAlign = VerticalAlignment.bottom;
        default:
          vertAlign = VerticalAlignment.top;
      }
    }

    final wrap = bodyPr.attr('wrap');
    final wordWrap = wrap == null ? base.wordWrap : wrap != 'none';

    final insetLeft = bodyPr.attr('lIns') != null
        ? (double.tryParse(bodyPr.attr('lIns') ?? '') ?? base.insetLeftEmu)
        : base.insetLeftEmu;
    final insetRight = bodyPr.attr('rIns') != null
        ? (double.tryParse(bodyPr.attr('rIns') ?? '') ?? base.insetRightEmu)
        : base.insetRightEmu;
    final insetTop = bodyPr.attr('tIns') != null
        ? (double.tryParse(bodyPr.attr('tIns') ?? '') ?? base.insetTopEmu)
        : base.insetTopEmu;
    final insetBottom = bodyPr.attr('bIns') != null
        ? (double.tryParse(bodyPr.attr('bIns') ?? '') ?? base.insetBottomEmu)
        : base.insetBottomEmu;

    var fontScale = base.fontScale;
    var lineSpaceReduction = base.lineSpaceReduction;
    final normAutofit = bodyPr.child('normAutofit');
    if (normAutofit != null) {
      final fs = int.tryParse(normAutofit.attr('fontScale') ?? '');
      if (fs != null) fontScale = fs / 100000.0;
      final lsr = int.tryParse(normAutofit.attr('lnSpcReduction') ?? '');
      if (lsr != null) lineSpaceReduction = lsr / 100000.0;
    }

    return TextBodyProperties(
      vertAlign: vertAlign,
      wordWrap: wordWrap,
      insetLeftEmu: insetLeft,
      insetRightEmu: insetRight,
      insetTopEmu: insetTop,
      insetBottomEmu: insetBottom,
      fontScale: fontScale,
      lineSpaceReduction: lineSpaceReduction,
    );
  }
}

class _TextStyleContext {
  final ColorResolver colorResolver;
  final XmlElement? masterTxStyles;
  final XmlElement? masterSpTree;
  final XmlElement? layoutSpTree;

  const _TextStyleContext({
    required this.colorResolver,
    this.masterTxStyles,
    this.masterSpTree,
    this.layoutSpTree,
  });
}

class _ResolvedTextDefaults {
  final Map<int, ParagraphProperties> paragraphByLevel;
  final Map<int, RunProperties> runByLevel;

  const _ResolvedTextDefaults({
    required this.paragraphByLevel,
    required this.runByLevel,
  });
}
