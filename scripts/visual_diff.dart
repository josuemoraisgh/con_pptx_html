import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) async {
  final options = _parseArgs(args);
  if (options.showHelp) {
    _printHelp();
    exit(0);
  }

  if (options.actualDir == null || options.referenceDir == null) {
    stderr.writeln('Erro: use --actual-dir e --reference-dir.');
    _printHelp();
    exit(2);
  }

  final actualDir = Directory(options.actualDir!);
  final referenceDir = Directory(options.referenceDir!);

  if (!actualDir.existsSync()) {
    stderr.writeln(
      'Erro: pasta de render atual nao encontrada: ${actualDir.path}',
    );
    exit(2);
  }
  if (!referenceDir.existsSync()) {
    stderr.writeln(
      'Erro: pasta de referencia nao encontrada: ${referenceDir.path}',
    );
    exit(2);
  }

  final outRoot = Directory(options.outputDir);
  outRoot.createSync(recursive: true);
  final outMasks = Directory('${outRoot.path}${Platform.pathSeparator}masks')
    ..createSync(recursive: true);
  final outOverlays = Directory(
    '${outRoot.path}${Platform.pathSeparator}overlays',
  )..createSync(recursive: true);

  final actualFiles = _listImageFiles(actualDir);
  final referenceFiles = _listImageFiles(referenceDir);
  final pairing = _pairSlides(actualFiles, referenceFiles);

  if (pairing.matches.isEmpty) {
    stderr.writeln(
      'Erro: nenhum slide pareado. Use nomes iguais ou numeros de slide no nome.',
    );
    exit(2);
  }

  final maxSlides = options.maxSlides;
  final pairs = maxSlides == null
      ? pairing.matches
      : pairing.matches.take(maxSlides).toList();

  final slideReports = <Map<String, dynamic>>[];
  var totalPixels = 0;
  var totalDiffPixels = 0;
  var totalMae = 0.0;

  for (final pair in pairs) {
    final refImage = _decode(pair.reference.path);
    final actualRaw = _decode(pair.actual.path);

    if (refImage == null || actualRaw == null) {
      stderr.writeln(
        'Aviso: nao foi possivel decodificar ${pair.reference.path} ou ${pair.actual.path}',
      );
      continue;
    }

    // Normaliza: downscale da referência para tamanho do actual
    final img.Image actualImage = actualRaw;
    final img.Image refNorm =
        (actualRaw.width == refImage.width &&
            actualRaw.height == refImage.height)
        ? refImage
        : img.copyResize(
            refImage,
            width: actualRaw.width,
            height: actualRaw.height,
            interpolation: img.Interpolation.average,
          );

    final result = _compareImages(
      reference: refNorm,
      actual: actualImage,
      threshold: options.pixelThreshold,
      minAreaPixels: options.minAreaPixels,
    );

    final maskName = '${pair.id}_mask.png';
    final overlayName = '${pair.id}_overlay.png';
    final maskPath = '${outMasks.path}${Platform.pathSeparator}$maskName';
    final overlayPath =
        '${outOverlays.path}${Platform.pathSeparator}$overlayName';

    File(maskPath).writeAsBytesSync(img.encodePng(result.mask));
    File(overlayPath).writeAsBytesSync(img.encodePng(result.overlay));

    totalPixels += result.totalPixels;
    totalDiffPixels += result.diffPixels;
    totalMae += result.meanAbsError;

    slideReports.add({
      'slideId': pair.id,
      'referenceFile': pair.reference.path,
      'actualFile': pair.actual.path,
      'referenceWidth': refImage.width,
      'referenceHeight': refImage.height,
      'diffPixels': result.diffPixels,
      'totalPixels': result.totalPixels,
      'mismatchPercent': _pct(result.diffPixels, result.totalPixels),
      'meanAbsError': result.meanAbsError,
      'maskFile': maskPath,
      'overlayFile': overlayPath,
      'areas': result.areas
          .map(
            (a) => {
              'x': a.x,
              'y': a.y,
              'width': a.width,
              'height': a.height,
              'pixelCount': a.pixelCount,
              'coverPercent': _pct(a.pixelCount, result.totalPixels),
            },
          )
          .toList(),
    });
  }

  slideReports.sort((a, b) {
    final av = a['mismatchPercent'] as double;
    final bv = b['mismatchPercent'] as double;
    return bv.compareTo(av);
  });

  final summary = {
    'slidesCompared': slideReports.length,
    'slidesUnmatchedReference': pairing.missingActual
        .map((f) => f.path)
        .toList(),
    'slidesUnmatchedActual': pairing.missingReference
        .map((f) => f.path)
        .toList(),
    'globalMismatchPercent': _pct(totalDiffPixels, totalPixels),
    'globalMeanAbsError': slideReports.isEmpty
        ? 0.0
        : totalMae / slideReports.length,
    'threshold': options.pixelThreshold,
    'minAreaPixels': options.minAreaPixels,
  };

  final jsonReport = {'summary': summary, 'slides': slideReports};

  final jsonPath = '${outRoot.path}${Platform.pathSeparator}report.json';
  final mdPath = '${outRoot.path}${Platform.pathSeparator}report.md';

  File(
    jsonPath,
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonReport));
  File(mdPath).writeAsStringSync(_toMarkdownReport(summary, slideReports));

  stdout.writeln('Comparacao concluida.');
  stdout.writeln('Relatorio JSON: $jsonPath');
  stdout.writeln('Relatorio MD:   $mdPath');
  stdout.writeln('Mascara diff:   ${outMasks.path}');
  stdout.writeln('Overlay diff:   ${outOverlays.path}');
}

class _Options {
  final String? actualDir;
  final String? referenceDir;
  final String outputDir;
  final int pixelThreshold;
  final int minAreaPixels;
  final int? maxSlides;
  final bool showHelp;

  const _Options({
    required this.actualDir,
    required this.referenceDir,
    required this.outputDir,
    required this.pixelThreshold,
    required this.minAreaPixels,
    required this.maxSlides,
    required this.showHelp,
  });
}

_Options _parseArgs(List<String> args) {
  String? actualDir;
  String? referenceDir;
  var outputDir = 'visual_diff';
  var threshold = 24;
  var minAreaPixels = 30;
  int? maxSlides;
  var showHelp = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '-h' || a == '--help') {
      showHelp = true;
      continue;
    }

    if (a.startsWith('--')) {
      String key;
      String? value;
      if (a.contains('=')) {
        final parts = a.split('=');
        key = parts.first;
        value = parts.sublist(1).join('=');
      } else {
        key = a;
        if (i + 1 < args.length) {
          value = args[i + 1];
          i++;
        }
      }

      switch (key) {
        case '--actual-dir':
          actualDir = value;
        case '--reference-dir':
          referenceDir = value;
        case '--output-dir':
          if (value != null && value.isNotEmpty) outputDir = value;
        case '--threshold':
          final parsed = int.tryParse(value ?? '');
          if (parsed != null) threshold = parsed;
        case '--min-area':
          final parsed = int.tryParse(value ?? '');
          if (parsed != null) minAreaPixels = parsed;
        case '--max-slides':
          maxSlides = int.tryParse(value ?? '');
      }
    }
  }

  return _Options(
    actualDir: actualDir,
    referenceDir: referenceDir,
    outputDir: outputDir,
    pixelThreshold: threshold.clamp(0, 255),
    minAreaPixels: minAreaPixels < 1 ? 1 : minAreaPixels,
    maxSlides: maxSlides,
    showHelp: showHelp,
  );
}

void _printHelp() {
  stdout.writeln('''
Comparacao visual slide a slide (render atual vs referencia)

Uso:
  dart run scripts/visual_diff.dart
    --actual-dir <pasta_render_atual>
    --reference-dir <pasta_referencia>
    [--output-dir visual_diff]
    [--threshold 24]
    [--min-area 30]
    [--max-slides 20]

Pareamento de slides:
  1) Mesmo nome de arquivo (case-insensitive), ou
  2) Mesmo numero no nome (ex.: slide_001.png <-> ref_1.png)

Saida:
  - report.json (metricas completas)
  - report.md (resumo legivel)
  - masks/*.png (mascara binaria da diferenca)
  - overlays/*.png (diff em vermelho sobre referencia)
''');
}

class _PairedSlide {
  final String id;
  final File actual;
  final File reference;

  const _PairedSlide({
    required this.id,
    required this.actual,
    required this.reference,
  });
}

class _PairingResult {
  final List<_PairedSlide> matches;
  final List<File> missingActual;
  final List<File> missingReference;

  const _PairingResult({
    required this.matches,
    required this.missingActual,
    required this.missingReference,
  });
}

_PairingResult _pairSlides(List<File> actual, List<File> reference) {
  final actualByName = <String, File>{
    for (final f in actual) _baseName(f.path).toLowerCase(): f,
  };

  final actualUsed = <String>{};
  final refUsed = <String>{};
  final matches = <_PairedSlide>[];

  for (final ref in reference) {
    final refName = _baseName(ref.path).toLowerCase();
    final sameName = actualByName[refName];
    if (sameName != null) {
      matches.add(
        _PairedSlide(
          id: _buildSlideId(ref.path, sameName.path),
          actual: sameName,
          reference: ref,
        ),
      );
      actualUsed.add(sameName.path);
      refUsed.add(ref.path);
    }
  }

  final actualByIndex = <int, File>{};
  for (final f in actual) {
    if (actualUsed.contains(f.path)) continue;
    final idx = _extractIndex(_baseName(f.path));
    if (idx != null) actualByIndex[idx] = f;
  }

  for (final ref in reference) {
    if (refUsed.contains(ref.path)) continue;
    final idx = _extractIndex(_baseName(ref.path));
    if (idx == null) continue;
    final candidate = actualByIndex[idx];
    if (candidate == null) continue;
    if (actualUsed.contains(candidate.path)) continue;

    matches.add(
      _PairedSlide(
        id: 'slide_${idx.toString().padLeft(3, '0')}',
        actual: candidate,
        reference: ref,
      ),
    );
    actualUsed.add(candidate.path);
    refUsed.add(ref.path);
  }

  matches.sort((a, b) => a.id.compareTo(b.id));

  final missingActual =
      reference.where((f) => !refUsed.contains(f.path)).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final missingReference =
      actual.where((f) => !actualUsed.contains(f.path)).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return _PairingResult(
    matches: matches,
    missingActual: missingActual,
    missingReference: missingReference,
  );
}

List<File> _listImageFiles(Directory dir) {
  final out = <File>[];
  final allowed = {'.png', '.jpg', '.jpeg', '.webp'};

  for (final e in dir.listSync(recursive: true)) {
    if (e is! File) continue;
    final ext = _extension(e.path).toLowerCase();
    if (allowed.contains(ext)) out.add(e);
  }

  out.sort((a, b) => a.path.compareTo(b.path));
  return out;
}

img.Image? _decode(String path) {
  final bytes = File(path).readAsBytesSync();
  return img.decodeImage(bytes);
}

class _CompareResult {
  final int totalPixels;
  final int diffPixels;
  final double meanAbsError;
  final img.Image mask;
  final img.Image overlay;
  final List<_DiffArea> areas;

  const _CompareResult({
    required this.totalPixels,
    required this.diffPixels,
    required this.meanAbsError,
    required this.mask,
    required this.overlay,
    required this.areas,
  });
}

class _DiffArea {
  final int x;
  final int y;
  final int width;
  final int height;
  final int pixelCount;

  const _DiffArea({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pixelCount,
  });
}

_CompareResult _compareImages({
  required img.Image reference,
  required img.Image actual,
  required int threshold,
  required int minAreaPixels,
}) {
  final w = reference.width;
  final h = reference.height;
  final total = w * h;

  final mask = img.Image(width: w, height: h);
  final overlay = img.Image.from(reference);
  final flags = List<bool>.filled(total, false);

  var diffCount = 0;
  var absErrorAcc = 0.0;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final idx = y * w + x;
      final rp = reference.getPixel(x, y);
      final ap = actual.getPixel(x, y);

      final dr = (rp.r.toInt() - ap.r.toInt()).abs();
      final dg = (rp.g.toInt() - ap.g.toInt()).abs();
      final db = (rp.b.toInt() - ap.b.toInt()).abs();
      final delta = ((dr + dg + db) / 3.0);
      absErrorAcc += delta;

      final isDiff = delta >= threshold;
      flags[idx] = isDiff;

      if (isDiff) {
        diffCount++;
        mask.setPixelRgba(x, y, 255, 255, 255, 255);
        overlay.setPixelRgba(
          x,
          y,
          255,
          (overlay.getPixel(x, y).g * 0.3).toInt(),
          (overlay.getPixel(x, y).b * 0.3).toInt(),
          255,
        );
      } else {
        mask.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
  }

  final areas = _connectedAreas(
    flags,
    width: w,
    height: h,
    minAreaPixels: minAreaPixels,
  );

  for (final a in areas) {
    _drawRect(overlay, a.x, a.y, a.width, a.height, 255, 255, 0);
  }

  return _CompareResult(
    totalPixels: total,
    diffPixels: diffCount,
    meanAbsError: total == 0 ? 0 : absErrorAcc / total,
    mask: mask,
    overlay: overlay,
    areas: areas,
  );
}

List<_DiffArea> _connectedAreas(
  List<bool> diffFlags, {
  required int width,
  required int height,
  required int minAreaPixels,
}) {
  final visited = List<bool>.filled(diffFlags.length, false);
  final areas = <_DiffArea>[];

  int offset(int x, int y) => y * width + x;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final start = offset(x, y);
      if (!diffFlags[start] || visited[start]) continue;

      var minX = x;
      var maxX = x;
      var minY = y;
      var maxY = y;
      var pixels = 0;

      final queue = <int>[start];
      visited[start] = true;

      for (var q = 0; q < queue.length; q++) {
        final idx = queue[q];
        final cx = idx % width;
        final cy = idx ~/ width;
        pixels++;

        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
        if (cy < minY) minY = cy;
        if (cy > maxY) maxY = cy;

        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = cx + dx;
            final ny = cy + dy;
            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
            final ni = offset(nx, ny);
            if (visited[ni] || !diffFlags[ni]) continue;
            visited[ni] = true;
            queue.add(ni);
          }
        }
      }

      if (pixels >= minAreaPixels) {
        areas.add(
          _DiffArea(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1,
            pixelCount: pixels,
          ),
        );
      }
    }
  }

  areas.sort((a, b) => b.pixelCount.compareTo(a.pixelCount));
  return areas;
}

void _drawRect(
  img.Image image,
  int x,
  int y,
  int width,
  int height,
  int r,
  int g,
  int b,
) {
  final x2 = x + width - 1;
  final y2 = y + height - 1;

  for (var i = x; i <= x2; i++) {
    if (i >= 0 && i < image.width && y >= 0 && y < image.height) {
      image.setPixelRgba(i, y, r, g, b, 255);
    }
    if (i >= 0 && i < image.width && y2 >= 0 && y2 < image.height) {
      image.setPixelRgba(i, y2, r, g, b, 255);
    }
  }

  for (var j = y; j <= y2; j++) {
    if (x >= 0 && x < image.width && j >= 0 && j < image.height) {
      image.setPixelRgba(x, j, r, g, b, 255);
    }
    if (x2 >= 0 && x2 < image.width && j >= 0 && j < image.height) {
      image.setPixelRgba(x2, j, r, g, b, 255);
    }
  }
}

double _pct(int part, int total) {
  if (total == 0) return 0;
  return (part * 100.0) / total;
}

String _toMarkdownReport(
  Map<String, dynamic> summary,
  List<Map<String, dynamic>> slides,
) {
  final b = StringBuffer();
  b.writeln('# Relatorio de Comparacao Visual');
  b.writeln();
  b.writeln('- Slides comparados: ${summary['slidesCompared']}');
  b.writeln(
    '- Mismatch global: ${(summary['globalMismatchPercent'] as double).toStringAsFixed(3)}%',
  );
  b.writeln(
    '- MAE global: ${(summary['globalMeanAbsError'] as double).toStringAsFixed(3)}',
  );
  b.writeln();

  final missingActual = (summary['slidesUnmatchedReference'] as List<dynamic>)
      .cast<String>();
  final missingReference = (summary['slidesUnmatchedActual'] as List<dynamic>)
      .cast<String>();

  if (missingActual.isNotEmpty) {
    b.writeln('## Referencias sem render atual');
    for (final p in missingActual) {
      b.writeln('- $p');
    }
    b.writeln();
  }

  if (missingReference.isNotEmpty) {
    b.writeln('## Renders sem referencia');
    for (final p in missingReference) {
      b.writeln('- $p');
    }
    b.writeln();
  }

  b.writeln('## Slides por severidade');
  b.writeln();
  b.writeln('| Slide | Mismatch % | MAE | Areas (top 3) |');
  b.writeln('|---|---:|---:|---|');

  for (final slide in slides) {
    final areas = (slide['areas'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final top = areas
        .take(3)
        .map((a) {
          return '[x:${a['x']} y:${a['y']} w:${a['width']} h:${a['height']} p:${a['pixelCount']}]';
        })
        .join(' ');

    b.writeln(
      '| ${slide['slideId']} | '
      '${(slide['mismatchPercent'] as double).toStringAsFixed(3)} | '
      '${(slide['meanAbsError'] as double).toStringAsFixed(3)} | '
      '${top.isEmpty ? '-' : top} |',
    );
  }

  b.writeln();
  b.writeln('## Detalhes por slide');
  b.writeln();

  for (final slide in slides) {
    b.writeln('### ${slide['slideId']}');
    b.writeln('- Referencia: ${slide['referenceFile']}');
    b.writeln('- Atual: ${slide['actualFile']}');
    b.writeln(
      '- Mismatch: ${(slide['mismatchPercent'] as double).toStringAsFixed(3)}%',
    );
    b.writeln('- MAE: ${(slide['meanAbsError'] as double).toStringAsFixed(3)}');
    b.writeln('- Mask: ${slide['maskFile']}');
    b.writeln('- Overlay: ${slide['overlayFile']}');

    final areas = (slide['areas'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    if (areas.isEmpty) {
      b.writeln('- Areas de diferenca: nenhuma acima do minimo configurado.');
    } else {
      b.writeln('- Areas de diferenca:');
      for (final a in areas.take(10)) {
        b.writeln(
          '  - x:${a['x']} y:${a['y']} w:${a['width']} h:${a['height']} '
          'pixels:${a['pixelCount']} '
          'cover:${(a['coverPercent'] as double).toStringAsFixed(4)}%',
        );
      }
    }

    b.writeln();
  }

  return b.toString();
}

String _extension(String path) {
  final file = path.replaceAll('\\', '/').split('/').last;
  final i = file.lastIndexOf('.');
  return i == -1 ? '' : file.substring(i).toLowerCase();
}

String _baseName(String path) {
  final file = path.replaceAll('\\', '/').split('/').last;
  final i = file.lastIndexOf('.');
  return i == -1 ? file : file.substring(0, i);
}

int? _extractIndex(String name) {
  final m = RegExp(r'(\d+)').firstMatch(name);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

String _buildSlideId(String referencePath, String actualPath) {
  final ri = _extractIndex(_baseName(referencePath));
  final ai = _extractIndex(_baseName(actualPath));
  final idx = ri ?? ai;
  if (idx != null) return 'slide_${idx.toString().padLeft(3, '0')}';
  return _baseName(referencePath);
}
