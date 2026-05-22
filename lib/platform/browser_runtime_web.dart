// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

class AudienceWindowHandle {
  final web.Window _window;

  const AudienceWindowHandle(this._window);

  void close() {
    try {
      _window.close();
    } catch (_) {}
  }
}

class BrowserMessenger {
  late final web.BroadcastChannel _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  BrowserMessenger(String channelName) {
    _channel = web.BroadcastChannel(channelName);
    _channel.onmessage = ((web.MessageEvent event) {
      final raw = event.data.dartify();
      if (raw is! Map) return;

      final message = <String, dynamic>{};
      for (final entry in raw.entries) {
        final key = entry.key;
        if (key is String) message[key] = entry.value;
      }
      if (message.isNotEmpty) _controller.add(message);
    }).toJS;
  }

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void post(Map<String, dynamic> data) {
    try {
      _channel.postMessage(data.jsify()!);
    } catch (_) {}
  }

  void dispose() {
    _channel.close();
    _controller.close();
  }
}

bool get isAudienceView =>
    Uri.tryParse(web.window.location.href)?.queryParameters['view'] ==
    'audience';

bool get hasMultipleScreens {
  try {
    final screen = globalContext['screen'];
    if (screen == null) return false;
    final isExtended = (screen as JSObject)['isExtended'];
    if (isExtended == null || !isExtended.isA<JSBoolean>()) return false;
    return (isExtended as JSBoolean).toDart;
  } catch (_) {
    return false;
  }
}

AudienceWindowHandle? openAudienceWindow() {
  try {
    final current = Uri.parse(web.window.location.href);
    final queryParameters = Map<String, String>.from(current.queryParameters);
    queryParameters['view'] = 'audience';
    final audienceUri = current.replace(queryParameters: queryParameters);

    final screenWidth = web.window.screen.width;
    final screenHeight = web.window.screen.height;
    final features =
        'width=$screenWidth,height=$screenHeight,left=$screenWidth,top=0,'
        'menubar=no,toolbar=no,location=no,status=no,scrollbars=no';

    final opened = web.window.open(
      audienceUri.toString(),
      'pptx_audience',
      features,
    );
    return opened == null ? null : AudienceWindowHandle(opened);
  } catch (_) {
    return null;
  }
}

void requestFullscreen() {
  try {
    web.document.documentElement?.requestFullscreen();
  } catch (_) {}
}

void exitFullscreen() {
  try {
    web.document.exitFullscreen();
  } catch (_) {}
}

@JS('__copilotEnsurePyodide')
external JSPromise<JSAny?> _ensurePyodideJs();

@JS('__copilotRunPython')
external JSPromise<JSAny?> _runPythonJs(JSString code);

Future<bool> ensurePyodideReady() async {
  try {
    final raw = (await _ensurePyodideJs().toDart).dartify();
    if (raw is bool) return raw;
    return false;
  } catch (_) {
    return false;
  }
}

Future<String> runPythonCode(String code) async {
  try {
    final raw = (await _runPythonJs(code.toJS).toDart).dartify();
    if (raw == null) return '';
    if (raw is String) return raw;
    return raw.toString();
  } catch (e) {
    return 'Erro ao executar Python: $e';
  }
}
