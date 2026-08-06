package com.peraatmuu.app.emulator

import android.content.Context
import android.content.SharedPreferences

/**
 * Preferências persistentes da sala de emulação (layout de controles,
 * velocidade, escala de tela e ajustes de cor).
 */
object EmuSettings {

    private const val PREFS = "emu_settings"

    const val SCALE_FIT = 0       // mantém proporção (letterbox)
    const val SCALE_FILL = 1      // estica para preencher a tela
    const val SCALE_CROP = 2      // preenche mantendo proporção (recorta bordas)
    const val SCALE_INTEGER = 3   // escala inteira por pixels exatos

    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        if (!::prefs.isInitialized) {
            prefs = context.applicationContext
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        }
    }

    // ---------------------------------------------------------- Tela / cor

    var scaleMode: Int
        get() = prefs.getInt("scale_mode", SCALE_FIT)
        set(v) = prefs.edit().putInt("scale_mode", v).apply()

    var brightness: Float
        get() = prefs.getFloat("c_brightness", 0f)   // -0.5 .. +0.5
        set(v) = prefs.edit().putFloat("c_brightness", v).apply()

    var contrast: Float
        get() = prefs.getFloat("c_contrast", 1f)     // 0.5 .. 2.0
        set(v) = prefs.edit().putFloat("c_contrast", v).apply()

    var saturation: Float
        get() = prefs.getFloat("c_saturation", 1f)   // 0 .. 2.0
        set(v) = prefs.edit().putFloat("c_saturation", v).apply()

    // ------------------------------------------------------ Velocidade

    var speedFactor: Float
        get() = prefs.getFloat("speed_factor", 1f)
        set(v) = prefs.edit().putFloat("speed_factor", v).apply()

    // ------------------------------------------------------ Controles

    /** JSON do layout dos controles de CADA console (""/_null_ = padrão
     * do console). O layout global antigo ("controls_layout") é usado
     * como base na primeira vez e migrado ao primeiro salvamento. */
    fun controlsLayoutFor(systemId: String): String {
        val perKey = "controls_layout_$systemId"
        val per = prefs.getString(perKey, null)
        if (per != null) return per
        // migração: layout global (editado em versões antigas) vira base
        return prefs.getString("controls_layout", "") ?: ""
    }

    fun setControlsLayoutFor(systemId: String, json: String) {
        prefs.edit().putString("controls_layout_$systemId", json).apply()
    }

    /** JSON de cheats por jogo (chave = hash do caminho da ROM). */
    fun cheatsFor(romPath: String): String =
        prefs.getString("cheats_${romPath.hashCode()}", "[]") ?: "[]"

    fun setCheatsFor(romPath: String, json: String) {
        prefs.edit().putString("cheats_${romPath.hashCode()}", json).apply()
    }

    fun scaleModeLabel(mode: Int = scaleMode): String = when (mode) {
        SCALE_FILL -> "preencher"
        SCALE_CROP -> "recortar"
        SCALE_INTEGER -> "preciso"
        else -> "ajustar"
    }
}
