package com.peraatmuu.app.emulator

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.opengl.GLSurfaceView
import android.os.Bundle
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.Toast
import java.io.File
import kotlin.math.abs

/**
 * Tela de emulação real: núcleo libretro + OpenGL + áudio + controles
 * na tela e suporte a gamepads físicos (Bluetooth/USB).
 */
class GameActivity : Activity() {

    companion object {
        private const val EXTRA_CORE = "corePath"
        private const val EXTRA_ROM = "romPath"
        private const val EXTRA_SYSTEM = "systemId"

        fun createIntent(context: Context, corePath: String, romPath: String, systemId: String): Intent =
            Intent(context, GameActivity::class.java).apply {
                putExtra(EXTRA_CORE, corePath)
                putExtra(EXTRA_ROM, romPath)
                putExtra(EXTRA_SYSTEM, systemId)
            }
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
        // Teclado (mapa clássico: Z=B, X=A, A=Y, S=X, Enter=Start, Espaço=Select)
        KeyEvent.KEYCODE_Z to ControlsOverlayView.BTN_B,
        KeyEvent.KEYCODE_X to ControlsOverlayView.BTN_A,
        KeyEvent.KEYCODE_A to ControlsOverlayView.BTN_Y,
        KeyEvent.KEYCODE_S to ControlsOverlayView.BTN_X,
        KeyEvent.KEYCODE_ENTER to ControlsOverlayView.BTN_START,
        KeyEvent.KEYCODE_SPACE to ControlsOverlayView.BTN_SELECT,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        applyImmersive()

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
            RetroBridge.loadGame(romPath)
        } catch (e: EmulatorException) {
            Toast.makeText(this, e.message, Toast.LENGTH_LONG).show()
            dead = true
            finish()
            return
        }

        if (sramFile.exists()) {
            RetroBridge.nativeLoadRam(sramFile.absolutePath)
        }

        glView = GLSurfaceView(this).apply {
            setEGLContextClientVersion(2)
            renderer = EmulatorRenderer()
            setRenderer(renderer)
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }
        this.renderer = renderer

        controls = ControlsOverlayView(this).apply {
            onButtonsChanged = { mask ->
                virtualMask = mask
                pushMask()
            }
            onMenuPressed = { showGameMenu() }
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

        Toast.makeText(this, romName, Toast.LENGTH_SHORT).show()
        RetroBridge.nativeStart()
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

    override fun onResume() {
        super.onResume()
        applyImmersive()
        if (!dead) {
            if (::glView.isInitialized) glView.onResume()
            RetroBridge.nativeStart()
            startAudio()
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
        RetroBridge.nativeUnload()
    }

    // ------------------------------------------------------------------
    // Menu do jogo
    // ------------------------------------------------------------------

    private fun showGameMenu() {
        val items = arrayOf(
            "Continuar",
            "Salvar estado",
            "Carregar estado",
            "Reiniciar jogo",
            "Sair",
        )
        AlertDialog.Builder(this)
            .setTitle("PeraatMuu")
            .setItems(items) { dialog, which ->
                when (which) {
                    1 -> toast(
                        if (RetroBridge.nativeSaveState(stateFile.absolutePath)) "Estado salvo"
                        else "Não foi possível salvar"
                    )
                    2 -> toast(
                        when {
                            !stateFile.exists() -> "Nenhum estado salvo ainda"
                            RetroBridge.nativeLoadState(stateFile.absolutePath) -> "Estado carregado"
                            else -> "Falha ao carregar o estado"
                        }
                    )
                    3 -> RetroBridge.nativeReset()
                    4 -> finish()
                    else -> Unit
                }
                dialog.dismiss()
            }
            .setOnDismissListener { applyImmersive() }
            .show()
    }

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
