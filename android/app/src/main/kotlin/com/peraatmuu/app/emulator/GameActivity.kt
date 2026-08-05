package com.peraatmuu.app.emulator

import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.opengl.GLSurfaceView
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import java.io.File
import kotlin.math.abs

/**
 * Tela de emulação: núcleo libretro + OpenGL + áudio + controles
 * personalizáveis + fast-forward + cheats + ajustes de vídeo,
 * tudo com o visual neon do app.
 */
class GameActivity : Activity() {

    companion object {
        private const val EXTRA_CORE = "corePath"
        private const val EXTRA_ROM = "romPath"
        private const val EXTRA_SYSTEM = "systemId"
        private const val REQ_PICK_BUTTON_IMAGE = 71

        fun createIntent(context: Context, corePath: String, romPath: String, systemId: String): Intent =
            Intent(context, GameActivity::class.java).apply {
                putExtra(EXTRA_CORE, corePath)
                putExtra(EXTRA_ROM, romPath)
                putExtra(EXTRA_SYSTEM, systemId)
            }

        private val BG = Color.parseColor("#12121F")
        private val CARD = Color.parseColor("#1B1B2E")
        private val LINE = Color.parseColor("#2E2E4D")
        private val NEON = Color.parseColor("#00F5D4")
        private val TXT = Color.parseColor("#F4F4FA")
        private val TXT_MID = Color.parseColor("#9FA3C0")

        /** Consoles com tela sensível ao toque (interação direta no jogo). */
        private val TOUCH_SYSTEMS = setOf("nds")
    }

    private lateinit var glView: GLSurfaceView
    private lateinit var renderer: EmulatorRenderer
    private lateinit var controls: ControlsOverlayView
    private var audio: AudioPlayer? = null

    private var corePath = ""
    private var romPath = ""
    private var systemId = "generic"
    private lateinit var stateFile: File
    private lateinit var sramFile: File

    private var virtualMask = 0
    private var physicalMask = 0
    private var dead = false

    /** Núcleo usa GPU (renderização por hardware)? */
    private var hwMode = false

    /** Load do jogo concluído na thread GL? */
    private var emuLoaded = false

    /** Console tem tela sensível ao toque (Nintendo DS)? */
    private var touchEnabled = false

    private var editingButton: ControlsOverlayView.ButtonCfg? = null
    private val cheats = mutableListOf<CheatEngine.Cheat>()

    private val keyToButton = mapOf(
        KeyEvent.KEYCODE_BUTTON_B to ControlsOverlayView.BTN_B,
        KeyEvent.KEYCODE_BUTTON_Y to ControlsOverlayView.BTN_Y,
        KeyEvent.KEYCODE_BUTTON_SELECT to ControlsOverlayView.BTN_SELECT,
        KeyEvent.KEYCODE_BUTTON_START to ControlsOverlayView.BTN_START,
        KeyEvent.KEYCODE_DPAD_UP to ControlsOverlayView.BTN_UP,
        KeyEvent.KEYCODE_DPAD_DOWN to ControlsOverlayView.BTN_DOWN,
        KeyEvent.KEYCODE_DPAD_LEFT to ControlsOverlayView.BTN_LEFT,
        KeyEvent.KEYCODE_DPAD_RIGHT to ControlsOverlayView.BTN_RIGHT,
        KeyEvent.KEYCODE_BUTTON_A to ControlsOverlayView.BTN_A,
        KeyEvent.KEYCODE_BUTTON_X to ControlsOverlayView.BTN_X,
        KeyEvent.KEYCODE_BUTTON_L1 to ControlsOverlayView.BTN_L,
        KeyEvent.KEYCODE_BUTTON_R1 to ControlsOverlayView.BTN_R,
        KeyEvent.KEYCODE_Z to ControlsOverlayView.BTN_B,
        KeyEvent.KEYCODE_X to ControlsOverlayView.BTN_A,
        KeyEvent.KEYCODE_A to ControlsOverlayView.BTN_Y,
        KeyEvent.KEYCODE_S to ControlsOverlayView.BTN_X,
        KeyEvent.KEYCODE_ENTER to ControlsOverlayView.BTN_START,
        KeyEvent.KEYCODE_SPACE to ControlsOverlayView.BTN_SELECT,
    )

    // ------------------------------------------------------------------
    // Ciclo de vida
    // ------------------------------------------------------------------

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        applyImmersive()
        EmuSettings.init(this)

        corePath = intent.getStringExtra(EXTRA_CORE).orEmpty()
        romPath = intent.getStringExtra(EXTRA_ROM).orEmpty()
        systemId = intent.getStringExtra(EXTRA_SYSTEM) ?: "generic"

        val romName = File(romPath).nameWithoutExtension
        val statesDir = File(filesDir, "states/$systemId").apply { mkdirs() }
        val savesDir = File(filesDir, "saves").apply { mkdirs() }
        val systemDir = File(filesDir, "system").apply { mkdirs() }
        stateFile = File(statesDir, "$romName.state")
        sramFile = File(savesDir, "$romName.srm")

        try {
            RetroBridge.init(corePath, systemDir.absolutePath, savesDir.absolutePath)
        } catch (e: EmulatorException) {
            Toast.makeText(this, e.message, Toast.LENGTH_LONG).show()
            dead = true
            finish()
            return
        }
        touchEnabled = systemId in TOUCH_SYSTEMS

        renderer = EmulatorRenderer()
        applyVisualSettings()

        glView = GLSurfaceView(this).apply {
            // Profundidade+stencil e contexto preservado: necessários para os
            // núcleos com renderização por GPU (PSP, N64).
            setEGLConfigChooser(8, 8, 8, 8, 16, 8)
            setEGLContextClientVersion(2)
            setPreserveEGLContextOnPause(true)
            setRenderer(renderer)
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }

        controls = ControlsOverlayView(this).apply {
            onButtonsChanged = { mask ->
                virtualMask = mask
                pushMask()
            }
            onMenuPressed = { showGameMenu() }
            onButtonEditRequested = { showButtonEditor(it) }
            if (touchEnabled) {
                onScreenTouch = { x, y, action -> routePointer(x, y, action) }
            }
        }

        val root = FrameLayout(this).apply {
            addView(
                glView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
            addView(
                controls,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
        }
        setContentView(root)

        // Cheats salvos deste jogo
        cheats.clear()
        cheats.addAll(CheatEngine.load(romPath))
        applyCheats()

        // Velocidade persistida
        RetroBridge.nativeSetSpeedFactor(EmuSettings.speedFactor)

        // O carregamento do jogo acontece NA THREAD GL: núcleos com GPU
        // (PSP/N64) já inicializam OpenGL dentro do retro_load_game.
        val romLabel = romName
        glView.queueEvent {
            try {
                RetroBridge.loadGame(romPath)
                if (sramFile.exists()) {
                    RetroBridge.nativeLoadRam(sramFile.absolutePath)
                }
                hwMode = RetroBridge.nativeIsHwRender()
                renderer.hwMode = hwMode
                emuLoaded = true
                runOnUiThread {
                    toast(if (hwMode) "$romLabel (GPU)" else romLabel)
                    if (!hwMode) RetroBridge.nativeStart()
                    if (EmuSettings.speedFactor <= 1f) startAudio()
                }
            } catch (e: EmulatorException) {
                runOnUiThread {
                    Toast.makeText(this, e.message, Toast.LENGTH_LONG).show()
                    dead = true
                    finish()
                }
            }
        }
    }

    /** Repassa o toque da tela do DS ao núcleo (coordenadas libretro). */
    private fun routePointer(x: Float, y: Float, action: Int) {
        if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_MOVE) {
            val r = renderer.frameRectOnView()
            val rw = if (r.width() > 1f) r.width() else 1f
            val rh = if (r.height() > 1f) r.height() else 1f
            val nx = (((x - r.left) / rw) * 65534f - 32767f).toInt()
            val ny = (((y - r.top) / rh) * 65534f - 32767f).toInt()
            RetroBridge.nativeSetPointer(
                nx.coerceIn(-32767, 32767),
                ny.coerceIn(-32767, 32767),
                true,
            )
        } else {
            RetroBridge.nativeSetPointer(0, 0, false)
        }
    }

    override fun onResume() {
        super.onResume()
        applyImmersive()
        if (!dead) {
            if (::glView.isInitialized) glView.onResume()
            if (emuLoaded) {
                if (!hwMode) RetroBridge.nativeStart()
                if (EmuSettings.speedFactor <= 1f) startAudio()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        if (::glView.isInitialized) glView.onPause()
        stopAudio()
        RetroBridge.nativeSetButtons(0)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (dead) return
        RetroBridge.nativeStop()
        if (::sramFile.isInitialized) {
            RetroBridge.nativeSaveRam(sramFile.absolutePath)
        }
        if (hwMode && ::glView.isInitialized) {
            // Núcleos com GPU precisam do contexto GL vivo para se desligar.
            glView.queueEvent { RetroBridge.nativeUnload() }
        } else {
            RetroBridge.nativeUnload()
        }
    }

    private fun applyImmersive() {
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    }

    private fun startAudio() {
        if (audio != null) return
        val rate = RetroBridge.nativeGetSampleRate().coerceIn(8000, 96000)
        audio = AudioPlayer(rate).also { it.start() }
    }

    private fun stopAudio() {
        audio?.shutdown()
        audio = null
    }

    private fun applyVisualSettings() {
        renderer.scaleMode = EmuSettings.scaleMode
        renderer.brightness = EmuSettings.brightness
        renderer.contrast = EmuSettings.contrast
        renderer.saturation = EmuSettings.saturation
    }

    // ------------------------------------------------------------------
    // Menu do jogo (visual PeraatMuu)
    // ------------------------------------------------------------------

    private fun neonDialog(title: String): Pair<Dialog, LinearLayout> {
        val dialog = Dialog(this)
        val scroll = ScrollView(this)
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(14), dp(18), dp(18))
        }
        val titleView = TextView(this).apply {
            text = title
            setTextColor(NEON)
            textSize = 15f
            setTypeface(null, android.graphics.Typeface.BOLD)
            letterSpacing = 0.15f
        }
        column.addView(titleView)
        column.addView(divider())
        scroll.addView(column)
        dialog.setContentView(
            scroll,
            FrameLayout.LayoutParams(
                (resources.displayMetrics.heightPixels * 0.72f).toInt().coerceAtMost(dp(360)),
                FrameLayout.LayoutParams.WRAP_CONTENT,
            ),
        )
        dialog.window?.setBackgroundDrawable(
            GradientDrawable().apply {
                cornerRadius = dp(18).toFloat()
                setColor(BG)
                setStroke(dp(1), LINE)
            },
        )
        dialog.setOnDismissListener { applyImmersive() }
        return dialog to column
    }

    private fun divider(): View = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, dp(1),
        ).apply { setMargins(0, dp(10), 0, dp(6)) }
        setBackgroundColor(LINE)
    }

    data class MenuItem(
        val glyph: String,
        val label: String,
        val detail: String = "",
        val onTap: () -> Unit,
    )

    private fun LinearLayout.addMenuRows(dialog: Dialog, items: List<MenuItem>) {
        for (item in items) {
            val row = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, dp(10), 0, dp(10))
                setOnClickListener { item.onTap(); if (dialog.isShowing) dialog.dismiss() }
            }
            val icon = TextView(context).apply {
                text = item.glyph
                setTextColor(NEON)
                textSize = 16f
                setPadding(0, 0, dp(14), 0)
            }
            val labelCol = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            val label = TextView(context).apply {
                text = item.label
                setTextColor(TXT)
                textSize = 14f
            }
            labelCol.addView(label)
            if (item.detail.isNotEmpty()) {
                labelCol.addView(
                    TextView(context).apply {
                        text = item.detail
                        setTextColor(TXT_MID)
                        textSize = 11f
                    },
                )
            }
            row.addView(icon)
            row.addView(labelCol)
            addView(row)
            addView(
                View(context).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT, 1,
                    ).apply { setMargins(dp(28), 0, 0, 0) }
                    setBackgroundColor(LINE)
                },
            )
        }
    }

    private fun showGameMenu() {
        val speed = EmuSettings.speedFactor
        val (dialog, column) = neonDialog("PERAATMUU")
        column.addMenuRows(
            dialog,
            listOf(
                MenuItem("▶", "Continuar", "voltar ao jogo") {},
                MenuItem("≫", "Acelerar velocidade", "atual: ${speedLabel(speed)}") {
                    cycleSpeed()
                },
                MenuItem("⛶", "Modo de tela", "atual: ${EmuSettings.scaleModeLabel()}") {
                    cycleScaleMode()
                },
                MenuItem("◐", "Ajustar cores", "brilho, contraste, saturação") {
                    showColorsDialog()
                },
                MenuItem("✎", "Controles", "mover, redimensionar, trocar ícones") {
                    toggleControlEdit()
                },
                MenuItem("</>", "Cheats", "${cheats.count { it.enabled }} ativo(s)") {
                    showCheatsDialog()
                },
                MenuItem("↓", "Salvar estado", "") {
                    toast(
                        if (RetroBridge.nativeSaveState(stateFile.absolutePath)) "Estado salvo"
                        else "Não foi possível salvar"
                    )
                },
                MenuItem("↑", "Carregar estado", "") {
                    toast(
                        when {
                            !stateFile.exists() -> "Nenhum estado salvo ainda"
                            RetroBridge.nativeLoadState(stateFile.absolutePath) -> "Estado carregado"
                            else -> "Falha ao carregar o estado"
                        }
                    )
                },
                MenuItem("↻", "Reiniciar jogo", "") {
                    RetroBridge.nativeReset()
                },
                MenuItem("✕", "Sair", "") {
                    finish()
                },
            ),
        )
        dialog.show()
    }

    // ------------------------------------------------------------------
    // Velocidade
    // ------------------------------------------------------------------

    private fun speedLabel(f: Float): String = when {
        f >= 5 -> "5× (máximo)"
        f >= 4 -> "4×"
        f >= 3 -> "3×"
        f >= 2 -> "2× — bom pra pular cutscenes"
        else -> "normal (1×)"
    }

    private fun cycleSpeed() {
        val current = EmuSettings.speedFactor
        val next = when {
            current >= 5f -> 1f
            current >= 4f -> 5f
            current >= 3f -> 4f
            current >= 2f -> 3f
            else -> 2f
        }
        setSpeed(next)
    }

    private fun setSpeed(f: Float) {
        EmuSettings.speedFactor = f
        RetroBridge.nativeSetSpeedFactor(f)
        if (f > 1f) stopAudio() else startAudio()
        toast("Velocidade: ${speedLabel(f)}")
    }

    // ------------------------------------------------------------------
    // Tela e cores
    // ------------------------------------------------------------------

    private fun cycleScaleMode() {
        val next = (EmuSettings.scaleMode + 1) % 4
        EmuSettings.scaleMode = next
        renderer.scaleMode = next
        toast("Tela: ${EmuSettings.scaleModeLabel(next)}")
    }

    private fun showColorsDialog() {
        val (dialog, column) = neonDialog("AJUSTAR CORES")
        column.addSliderRow("Brilho", EmuSettings.brightness, -0.5f, 0.5f) { v ->
            EmuSettings.brightness = v; renderer.brightness = v
        }
        column.addSliderRow("Contraste", EmuSettings.contrast, 0.5f, 2.0f) { v ->
            EmuSettings.contrast = v; renderer.contrast = v
        }
        column.addSliderRow("Saturação", EmuSettings.saturation, 0f, 2.0f) { v ->
            EmuSettings.saturation = v; renderer.saturation = v
        }
        column.addMenuRows(
            dialog,
            listOf(
                MenuItem("↺", "Restaurar padrão", "") {
                    EmuSettings.brightness = 0f
                    EmuSettings.contrast = 1f
                    EmuSettings.saturation = 1f
                    applyVisualSettings()
                    toast("Cores restauradas")
                },
            ),
        )
        dialog.show()
    }

    private fun LinearLayout.addSliderRow(
        label: String,
        initial: Float,
        min: Float,
        max: Float,
        onChange: (Float) -> Unit,
    ) {
        addView(
            TextView(context).apply {
                text = label
                setTextColor(TXT)
                textSize = 13f
                setPadding(0, dp(10), 0, 0)
            },
        )
        addView(
            SeekBar(context).apply {
                this.max = 100
                progress = (((initial - min) / (max - min)) * 100).toInt().coerceIn(0, 100)
                setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                    override fun onProgressChanged(sb: SeekBar?, p: Int, fromUser: Boolean) {
                        if (fromUser) onChange(min + (p / 100f) * (max - min))
                    }
                    override fun onStartTrackingTouch(sb: SeekBar?) {}
                    override fun onStopTrackingTouch(sb: SeekBar?) {}
                })
            },
        )
    }

    // ------------------------------------------------------------------
    // Controles personalizáveis
    // ------------------------------------------------------------------

    private fun toggleControlEdit() {
        controls.editMode = !controls.editMode
        if (controls.editMode) {
            toast("Arraste os botões. Toque para personalizar. Abra o menu novamente para concluir.")
        } else {
            controls.saveLayout()
            toast("Layout dos controles salvo")
        }
    }

    private fun showButtonEditor(cfg: ControlsOverlayView.ButtonCfg) {
        editingButton = cfg
        val (dialog, column) = neonDialog("BOTÃO ${nameOf(cfg.id)}")

        column.addView(
            TextView(this).apply {
                text = "Tamanho"
                setTextColor(TXT)
                textSize = 13f
                setPadding(0, dp(6), 0, 0)
            },
        )
        val sizeBar = SeekBar(this).apply {
            max = 100
            progress = ((cfg.size / 0.34f) * 100).toInt().coerceIn(10, 100)
        }
        sizeBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar?, p: Int, fromUser: Boolean) {
                if (!fromUser) return
                val newSize = 0.10f + (0.28f * p / 100f)
                cfg.size = newSize
                controls.updateButton(cfg)
            }
            override fun onStartTrackingTouch(sb: SeekBar?) {}
            override fun onStopTrackingTouch(sb: SeekBar?) {}
        })
        column.addView(sizeBar)

        column.addView(
            TextView(this).apply {
                text = "Ícone"
                setTextColor(TXT)
                textSize = 13f
                setPadding(0, dp(8), 0, dp(4))
            },
        )
        val grid = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        var row: LinearLayout? = null
        ControlsOverlayView.PRESETS.forEachIndexed { i, preset ->
            if (i % 6 == 0) {
                row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
                grid.addView(row)
            }
            val selected = cfg.image.isBlank() && if (preset.iconRes != 0) {
                cfg.icon == preset.iconRes
            } else {
                cfg.icon == 0 && cfg.label == preset.label
            }
            val chip = FrameLayout(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, dp(38), 1f).apply {
                    setMargins(dp(2), dp(2), dp(2), dp(2))
                }
                background = GradientDrawable().apply {
                    cornerRadius = dp(8).toFloat()
                    setColor(CARD)
                    setStroke(dp(1), if (selected) NEON else LINE)
                }
                if (preset.iconRes != 0) {
                    addView(ImageView(this@GameActivity).apply {
                        setImageResource(preset.iconRes)
                        setColorFilter(if (selected) NEON else TXT_MID)
                        layoutParams = FrameLayout.LayoutParams(dp(20), dp(20), Gravity.CENTER)
                    })
                } else {
                    addView(TextView(this@GameActivity).apply {
                        text = preset.label
                        setTextColor(if (selected) NEON else TXT_MID)
                        textSize = 13f
                        gravity = Gravity.CENTER
                        layoutParams = FrameLayout.LayoutParams(
                            FrameLayout.LayoutParams.MATCH_PARENT,
                            FrameLayout.LayoutParams.MATCH_PARENT,
                        )
                    })
                }
                setOnClickListener {
                    cfg.label = preset.label
                    cfg.icon = preset.iconRes
                    cfg.image = ""
                    controls.updateButton(cfg)
                    dialog.dismiss()
                    toast("Ícone alterado")
                }
            }
            row?.addView(chip)
        }
        column.addView(grid)

        column.addView(divider())
        column.addMenuRows(
            dialog,
            listOf(
                MenuItem("▣", "Importar imagem da memória", "PNG/JPG deixa o botão com a sua arte") {
                    pickImageForButton(cfg)
                },
                MenuItem("⟲", "Remover imagem personalizada", "") {
                    cfg.image = ""
                    controls.updateButton(cfg)
                    toast("Imagem removida")
                },
                MenuItem("↺", "Restaurar layout padrão", "reposiciona e rezeta todos os botões") {
                    controls.resetLayout()
                    toast("Layout restaurado")
                },
            ),
        )
        dialog.show()
    }

    private fun nameOf(id: Int): String = when (id) {
        ControlsOverlayView.BTN_A -> "A"
        ControlsOverlayView.BTN_B -> "B"
        ControlsOverlayView.BTN_X -> "X"
        ControlsOverlayView.BTN_Y -> "Y"
        ControlsOverlayView.BTN_L -> "L"
        ControlsOverlayView.BTN_R -> "R"
        ControlsOverlayView.BTN_SELECT -> "SELECT"
        ControlsOverlayView.BTN_START -> "START"
        ControlsOverlayView.BTN_UP -> "↑"
        ControlsOverlayView.BTN_DOWN -> "↓"
        ControlsOverlayView.BTN_LEFT -> "←"
        ControlsOverlayView.BTN_RIGHT -> "→"
        else -> "?"
    }

    private fun pickImageForButton(cfg: ControlsOverlayView.ButtonCfg) {
        editingButton = cfg
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "image/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        startActivityForResult(intent, REQ_PICK_BUTTON_IMAGE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_PICK_BUTTON_IMAGE || resultCode != RESULT_OK || data?.data == null) return
        val cfg = editingButton ?: return
        try {
            val dir = File(filesDir, "button_icons").apply { mkdirs() }
            val dest = File(dir, "btn_${cfg.id}.png")
            contentResolver.openInputStream(data.data!!).use { input ->
                if (input == null) throw IllegalStateException("sem acesso à imagem")
                dest.outputStream().use { output -> input.copyTo(output) }
            }
            cfg.image = dest.absolutePath
            controls.updateButton(cfg)
            toast("Imagem aplicada ao botão ${nameOf(cfg.id)}")
        } catch (e: Exception) {
            toast("Não consegui usar essa imagem: ${e.message}")
        }
    }

    // ------------------------------------------------------------------
    // Cheats
    // ------------------------------------------------------------------

    private fun applyCheats() {
        val pokes = CheatEngine.decodeActive(cheats, systemId)
        RetroBridge.nativeSetCheats(pokes)
        CheatEngine.save(romPath, cheats)
    }

    private fun showCheatsDialog() {
        val (dialog, column) = neonDialog("CHEATS (${cheats.size})")

        if (cheats.isEmpty()) {
            column.addView(
                TextView(this).apply {
                    text = "Nenhum cheat neste jogo ainda."
                    setTextColor(TXT_MID)
                    textSize = 13f
                    setPadding(0, dp(4), 0, dp(10))
                },
            )
        } else {
            cheats.forEach { cheat ->
                val row = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(0, dp(6), 0, dp(6))
                }
                val box = TextView(this).apply {
                    text = if (cheat.enabled) "☑" else "☐"
                    setTextColor(NEON)
                    textSize = 16f
                    setPadding(0, 0, dp(10), 0)
                    setOnClickListener {
                        cheat.enabled = !cheat.enabled
                        applyCheats()
                        dialog.dismiss()
                        showCheatsDialog()
                    }
                }
                val label = TextView(this).apply {
                    text = cheat.name
                    setTextColor(TXT)
                    textSize = 13f
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                }
                val del = TextView(this).apply {
                    text = "✕"
                    setTextColor(TXT_MID)
                    textSize = 14f
                    setPadding(dp(8), 0, 0, 0)
                    setOnClickListener {
                        cheats.remove(cheat)
                        applyCheats()
                        toast("Cheat removido")
                        dialog.dismiss()
                        showCheatsDialog()
                    }
                }
                row.addView(box)
                row.addView(label)
                row.addView(del)
                column.addView(row)
            }
        }

        column.addView(divider())
        column.addView(
            TextView(this).apply {
                text = CheatEngine.helpText
                setTextColor(TXT_MID)
                textSize = 11f
                setPadding(0, dp(4), 0, dp(8))
            },
        )

        val nameField = EditText(this).apply {
            hint = "Nome do cheat (ex.: Vidas infinitas)"
            setHintTextColor(TXT_MID)
            setTextColor(TXT)
            textSize = 13f
        }
        val codeField = EditText(this).apply {
            hint = "Código (ex.: 01FF9BD1)"
            setHintTextColor(TXT_MID)
            setTextColor(TXT)
            textSize = 13f
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
        }
        column.addView(nameField)
        column.addView(codeField)
        column.addMenuRows(
            dialog,
            listOf(
                MenuItem("＋", "Adicionar cheat", "") {
                    val code = codeField.text.toString().trim()
                    val name = nameField.text.toString().trim()
                        .ifEmpty { "Cheat ${cheats.size + 1}" }
                    if (code.isBlank()) {
                        toast("Digite o código do cheat")
                    } else if (CheatEngine.decode(code, systemId) == null) {
                        toast("Formato não reconhecido para este console")
                    } else {
                        cheats.add(CheatEngine.Cheat(name, code, true))
                        applyCheats()
                        toast("Cheat \"$name\" ativado")
                    }
                },
            ),
        )
        dialog.show()
    }

    // ------------------------------------------------------------------
    // Utilidades
    // ------------------------------------------------------------------

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun toast(message: String) {
        runOnUiThread { Toast.makeText(this, message, Toast.LENGTH_SHORT).show() }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        showGameMenu()
    }

    // ------------------------------------------------------------------
    // Entrada: gamepad físico + teclado
    // ------------------------------------------------------------------

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (controls.editMode) return super.dispatchKeyEvent(event)
        if (event.keyCode == KeyEvent.KEYCODE_BACK &&
            event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0
        ) {
            showGameMenu()
            return true
        }
        val button = keyToButton[event.keyCode]
        if (button != null) {
            when (event.action) {
                KeyEvent.ACTION_DOWN -> {
                    if (event.repeatCount == 0) {
                        physicalMask = physicalMask or (1 shl button)
                        pushMask()
                    }
                }
                KeyEvent.ACTION_UP -> {
                    physicalMask = physicalMask and (1 shl button).inv()
                    pushMask()
                }
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (controls.editMode) return super.dispatchGenericMotionEvent(event)
        if (event.source and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK) {
            val dpadBits = (1 shl ControlsOverlayView.BTN_UP) or
                (1 shl ControlsOverlayView.BTN_DOWN) or
                (1 shl ControlsOverlayView.BTN_LEFT) or
                (1 shl ControlsOverlayView.BTN_RIGHT)
            var newBits = 0

            val hatX = event.getAxisValue(MotionEvent.AXIS_HAT_X)
            val hatY = event.getAxisValue(MotionEvent.AXIS_HAT_Y)
            val stickX = event.getAxisValue(MotionEvent.AXIS_X)
            val stickY = event.getAxisValue(MotionEvent.AXIS_Y)

            val x = if (abs(hatX) > 0.5f) hatX else stickX
            val y = if (abs(hatY) > 0.5f) hatY else stickY

            if (x < -0.5f) newBits = newBits or (1 shl ControlsOverlayView.BTN_LEFT)
            if (x > 0.5f) newBits = newBits or (1 shl ControlsOverlayView.BTN_RIGHT)
            if (y < -0.5f) newBits = newBits or (1 shl ControlsOverlayView.BTN_UP)
            if (y > 0.5f) newBits = newBits or (1 shl ControlsOverlayView.BTN_DOWN)

            physicalMask = (physicalMask and dpadBits.inv()) or newBits
            pushMask()
            return true
        }
        return super.dispatchGenericMotionEvent(event)
    }

    private fun pushMask() {
        if (!dead) {
            RetroBridge.nativeSetButtons(virtualMask or physicalMask)
        }
    }
}
