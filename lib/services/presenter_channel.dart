import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

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

// ─────────────────────────────────────────────────────────────────────────────
// Canal
// ─────────────────────────────────────────────────────────────────────────────

/// Wrapper sobre [BroadcastChannel] para sincronizar o modo apresentador
/// entre a janela principal e a janela da plateia.
class PresenterChannel {
  static const _channelName = 'pptx_presenter';

  late final web.BroadcastChannel _bc;
  final _controller = StreamController<PresenterMessage>.broadcast();

  PresenterChannel() {
    _bc = web.BroadcastChannel(_channelName);
    _bc.onmessage = (web.MessageEvent e) {
      _onMessage(e);
    }.toJS;
  }

  Stream<PresenterMessage> get messages => _controller.stream;

  void _onMessage(web.MessageEvent e) {
    try {
      final raw = e.data.dartify();
      if (raw is! Map) return;
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

  void _post(Map<String, dynamic> data) {
    try {
      _bc.postMessage(data.jsify()!);
    } catch (_) {}
  }

  void dispose() {
    _bc.close();
    _controller.close();
  }

  // ── Utilitários estáticos ────────────────────────────────────────────────

  /// Retorna true se o browser indica múltiplos monitores conectados.
  /// Usa `window.screen.isExtended` (Chrome/Edge 100+).
  static bool get hasMultipleScreens {
    try {
      final screen = globalContext['screen'];
      if (screen == null) return false;
      final isExt = (screen as JSObject)['isExtended'];
      if (isExt == null) return false;
      // Verifica se é um boolean JS válido
      if (!isExt.isA<JSBoolean>()) return false;
      return (isExt as JSBoolean).toDart;
    } catch (_) {
      return false;
    }
  }

  /// Abre a janela da plateia posicionada no segundo monitor.
  /// Retorna a referência da janela aberta, ou null em caso de falha.
  static web.Window? openAudienceWindow() {
    try {
      final sw = web.window.screen.width;
      final sh = web.window.screen.height;
      // left=sw posiciona a janela à direita do monitor principal
      final features =
          'width=$sw,height=$sh,left=$sw,top=0,'
          'menubar=no,toolbar=no,location=no,status=no,scrollbars=no';
      return web.window.open('/?view=audience', 'pptx_audience', features);
    } catch (_) {
      return null;
    }
  }
}
