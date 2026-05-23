import 'dart:async';

class AudienceWindowHandle {
  const AudienceWindowHandle();

  void close() {}
}

class BrowserMessenger {
  const BrowserMessenger(String channelName);

  Stream<Map<String, dynamic>> get messages => const Stream.empty();

  void post(Map<String, dynamic> data) {}

  void dispose() {}
}

bool get isAudienceView => false;
bool get isRawView => false;
int get rawSlideIndex => 0;

bool get hasMultipleScreens => false;

AudienceWindowHandle? openAudienceWindow() => null;

void requestFullscreen() {}

void exitFullscreen() {}

void saveViewerState(int slideIndex, int animStep) {}

({int slideIndex, int animStep})? loadViewerState() => null;

Future<bool> ensurePyodideReady() async => false;

Future<String> runPythonCode(String code) async =>
    'Pyodide disponivel apenas no build web.';
