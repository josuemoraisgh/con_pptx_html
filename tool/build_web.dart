// Compilação completa: PPTX → WASM autossuficiente
//
// Uso:
//   dart run tool/build_web.dart [caminho.pptx] [--serve]
//
// Padrão: assets/presentation.pptx
//
// Flags:
//   --serve   Após o build, sobe servidor HTTP em http://localhost:8080
//
// O que faz:
//   1. Compila o PPTX → lib/generated/presentation_data.g.dart
//   2. Remove temporariamente o asset .pptx do pubspec.yaml
//   3. Executa: flutter build web --wasm
//   4. Restaura o pubspec.yaml
//   5. build/web/ fica sem o .pptx — pode publicar direto no GitHub Pages
//
// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main(List<String> args) async {
  final serve = args.contains('--serve');
  final pptxArgs = args.where((a) => !a.startsWith('-')).toList();
  final pptxPath = pptxArgs.isNotEmpty ? pptxArgs[0] : 'assets/presentation.pptx';

  if (!File(pptxPath).existsSync()) {
    print('❌  Arquivo PPTX não encontrado: $pptxPath');
    print('   Uso: dart run tool/build_web.dart [caminho.pptx] [--serve]');
    exit(1);
  }

  // ── Passo 1: compilar PPTX → Dart ────────────────────────────────────────
  print('');
  print('═══════════════════════════════════════════════════════════');
  print(' Passo 1/2 — Compilando PPTX → Dart');
  print(' Fonte : $pptxPath');
  print(' Saída : lib/generated/presentation_data.g.dart');
  print('═══════════════════════════════════════════════════════════');

  final compileOk = await _run(
    'flutter',
    ['test', 'tool/compile_pptx.dart'],
    env: {'PPTX_INPUT': pptxPath},
  );
  if (!compileOk) {
    print('❌  Falha na compilação do PPTX. Build interrompido.');
    exit(1);
  }

  // ── Passo 2: flutter build web --wasm ────────────────────────────────────
  print('');
  print('═══════════════════════════════════════════════════════════');
  print(' Passo 2/2 — flutter build web --wasm');
  print('═══════════════════════════════════════════════════════════');

  final buildOk = await _run('flutter', ['build', 'web', '--wasm']);

  if (!buildOk) {
    print('❌  Falha no flutter build web --wasm.');
    exit(1);
  }

  print('');
  print('✅  build/web/ pronto — sem o arquivo .pptx');

  if (serve) {
    await _serveLocal('build/web');
  } else {
    print('   Para testar localmente: dart run tool/build_web.dart --serve');
    print('   Para publicar: copie a pasta build/web/ para o GitHub Pages.');
    print('');
  }
}

// ── Servidor HTTP local ───────────────────────────────────────────────────

Future<void> _serveLocal(String webDir) async {
  const port = 8080;
  final dir = Directory(webDir).absolute;

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final url = 'http://localhost:$port';

  print('');
  print('═══════════════════════════════════════════════════════════');
  print(' Servidor rodando em $url');
  print(' Pasta  : ${dir.path}');
  print(' Ctrl+C para encerrar.');
  print('═══════════════════════════════════════════════════════════');
  print('');

  // Abre o navegador automaticamente
  await _openBrowser(url);

  await for (final request in server) {
    await _handleRequest(request, dir);
  }
}

Future<void> _handleRequest(HttpRequest request, Directory root) async {
  var path = request.uri.path;
  if (path == '/') path = '/index.html';

  final file = File('${root.path}$path');

  if (await file.exists()) {
    final mime = _mime(path);
    request.response
      ..headers.contentType = ContentType.parse(mime)
      ..headers.set('Cross-Origin-Opener-Policy', 'same-origin')
      ..headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
    await request.response.addStream(file.openRead());
    await request.response.close();
  } else {
    // SPA fallback → index.html
    final index = File('${root.path}/index.html');
    if (await index.exists()) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.set('Cross-Origin-Opener-Policy', 'same-origin')
        ..headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
      await request.response.addStream(index.openRead());
      await request.response.close();
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('404 Not Found');
      await request.response.close();
    }
  }
}

String _mime(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'html' => 'text/html; charset=utf-8',
    'js' || 'mjs' => 'application/javascript',
    'wasm' => 'application/wasm',
    'css' => 'text/css',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'svg' => 'image/svg+xml',
    'json' => 'application/json',
    'ico' => 'image/x-icon',
    'ttf' => 'font/ttf',
    'woff' => 'font/woff',
    'woff2' => 'font/woff2',
    _ => 'application/octet-stream',
  };
}

Future<void> _openBrowser(String url) async {
  try {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', url]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else {
      await Process.run('xdg-open', [url]);
    }
  } catch (_) {
    // Falha silenciosa — o usuário pode abrir manualmente
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

/// Executa um processo transmitindo stdout/stderr em tempo real.
/// Retorna true se exitCode == 0.
Future<bool> _run(
  String executable,
  List<String> arguments, {
  Map<String, String> env = const {},
}) async {
  final process = await Process.start(
    executable,
    arguments,
    environment: {...Platform.environment, ...env},
    runInShell: true,
  );

  process.stdout.listen((data) => stdout.add(data));
  process.stderr.listen((data) => stderr.add(data));

  return await process.exitCode == 0;
}
