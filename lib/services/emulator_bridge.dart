import 'package:flutter/services.dart';

/// Canal de comunicação com a camada nativa Android (Kotlin/JNI).
class EmulatorBridge {
  static const MethodChannel _channel = MethodChannel('peraatmuu/emulator');

  /// Pastas internas do app e diretório de bibliotecas nativas (núcleos).
  static Future<Map<String, String>> paths() async {
    final result =
        await _channel.invokeMapMethod<String, String>('getPaths');
    return result ?? const {};
  }

  static Future<String> primaryAbi() async {
    final abi = await _channel.invokeMethod<String>('getAbi');
    return abi ?? 'arm64-v8a';
  }

  /// Verifica se o núcleo embutido existe no dispositivo.
  static Future<bool> isCoreAvailable(String coreFile) async {
    final ok = await _channel
        .invokeMethod<bool>('isCoreAvailable', {'coreFile': coreFile});
    return ok ?? false;
  }

  /// Abre a tela nativa de emulação e inicia o jogo.
  static Future<void> play({
    required String corePath,
    required String romPath,
    required String systemId,
    Map<String, String> coreOptions = const {},
  }) {
    return _channel.invokeMethod<void>('play', {
      'corePath': corePath,
      'romPath': romPath,
      'systemId': systemId,
      'coreOptions': coreOptions,
    });
  }
}
