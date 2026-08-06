package com.peraatmuu.app.emulator

import java.nio.ByteBuffer

class EmulatorException(message: String) : Exception(message)

/**
 * Ponte para o código nativo (libretrobridge.so) que carrega os núcleos
 * libretro e executa a emulação de verdade.
 */
object RetroBridge {

    init {
        System.loadLibrary("retrobridge")
    }

    @JvmStatic external fun nativeInit(corePath: String, sysDir: String, saveDir: String): Int
    @JvmStatic external fun nativeLoadGame(romPath: String): Boolean
    @JvmStatic external fun nativeStart()
    @JvmStatic external fun nativeStop()
    @JvmStatic external fun nativeUnload()
    @JvmStatic external fun nativeReset()
    @JvmStatic external fun nativeSetButtons(mask: Int)
    @JvmStatic external fun nativeFrameInfo(out: IntArray)
    @JvmStatic external fun nativeCopyFrame(buffer: ByteBuffer): Boolean
    @JvmStatic external fun nativeReadAudio(dest: ByteArray, maxBytes: Int): Int
    @JvmStatic external fun nativeGetSampleRate(): Int
    @JvmStatic external fun nativeGetFps(): Double
    @JvmStatic external fun nativeSaveState(path: String): Boolean
    @JvmStatic external fun nativeLoadState(path: String): Boolean
    @JvmStatic external fun nativeSaveRam(path: String): Boolean
    @JvmStatic external fun nativeLoadRam(path: String): Boolean
    @JvmStatic external fun nativeShouldQuit(): Boolean
    @JvmStatic external fun nativeSetSpeedFactor(factor: Float)
    @JvmStatic external fun nativeGetSpeedFactor(): Float
    @JvmStatic external fun nativeSetCheats(entries: IntArray)

    /** Aplica uma opção de núcleo (core option) escolhida pelo usuário.
     * Deve ser chamada ANTES do loadGame. Valor "" remove o override. */
    @JvmStatic external fun nativeSetCoreOption(key: String, value: String)

    /** Núcleo negociou renderização por hardware (GPU) durante o load? */
    @JvmStatic external fun nativeIsHwRender(): Boolean

    /** Executa UM retro_run() na thread GL (núcleos com GPU desenham direto). */
    @JvmStatic external fun nativeRunHwFrame()

    /** Cursor/toque da tela sensível ao toque (DS): coordenadas normalizadas
     * no padrão libretro (-32767..32767) cobrindo o quadro inteiro. */
    @JvmStatic external fun nativeSetPointer(x: Int, y: Int, pressed: Boolean)

    @JvmStatic
    fun init(corePath: String, sysDir: String, saveDir: String) {
        val code = nativeInit(corePath, sysDir, saveDir)
        if (code != 0) {
            throw EmulatorException("Falha ao carregar o núcleo (código $code)")
        }
    }

    @JvmStatic
    fun loadGame(romPath: String) {
        if (!nativeLoadGame(romPath)) {
            throw EmulatorException("O núcleo não conseguiu abrir esta ROM")
        }
    }

    /** Retorna [largura, altura, atualizado, aspecto*1000] do quadro atual. */
    @JvmStatic
    fun frameInfo(out: IntArray = IntArray(4)): IntArray {
        nativeFrameInfo(out)
        return out
    }
}
