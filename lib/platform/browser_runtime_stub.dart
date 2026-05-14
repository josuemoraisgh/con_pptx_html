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

bool get hasMultipleScreens => false;

AudienceWindowHandle? openAudienceWindow() => null;

void requestFullscreen() {}

void exitFullscreen() {}
