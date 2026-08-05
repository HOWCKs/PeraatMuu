package com.peraatmuu.app.emulator

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.min

/**
 * Controles virtuais na tela (estilo neon) com suporte a multitoque.
 * Botões extras de menu são tratados pelo callback dedicado.
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
    }

    data class OverlayButton(
        val id: Int,
        val label: String,
        val rect: RectF,
        val circular: Boolean,
        val accent: Int,
    )

    var onButtonsChanged: ((Int) -> Unit)? = null
    var onMenuPressed: (() -> Unit)? = null

    private val buttons = mutableListOf<OverlayButton>()
    private var menuRect = RectF()
    private val pressed = mutableSetOf<Int>()
    private var menuPressed = false
    private var lastMask = 0

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
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
        isFakeBoldText = true
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        buttons.clear()
        val cy = h * 0.74f
        val btnR = h * 0.085f

        // --- D-pad (esquerda) ---
        val padCx = w * 0.14f
        val arm = h * 0.155f
        val dAccent = Color.parseColor("#00F5D4")
        buttons += OverlayButton(BTN_UP, "▲", RectF(padCx - btnR, cy - arm - btnR, padCx + btnR, cy - arm + btnR), false, dAccent)
        buttons += OverlayButton(BTN_DOWN, "▼", RectF(padCx - btnR, cy + arm - btnR, padCx + btnR, cy + arm + btnR), false, dAccent)
        buttons += OverlayButton(BTN_LEFT, "◀", RectF(padCx - arm - btnR, cy - btnR, padCx - arm + btnR, cy + btnR), false, dAccent)
        buttons += OverlayButton(BTN_RIGHT, "▶", RectF(padCx + arm - btnR, cy - btnR, padCx + arm + btnR, cy + btnR), false, dAccent)

        // --- Botões de ação (direita) em losango ---
        val actCx = w * 0.86f
        val actArm = h * 0.16f
        buttons += OverlayButton(BTN_X, "X", RectF(actCx - btnR, cy - actArm - btnR, actCx + btnR, cy - actArm + btnR), true, Color.parseColor("#7B2FFF"))
        buttons += OverlayButton(BTN_B, "B", RectF(actCx - btnR, cy + actArm - btnR, actCx + btnR, cy + actArm + btnR), true, Color.parseColor("#F9F871"))
        buttons += OverlayButton(BTN_Y, "Y", RectF(actCx - actArm - btnR, cy - btnR, actCx - actArm + btnR, cy + btnR), true, Color.parseColor("#F9F871"))
        buttons += OverlayButton(BTN_A, "A", RectF(actCx + actArm - btnR, cy - btnR, actCx + actArm + btnR, cy + btnR), true, Color.parseColor("#FF2E88"))

        // --- Ombros L / R (topo) ---
        val shH = h * 0.045f
        buttons += OverlayButton(BTN_L, "L", RectF(w * 0.03f, shH, w * 0.25f, shH + h * 0.085f), false, Color.parseColor("#FF2E88"))
        buttons += OverlayButton(BTN_R, "R", RectF(w * 0.75f, shH, w * 0.97f, shH + h * 0.085f), false, Color.parseColor("#FF2E88"))

        // --- Start / Select (centro inferior) ---
        val ssY = h * 0.90f
        val ssW = w * 0.075f
        val ssH = h * 0.04f
        buttons += OverlayButton(BTN_SELECT, "SELECT", RectF(w * 0.5f - ssW - dp(8), ssY - ssH, w * 0.5f - dp(8), ssY + ssH), false, Color.parseColor("#00F5D4"))
        buttons += OverlayButton(BTN_START, "START", RectF(w * 0.5f + dp(8), ssY - ssH, w * 0.5f + ssW + dp(8), ssY + ssH), false, Color.parseColor("#00F5D4"))

        // --- Menu (centro superior) ---
        val mR = h * 0.05f
        menuRect = RectF(w * 0.5f - mR, h * 0.03f, w * 0.5f + mR, h * 0.03f + 2 * mR)

        textPaint.textSize = min(w, h) * 0.045f
    }

    private fun dp(v: Int): Float = v * resources.displayMetrics.density

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        for (b in buttons) {
            val isPressed = pressed.contains(b.id)
            strokePaint.color = b.accent
            strokePaint.alpha = if (isPressed) 255 else 140
            if (isPressed) {
                pressedPaint.color = b.accent
                pressedPaint.alpha = 110
                if (b.circular) {
                    canvas.drawCircle(b.rect.centerX(), b.rect.centerY(), b.rect.width() / 2f, pressedPaint)
                } else {
                    canvas.drawRoundRect(b.rect, 18f, 18f, pressedPaint)
                }
            }
            if (b.circular) {
                canvas.drawCircle(b.rect.centerX(), b.rect.centerY(), b.rect.width() / 2f, fillPaint)
                canvas.drawCircle(b.rect.centerX(), b.rect.centerY(), b.rect.width() / 2f, strokePaint)
            } else {
                canvas.drawRoundRect(b.rect, 18f, 18f, fillPaint)
                canvas.drawRoundRect(b.rect, 18f, 18f, strokePaint)
            }
            textPaint.alpha = if (isPressed) 255 else 190
            val ty = b.rect.centerY() - (textPaint.descent() + textPaint.ascent()) / 2f
            canvas.drawText(b.label, b.rect.centerX(), ty, textPaint)
        }

        // Botão de menu
        strokePaint.color = Color.WHITE
        strokePaint.alpha = if (menuPressed) 255 else 120
        fillPaint.alpha = if (menuPressed) 90 else 38
        canvas.drawCircle(menuRect.centerX(), menuRect.centerY(), menuRect.width() / 2f, fillPaint)
        canvas.drawCircle(menuRect.centerX(), menuRect.centerY(), menuRect.width() / 2f, strokePaint)
        textPaint.alpha = 200
        val my = menuRect.centerY() - (textPaint.descent() + textPaint.ascent()) / 2f
        canvas.drawText("≡", menuRect.centerX(), my, textPaint)
        fillPaint.alpha = 38
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
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

    private fun recompute(event: MotionEvent) {
        pressed.clear()
        var menuNow = false
        for (i in 0 until event.pointerCount) {
            val x = event.getX(i)
            val y = event.getY(i)
            if (menuRect.contains(x, y)) {
                menuNow = true
                continue
            }
            for (b in buttons) {
                if (b.rect.contains(x, y)) {
                    pressed.add(b.id)
                    break
                }
            }
        }
        // Dispara o menu apenas na transição solta→pressionado
        if (menuNow && !menuPressed) {
            onMenuPressed?.invoke()
            performHapticFeedback(android.view.HapticFeedbackConstants.VIRTUAL_KEY)
        }
        menuPressed = menuNow
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
