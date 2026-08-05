import 'dart:ffi';
import 'dart:io';

/// Ponte FFI para emuladores nativos (Android NDK / .so)
/// Em produção: compile libnes.so, libmgba.so, etc. via CMake/NDK
/// e carregue com DynamicLibrary.open('libnes.so')
class FfiBridge {
  static final Map<String, DynamicLibrary?> _libs = {};

  static bool loadLib(String libName) {
    try {
      if (Platform.isAndroid) {
        // Android: .so fica em jniLibs/armeabi-v7a/ ou lib/ no APK
        final lib = DynamicLibrary.open(libName);
        _libs[libName] = lib;
        return true;
      }
    } catch (e) {
      print('[FFI] Falha ao carregar $libName: $e');
    }
    return false;
  }

  static bool isLoaded(String libName) => _libs.containsKey(libName) && _libs[libName] != null;

  /// Inicializa o emulador com ROM (stub para integração real)
  static int initEmulator(String libName, String romPath) {
    if (!loadLib(libName)) return -1;
    // Lookup de símbolos nativos (ex: int nes_init(const char* rom))
    // final init = _libs[libName]!.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('nes_init');
    // return init(romPath.toNativeUtf8());
    print('[FFI] initEmulator $libName com ROM: $romPath');
    return 0; // sucesso simulado
  }

  /// Renderiza frame (stub)
  static int renderFrame(String libName) {
    print('[FFI] renderFrame $libName');
    return 0;
  }

  /// Finaliza
  static void shutdown(String libName) {
    print('[FFI] shutdown $libName');
    _libs.remove(libName);
  }

  /// Verifica se o dispositivo tem suporte (CPU, ABI)
  static bool isSupported() => Platform.isAndroid || Platform.isLinux || Platform.isWindows;
}
