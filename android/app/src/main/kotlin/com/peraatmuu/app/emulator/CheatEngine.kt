package com.peraatmuu.app.emulator

import org.json.JSONArray
import org.json.JSONObject

/**
 * Decodificador de códigos de cheat (estilo GameShark/Pro Action Replay)
 * para pokes de RAM aplicados em tempo real pela ponte nativa.
 *
 * Formatos aceitos (um por linha/atualização):
 *   - GB GameShark:   8 hex  → "01VVLLHH" (byte VV em HHLL)
 *   - SNES Pro Action Replay: 8 hex → "7EAAAAVV" (byte VV em WRAM AAAA)
 *   - GBA CodeBreaker: 12 hex → "3300AAAA 00VV" (halfword VV em WRAM AAAA)
 *   - RAW (qualquer sistema): "0xEND=0xVAL" ou "END=VAL"
 *       (1 byte por padrão; valor de 4 dígitos vira halfword, 8 dígitos word)
 *
 * Endereços são mapeados ao offset da memória emulada principal de cada
 * console (WRAM — id 2 na ABI libretro).
 */
object CheatEngine {

    // Ids de memória da ABI libretro
    const val MEM_SAVE = 0
    const val MEM_SYSTEM = 2 // WRAM (GB 0xC000+, SNES 0x7E0000+, GBA 0x02000000+...)

    // Base de endereçamento da WRAM por família de console, para converter
    // o endereço do código em offset dentro da memória do núcleo.
    private val wramBaseBySystem = mapOf(
        "gb" to 0xC000, "gbc" to 0xC000,
        "snes" to 0, // PAR já traz offset direto em 0x7E
        "gba" to 0x02000000,
        "nes" to 0, "sms" to 0, "md" to 0, "pce" to 0,
        "lynx" to 0, "ngp" to 0, "ws" to 0, "a26" to 0,
    )

    data class Cheat(
        val name: String,
        val code: String,
        var enabled: Boolean = true,
    )

    /** Uma entrada decodificada: [memId, offset, tamanho(1|2|4), valor]. */
    data class Poke(val memId: Int, val addr: Int, val size: Int, val value: Int)

    // ------------------------------------------------------------------
    // Persistência (JSON, por jogo)
    // ------------------------------------------------------------------

    fun load(romPath: String): MutableList<Cheat> {
        val list = mutableListOf<Cheat>()
        try {
            val arr = JSONArray(EmuSettings.cheatsFor(romPath))
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                list.add(
                    Cheat(
                        name = o.optString("name", "Cheat ${i + 1}"),
                        code = o.optString("code", ""),
                        enabled = o.optBoolean("enabled", true),
                    ),
                )
            }
        } catch (ignored: Exception) {
        }
        return list
    }

    fun save(romPath: String, cheats: List<Cheat>) {
        val arr = JSONArray()
        for (c in cheats) {
            arr.put(JSONObject().apply {
                put("name", c.name)
                put("code", c.code)
                put("enabled", c.enabled)
            })
        }
        EmuSettings.setCheatsFor(romPath, arr.toString())
    }

    // ------------------------------------------------------------------
    // Decodificação
    // ------------------------------------------------------------------

    /** Decodifica todos os cheats habilitados para [systemId]. */
    fun decodeActive(cheats: List<Cheat>, systemId: String): IntArray {
        val out = ArrayList<Int>()
        for (cheat in cheats) {
            if (!cheat.enabled) continue
            for (poke in decode(cheat.code, systemId)) {
                out.add(poke.memId)
                out.add(poke.addr)
                out.add(poke.size)
                out.add(poke.value)
            }
        }
        return out.toIntArray()
    }

    /** Decodifica UM código em pokes (retorna null + razão em [error] se inválido). */
    fun decode(code: String, systemId: String): List<Poke>? {
        val clean = code.trim().uppercase().replace(" ", "").replace("-", "")
        if (clean.length < 4) return null

        // RAW: 0xEND=0xVAL
        Regex("^0X([0-9A-F]+)=0X([0-9A-F]{1,8})$").find(clean)?.let { m ->
            val addr = m.groupValues[1].toInt(16)
            val vStr = m.groupValues[2]
            val value = vStr.toLong(16).toInt()
            val size = when {
                vStr.length <= 2 -> 1
                vStr.length <= 4 -> 2
                else -> 4
            }
            return listOf(Poke(MEM_SYSTEM, addr, size, value))
        }

        if (!clean.all { it in '0'..'9' || it in 'A'..'F' }) return null

        return when (systemId) {
            "gb" -> decodeGameBoy(clean)
            "snes" -> decodeSnes(clean)
            "gba" -> decodeGba(clean)
            else -> decodeSnes(clean) ?: decodeGameBoy(clean) ?: decodeGba(clean)
        }
    }

    /** GB GameShark v1: 8 dígitos "01VVLLHH" — escreve VV em 0xHHLL (WRAM-offset). */
    private fun decodeGameBoy(code: String): List<Poke>? {
        if (code.length != 8) return null
        val value = code.substring(2, 4).toInt(16)
        val addrLo = code.substring(4, 6).toInt(16)
        val addrHi = code.substring(6, 8).toInt(16)
        val addr = (addrHi shl 8) or addrLo // endereço físico 0x0000-0xFFFF
        val base = wramBaseBySystem["gb"] ?: 0xC000
        if (addr < base) return null
        return listOf(Poke(MEM_SYSTEM, addr - base, 1, value))
    }

    /** SNES Pro Action Replay: 8 dígitos "7EAAAABB" — byte BB em WRAM 0xAAAA. */
    private fun decodeSnes(code: String): List<Poke>? {
        if (code.length != 8 || !code.startsWith("7E")) return null
        val addr = code.substring(2, 6).toInt(16)
        val value = code.substring(6, 8).toInt(16)
        return listOf(Poke(MEM_SYSTEM, addr, 1, value))
    }

    /** GBA CodeBreaker "3300AAAA00VV" (12 dígitos): halfword VV em WRAM 0x0200xxxx.
     *  Emite pokes nos ids 2 e 3 (o mGBA pode expor WRAM rápida como 3). */
    private fun decodeGba(code: String): List<Poke>? {
        if (code.length != 12 || !code.startsWith("3300")) return null
        val addr = code.substring(4, 8).toInt(16)
        val value = code.substring(8, 12).toInt(16)
        return listOf(Poke(MEM_SYSTEM, addr, 2, value), Poke(3, addr, 2, value))
    }

    /** Texto de ajuda mostrado no diálogo de cheats. */
    val helpText: String =
        "Formatos aceitos:\n" +
        "• GB GameShark: 8 hex (ex.: 01FF9BD1)\n" +
        "• SNES Pro Action Replay: 8 hex (ex.: 7E1F5009)\n" +
        "• GBA CodeBreaker: 12 hex (ex.: 3300ADDE0042)\n" +
        "• Modo bruto: 0xEND=0xVAL (ex.: 0xC01B=0x63)\n\n" +
        "Dica: códigos de sites de cheats clássicos costumam funcionar. " +
        "Cheats errados podem travar o jogo — resete se algo quebrar."
}
