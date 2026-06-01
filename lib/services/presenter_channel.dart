import 'dart:async';

import '../platform/browser_runtime.dart' as browser;

// ─────────────────────────────────────────────────────────────────────────────
// Mensagens
// ─────────────────────────────────────────────────────────────────────────────

sealed class PresenterMessage {
  const PresenterMessage();
}

/// Estado atual do slide, enviado pela janela controladora.
class PresenterStateMessage extends PresenterMessage {
  final int slideIndex;
  final int animStep;
  const PresenterStateMessage({
    required this.slideIndex,
    required this.animStep,
  });
}

/// Sinal de swap: ambas as janelas invertem qual conteúdo exibem.
class PresenterSwapMessage extends PresenterMessage {
  const PresenterSwapMessage();
}

/// Comando de navegação enviado pela janela passiva para a janela controladora.
class PresenterNavigateMessage extends PresenterMessage {
  final bool advance;
  const PresenterNavigateMessage({required this.advance});
}

/// Estado atual de autenticação do quiz, compartilhado entre as janelas.
class PresenterAuthMessage extends PresenterMessage {
  final Map<String, dynamic>? user;
  const PresenterAuthMessage({required this.user});
}

// ─────────────────────────────────────────────────────────────────────────────
// Canal
// ─────────────────────────────────────────────────────────────────────────────

/// Wrapper sobre [BroadcastChannel] para sincronizar o modo apresentador
/// entre a janela principal e a janela da plateia.
class PresenterChannel {
  static const _channelName = 'pptx_presenter';

  late final browser.BrowserMessenger _messenger;
  final _controller = StreamController<PresenterMessage>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  PresenterChannel() {
    _messenger = browser.BrowserMessenger(_channelName);
    _subscription = _messenger.messages.listen(_onMessage);
  }

  Stream<PresenterMessage> get messages => _controller.stream;

  void _onMessage(Map<String, dynamic> raw) {
    try {
      final type = raw['type'] as String?;
      switch (type) {
        case 'state':
          _controller.add(
            PresenterStateMessage(
              slideIndex: (raw['slideIndex'] as num).toInt(),
              animStep: (raw['animStep'] as num).toInt(),
            ),
          );
        case 'swap':
          _controller.add(const PresenterSwapMessage());
        case 'navigate':
          _controller.add(
            PresenterNavigateMessage(advance: raw['action'] == 'advance'),
          );
        case 'auth':
          final user = raw['user'];
          if (user == null || user is Map<String, dynamic>) {
            _controller.add(PresenterAuthMessage(user: user));
          } else if (user is Map) {
            _controller.add(
              PresenterAuthMessage(
                user: user.map((key, value) => MapEntry(key.toString(), value)),
              ),
            );
          }
      }
    } catch (_) {}
  }

  /// Envia estado atual do slide para a outra janela.
  void sendState(int slideIndex, int animStep) {
    _post({'type': 'state', 'slideIndex': slideIndex, 'animStep': animStep});
  }

  /// Envia sinal de swap para ambas as janelas reagirem.
  void sendSwap() => _post({'type': 'swap'});

  /// Envia comando de navegação (da janela passiva para a controladora).
  void sendNavigate({required bool advance}) {
    _post({'type': 'navigate', 'action': advance ? 'advance' : 'retreat'});
  }

  /// Compartilha o usuário autenticado do quiz entre as janelas.
  void sendAuth(Map<String, dynamic>? user) =>
      _post({'type': 'auth', 'user': user});

  void _post(Map<String, dynamic> data) {
    _messenger.post(data);
  }

  void dispose() {
    _subscription?.cancel();
    _messenger.dispose();
    _controller.close();
  }

  // ── Utilitários estáticos ────────────────────────────────────────────────

  /// Retorna true se o browser indica múltiplos monitores conectados.
  /// Usa `window.screen.isExtended` (Chrome/Edge 100+).
  static bool get hasMultipleScreens {
    return browser.hasMultipleScreens;
  }

  /// Abre a janela da plateia posicionada no segundo monitor.
  /// Retorna a referência da janela aberta, ou null em caso de falha.
  static browser.AudienceWindowHandle? openAudienceWindow() =>
      browser.openAudienceWindow();
}
