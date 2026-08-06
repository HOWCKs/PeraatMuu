package com.peraatmuu.app.emulator

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.Paint
import android.graphics.Color
import android.graphics.RectF
import android.util.AttributeSet
import android.util.LruCache
import android.graphics.drawable.Drawable
import android.util.SparseArray
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import com.peraatmuu.app.R
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.math.min

/**
 * Controles virtuais na tela (estilo neon) com multitoque, feedback tátil
 * e personalização completa: posição (arrastar), tamanho, ícone por texto
 * ou imagem importada da memória. O layout é persistido automaticamente.
 */
class ControlsOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : View(context, attrs) {

    // IDs do joypad libretro
    companion object {
        const val BTN_B = 0
        const val BTN_Y = 1
        const val BTN_SELECT = 2
        const val BTN_START = 3
        const val BTN_UP = 4
        const val BTN_DOWN = 5
        const val BTN_LEFT = 6
        const val BTN_RIGHT = 7
        const val BTN_A = 8
        const val BTN_X = 9
        const val BTN_L = 10
        const val BTN_R = 11
        const val BTN_L2 = 12
        const val BTN_R2 = 13

        /** Consoles cujo controle original só tem 2 botões de ação. */
        private val SIMPLE_AB_SYSTEMS = setOf(
            "a26", "nes", "sms", "gg", "pce", "gb", "lynx", "ngp", "wswan",
        )

        /** Preset do editor: texto (iconRes=0) ou ícone vetorial. */
        data class Preset(val label: String, val iconRes: Int = 0)

        /** Ícones disponíveis no editor — vetores desenhados, sem emoji. */
        val PRESETS = listOf(
            Preset("A"), Preset("B"), Preset("X"), Preset("Y"),
            Preset("L"), Preset("R"), Preset("L2"), Preset("R2"),
            Preset("A+"), Preset("B+"), Preset("START"), Preset("SELECT"),
            Preset("MENU"), Preset("TURBO"), Preset("FF"), Preset("SAVE"),
            Preset("▲", R.drawable.ic_ui_tri_up),
            Preset("▼", R.drawable.ic_ui_tri_down),
            Preset("◀", R.drawable.ic_ui_tri_left),
            Preset("▶", R.drawable.ic_ui_tri_right),
            Preset("↻", R.drawable.ic_ui_restart),
            Preset("⊕", R.drawable.ic_ui_add_circle),
            Preset("★", R.drawable.ic_ui_star),
            Preset("❚❚", R.drawable.ic_ui_pause),
            Preset("▶|", R.drawable.ic_ui_play_end),
            Preset("⚡", R.drawable.ic_ui_bolt),
        )

        /** Migra glifos antigos (layout salvo em versões anteriores) para vetor. */
        fun iconForGlyph(label: String): Int =
            PRESETS.firstOrNull { it.iconRes != 0 && it.label == label }?.iconRes ?: 0
    }

    /** Um botão configurável: posição em fração da tela, tamanho em fração
     * da menor dimensão, rótulo ou imagem personalizada. */
    data class ButtonCfg(
        val id: Int,
        var label: String,
        var cx: Float,      // centro X em fração da largura
        var cy: Float,      // centro Y em fração da altura
        var size: Float,    // largura em fração da menor dimensão
        var circular: Boolean,
        var accent: Int,
        var image: String = "",  // caminho de PNG personalizado ("" = texto/ícone)
        var icon: Int = 0,       // drawable vetorial (0 = rótulo de texto)
    )

    var onButtonsChanged: ((Int) -> Unit)? = null
    var onMenuPressed: (() -> Unit)? = null
    var onButtonEditRequested: ((ButtonCfg) -> Unit)? = null

    /** Console em emulação: define o layout padrão (conjunto de botões)
     * e ONDE o layout editado é salvo (cada console guarda o seu). */
    var systemId: String = "generic"
        set(value) {
            if (field == value) return
            field = value
            buttons.clear()  // força reload no próximo onSizeChanged
            loadLayout()
            invalidate()
        }

    /** Toque na área do jogo (fora dos botões): usado pela tela sensível
     * ao toque do Nintendo DS. Ação = ACTION_DOWN/MOVE/UP. */
    var onScreenTouch: ((x: Float, y: Float, action: Int) -> Unit)? = null

    /** Quando true: arrastar = mover botões, toque rápido = personalizar
     * (sem enviar entrada ao jogo). */
    var editMode = false
        set(value) {
            field = value
            invalidate()
        }

    private val buttons = mutableListOf<ButtonCfg>()
    private var menuRect = RectF()
    private val pressed = mutableSetOf<Int>()
    private var menuPressed = false
    private var lastMask = 0

    // ponteiro que caiu na área do jogo (touch do DS)
    private var screenPointerId = -1

    // rastreio de drag no modo edição (por ponteiro)
    private var editSelectedId: Int = -1
    private var editTouchStartX = 0f
    private var editTouchStartY = 0f
    private var editMoved = false

    private val imageCache = LruCache<String, Bitmap>(8)

    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.argb(38, 255, 255, 255)
    }
    private val pressedPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3f
    }
    private val editStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 4f
        color = Color.parseColor("#00F5D4")
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
        isFakeBoldText = true
    }
    private val hintPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
    }
    private val imagePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val srcRect = Rect()
    private val dstRect = Rect()

    // cache de drawables vetoriais dos presets
    private val iconCache = SparseArray<Drawable>()

    init {
        // Listener padrão de detecção de haptics habilitado para o toque leve
        isHapticFeedbackEnabled = true
    }

    // ---------------------------------------------------------------
    // Layout padrão / persistência
    // ---------------------------------------------------------------

    private fun defaultLayout(): MutableList<ButtonCfg> {
        val dAccent = Color.parseColor("#00F5D4")
        val purple = Color.parseColor("#7B2FFF")
        val yellow = Color.parseColor("#F9F871")
        val pink = Color.parseColor("#FF2E88")
        val list = mutableListOf<ButtonCfg>()
        val simpleAb = systemId in SIMPLE_AB_SYSTEMS

        // D-pad (esquerda) — ícones vetoriais (triângulos)
        list += ButtonCfg(BTN_UP, "▲", 0.14f, 0.585f, 0.17f, false, dAccent,
            icon = R.drawable.ic_ui_tri_up)
        list += ButtonCfg(BTN_DOWN, "▼", 0.14f, 0.895f, 0.17f, false, dAccent,
            icon = R.drawable.ic_ui_tri_down)
        list += ButtonCfg(BTN_LEFT, "◀", 0.055f, 0.74f, 0.17f, false, dAccent,
            icon = R.drawable.ic_ui_tri_left)
        list += ButtonCfg(BTN_RIGHT, "▶", 0.225f, 0.74f, 0.17f, false, dAccent,
            icon = R.drawable.ic_ui_tri_right)

        // Ações (direita) em losango — consoles de 2 botões ganham só A/B
        if (!simpleAb) {
            list += ButtonCfg(BTN_X, "X", 0.86f, 0.58f, 0.17f, true, purple)
            list += ButtonCfg(BTN_Y, "Y", 0.775f, 0.74f, 0.17f, true, yellow)
        }
        list += ButtonCfg(BTN_B, "B", 0.86f, 0.90f, 0.17f, true, yellow)
        list += ButtonCfg(BTN_A, "A", 0.945f, 0.74f, 0.17f, true, pink)

        // Ombros: consoles 8/16-bit simples não tinham
        if (!simpleAb) {
            list += ButtonCfg(BTN_L, "L", 0.14f, 0.085f, 0.09f, false, pink)
            list += ButtonCfg(BTN_R, "R", 0.86f, 0.085f, 0.09f, false, pink)
        }

        // L2/R2: PS1 usa os dois; no N64 o gatilho Z costuma ir no L2
        if (systemId == "ps1") {
            list += ButtonCfg(BTN_L2, "L2", 0.30f, 0.075f, 0.08f, false, pink)
            list += ButtonCfg(BTN_R2, "R2", 0.70f, 0.075f, 0.08f, false, pink)
        }
        if (systemId == "n64") {
            list += ButtonCfg(BTN_L2, "Z", 0.30f, 0.075f, 0.08f, false, pink)
        }

        // Start/Select — ícones vetoriais
        list += ButtonCfg(BTN_SELECT, "⊕", 0.43f, 0.90f, 0.085f, false, dAccent,
            icon = R.drawable.ic_ui_add_circle)
        list += ButtonCfg(BTN_START, "▶|", 0.57f, 0.90f, 0.085f, false, dAccent,
            icon = R.drawable.ic_ui_play_end)
        return list
    }

    private fun loadLayout() {
        val json = EmuSettings.controlsLayoutFor(systemId)
        if (json.isBlank()) {
            buttons.clear()
            buttons.addAll(defaultLayout())
            return
        }
        try {
            val arr = JSONArray(json)
            buttons.clear()
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val label = o.optString("label", "?")
                val icon = o.optInt("icon", 0).let { if (it == 0) iconForGlyph(label) else it }
                buttons.add(
                    ButtonCfg(
                        id = o.getInt("id"),
                        label = label,
                        cx = o.getDouble("cx").toFloat(),
                        cy = o.getDouble("cy").toFloat(),
                        size = o.getDouble("size").toFloat(),
                        circular = o.optBoolean("circular", true),
                        accent = o.optInt("accent", Color.parseColor("#00F5D4")),
                        image = o.optString("image", ""),
                        icon = icon,
                    ),
                )
            }
            // Garante presença de botões essenciais após migrações de versão
            val ids = buttons.map { it.id }.toSet()
            defaultLayout().filter { !ids.contains(it.id) }.forEach { buttons.add(it) }
        } catch (ignored: Exception) {
            buttons.clear()
            buttons.addAll(defaultLayout())
        }
    }

    fun saveLayout() {
        val arr = JSONArray()
        for (b in buttons) {
            arr.put(JSONObject().apply {
                put("id", b.id)
                put("label", b.label)
                put("cx", b.cx.toDouble())
                put("cy", b.cy.toDouble())
                put("size", b.size.toDouble())
                put("circular", b.circular)
                put("accent", b.accent)
                put("image", b.image)
                put("icon", b.icon)
            })
        }
        EmuSettings.setControlsLayoutFor(systemId, arr.toString())
    }

    fun resetLayout() {
        EmuSettings.setControlsLayoutFor(systemId, "")
        imageCache.evictAll()
        loadLayout()
        invalidate()
    }

    /** Configura um botão (chamada do diálogo de personalização). */
    fun updateButton(cfg: ButtonCfg) {
        val idx = buttons.indexOfFirst { it.id == cfg.id }
        if (idx >= 0) {
            buttons[idx] = cfg
            if (cfg.image.isBlank()) imageCache.remove(cfg.id.toString())
            saveLayout()
            invalidate()
        }
    }

    // ---------------------------------------------------------------
    // Render e toque
    // ---------------------------------------------------------------

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        if (buttons.isEmpty()) loadLayout()
        val mR = h * 0.055f
        menuRect = RectF(w * 0.5f - mR, h * 0.03f, w * 0.5f + mR, h * 0.03f + 2 * mR)
        textPaint.textSize = min(w, h) * 0.055f
        hintPaint.textSize = min(w, h) * 0.035f
    }

    private fun rectOf(b: ButtonCfg): RectF {
        val w = width.toFloat()
        val h = height.toFloat()
        val m = min(w, h)
        val half = b.size * m / 2f
        val cx = b.cx * w
        val cy = b.cy * h
        // L/R são retângulos largos clássicos
        return if (!b.circular) {
            RectF(cx - half * 1.25f, cy - half, cx + half * 1.25f, cy + half)
        } else {
            RectF(cx - half, cy - half, cx + half, cy + half)
        }
    }

    private fun bitmapFor(b: ButtonCfg): Bitmap? {
        if (b.image.isBlank()) return null
        val key = b.id.toString()
        return imageCache.get(key) ?: run {
            val f = File(b.image)
            if (!f.exists()) null else {
                val full = BitmapFactory.decodeFile(f.absolutePath) ?: return null
                val targetPx = (min(width, height) * b.size).toInt().coerceAtLeast(16)
                val scaled = Bitmap.createScaledBitmap(full, targetPx, targetPx, true)
                imageCache.put(key, scaled)
                scaled
            }
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        for (b in buttons) {
            val rect = rectOf(b)
            val isPressed = pressed.contains(b.id) && !editMode
            val selected = editMode && editSelectedId == b.id

            strokePaint.color = b.accent
            strokePaint.alpha = if (isPressed || selected) 255 else 140
            if (isPressed) {
                pressedPaint.color = b.accent
                pressedPaint.alpha = 110
                drawShape(canvas, b, rect, pressedPaint)
            }
            drawShape(canvas, b, rect, fillPaint)
            drawShape(canvas, b, rect, strokePaint)

            // imagem personalizada, ícone vetorial ou texto
            val bmp = bitmapFor(b)
            when {
                bmp != null -> {
                    val pad = rect.width() * 0.12f
                    srcRect.set(0, 0, bmp.width, bmp.height)
                    dstRect.set(
                        (rect.left + pad).toInt(), (rect.top + pad).toInt(),
                        (rect.right - pad).toInt(), (rect.bottom - pad).toInt(),
                    )
                    imagePaint.alpha = if (isPressed) 255 else 220
                    canvas.drawBitmap(bmp, srcRect, dstRect, imagePaint)
                }
                b.icon != 0 -> drawIcon(canvas, b.icon, rect, isPressed)
                else -> {
                    textPaint.alpha = if (isPressed) 255 else 190
                    textPaint.textSize = labelSizeFor(b)
                    val ty = rect.centerY() - (textPaint.descent() + textPaint.ascent()) / 2f
                    canvas.drawText(b.label, rect.centerX(), ty, textPaint)
                }
            }

            if (selected) {
                drawShape(canvas, b, rect, editStrokePaint)
            }
        }

        // Botão de menu
        strokePaint.color = Color.WHITE
        strokePaint.alpha = if (menuPressed) 255 else 120
        fillPaint.alpha = if (menuPressed) 90 else 38
        val mcx = menuRect.centerX()
        val mcy = menuRect.centerY()
        val mr = menuRect.width() / 2f
        canvas.drawCircle(mcx, mcy, mr, fillPaint)
        canvas.drawCircle(mcx, mcy, mr, strokePaint)
        drawIcon(canvas, R.drawable.ic_ui_menu, menuRect, menuPressed)
        fillPaint.alpha = 38

        // Dicas do modo edição
        if (editMode) {
            canvas.drawColor(Color.argb(30, 0, 0, 0))
            canvas.drawText(
                "MODO EDIÇÃO — arraste os botões, toque num botão para personalizar",
                width / 2f,
                menuRect.bottom + hintPaint.textSize * 1.6f,
                hintPaint,
            )
        }
    }

    private fun drawShape(canvas: Canvas, b: ButtonCfg, rect: RectF, paint: Paint) {
        if (b.circular) {
            canvas.drawCircle(rect.centerX(), rect.centerY(), rect.width() / 2f, paint)
        } else {
            canvas.drawRoundRect(rect, 18f, 18f, paint)
        }
    }

    /** Desenha um ícone vetorial (drawable) centralizado no botão. */
    private fun drawIcon(canvas: Canvas, iconRes: Int, rect: RectF, active: Boolean) {
        var d = iconCache.get(iconRes)
        if (d == null) {
            d = context.getDrawable(iconRes)?.mutate() ?: return
            iconCache.put(iconRes, d)
        }
        val side = rect.width() * 0.52f
        val l = rect.centerX() - side / 2f
        val t = rect.centerY() - side / 2f
        d.setBounds(l.toInt(), t.toInt(), (l + side).toInt(), (t + side).toInt())
        d.setTint(Color.argb(if (active) 255 else 205, 255, 255, 255))
        d.alpha = if (active) 255 else 205
        d.draw(canvas)
    }

    /** true se o ponto cai num botão ou no menu (usado p/ rotear o touch). */
    fun hitControl(x: Float, y: Float): Boolean =
        menuRect.contains(x, y) || findButtonAt(x, y) != null

    private fun labelSizeFor(b: ButtonCfg): Float {
        val rect = rectOf(b)
        val base = rect.width() * if (b.label.length > 1) 0.20f else 0.40f
        return base.coerceIn(14f, 90f)
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (editMode) {
            handleEditTouch(event)
            invalidate()
            return true
        }
        routeScreenTouch(event)
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN,
            MotionEvent.ACTION_MOVE, MotionEvent.ACTION_UP,
            MotionEvent.ACTION_POINTER_UP, MotionEvent.ACTION_CANCEL -> {
                recompute(event)
                if (event.actionMasked == MotionEvent.ACTION_UP ||
                    event.actionMasked == MotionEvent.ACTION_CANCEL
                ) {
                    menuPressed = false
                    pressed.clear()
                    publish()
                }
                invalidate()
            }
        }
        return true
    }

    /** Repassa ao jogo os toques na área do vídeo (fora de botões) —
     *  é o que faz a tela sensível ao toque do Nintendo DS funcionar. */
    private fun routeScreenTouch(event: MotionEvent) {
        val cb = onScreenTouch ?: return
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                val i = event.actionIndex
                val x = event.getX(i)
                val y = event.getY(i)
                if (!hitControl(x, y)) {
                    screenPointerId = event.getPointerId(i)
                    cb(x, y, MotionEvent.ACTION_DOWN)
                }
            }
            MotionEvent.ACTION_MOVE -> {
                if (screenPointerId >= 0) {
                    val pi = event.findPointerIndex(screenPointerId)
                    if (pi >= 0) cb(event.getX(pi), event.getY(pi), MotionEvent.ACTION_MOVE)
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP,
            MotionEvent.ACTION_CANCEL -> {
                if (screenPointerId >= 0) {
                    val pi = event.findPointerIndex(screenPointerId)
                    if (pi >= 0) {
                        cb(event.getX(pi), event.getY(pi), MotionEvent.ACTION_UP)
                    } else {
                        cb(-1f, -1f, MotionEvent.ACTION_UP)
                    }
                    screenPointerId = -1
                }
            }
        }
    }

    // -------------------------------------------------------------- edição

    private fun handleEditTouch(event: MotionEvent) {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                editMoved = false
                val x = event.getX(0)
                val y = event.getY(0)
                if (menuRect.contains(x, y)) {
                    menuPressed = true
                    editSelectedId = -1
                    return
                }
                editTouchStartX = x
                editTouchStartY = y
                editSelectedId = findButtonAt(x, y)?.id ?: -1
            }
            MotionEvent.ACTION_MOVE -> {
                if (editSelectedId >= 0) {
                    val idx = buttons.indexOfFirst { it.id == editSelectedId }
                    if (idx >= 0) {
                        val x = event.getX(0)
                        val y = event.getY(0)
                        val dx = x - editTouchStartX
                        val dy = y - editTouchStartY
                        if (dx * dx + dy * dy > 12f) editMoved = true
                        editTouchStartX = x
                        editTouchStartY = y
                        val b = buttons[idx]
                        b.cx = (b.cx + dx / width).coerceIn(0.03f, 0.97f)
                        b.cy = (b.cy + dy / height).coerceIn(0.03f, 0.97f)
                    }
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (menuPressed) {
                    menuPressed = false
                    performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                    onMenuPressed?.invoke()
                    return
                }
                if (editSelectedId >= 0 && !editMoved) {
                    val cfg = buttons.firstOrNull { it.id == editSelectedId }
                    if (cfg != null) onButtonEditRequested?.invoke(cfg.copy())
                }
                if (editMoved) saveLayout()
                editSelectedId = -1
            }
        }
    }

    private fun findButtonAt(x: Float, y: Float): ButtonCfg? {
        // busca de trás pra frente = botões desenhados por cima têm prioridade
        for (b in buttons.asReversed()) {
            if (rectOf(b).contains(x, y)) return b
        }
        return null
    }

    // --------------------------------------------------------------- jogo

    private fun recompute(event: MotionEvent) {
        val nowPressed = mutableSetOf<Int>()
        var menuNow = false
        for (i in 0 until event.pointerCount) {
            val x = event.getX(i)
            val y = event.getY(i)
            if (menuRect.contains(x, y)) {
                menuNow = true
                continue
            }
            val hit = findButtonAt(x, y)
            if (hit != null) nowPressed.add(hit.id)
        }
        // Dispara o menu apenas na transição solta→pressionado
        if (menuNow && !menuPressed) {
            performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
            onMenuPressed?.invoke()
        }
        menuPressed = menuNow

        // Feedback tátil ao pressionar um botão NOVO (resposta melhor ao toque)
        val added = nowPressed.any { !pressed.contains(it) }
        pressed.clear()
        pressed.addAll(nowPressed)
        if (added) {
            performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
        }
        publish()
    }

    private fun publish() {
        var mask = 0
        for (id in pressed) {
            mask = mask or (1 shl id)
        }
        if (mask != lastMask) {
            lastMask = mask
            onButtonsChanged?.invoke(mask)
        }
    }
}
