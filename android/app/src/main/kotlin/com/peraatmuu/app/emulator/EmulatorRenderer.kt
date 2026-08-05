package com.peraatmuu.app.emulator

import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.max
import kotlin.math.min

/**
 * Desenha o framebuffer RGBA do núcleo em uma textura OpenGL.
 * Suporta modos de escala (ajustar/preencher/recortar/preciso) e ajustes
 * de cor (brilho, contraste, saturação) direto no fragment shader.
 */
class EmulatorRenderer : GLSurfaceView.Renderer {

    private var program = 0
    private var textureId = 0
    private var surfaceW = 1
    private var surfaceH = 1
    private var texW = 0
    private var texH = 0
    private var frameBuffer: ByteBuffer? = null
    private val info = IntArray(4)

    var scaleMode: Int = EmuSettings.SCALE_FIT
        set(v) { field = v }
    var brightness: Float = 0f
    var contrast: Float = 1f
    var saturation: Float = 1f

    private lateinit var posBuffer: FloatBuffer
    private lateinit var uvBuffer: FloatBuffer

    companion object {
        private const val TAG = "EmulatorRenderer"

        private const val VERTEX_SHADER = """
            attribute vec2 aPos;
            attribute vec2 aUV;
            varying vec2 vUV;
            void main() {
                gl_Position = vec4(aPos, 0.0, 1.0);
                vUV = aUV;
            }
        """

        private const val FRAGMENT_SHADER = """
            precision mediump float;
            varying vec2 vUV;
            uniform sampler2D uTex;
            uniform float uBrightness;
            uniform float uContrast;
            uniform float uSaturation;
            void main() {
                vec4 c = texture2D(uTex, vUV);
                vec3 rgb = c.rgb;
                // contraste em torno do cinza 0.5
                rgb = (rgb - 0.5) * uContrast + 0.5;
                // brilho aditivo
                rgb = rgb + uBrightness;
                // saturação via luminância
                float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
                rgb = mix(vec3(lum), rgb, uSaturation);
                gl_FragColor = vec4(clamp(rgb, 0.0, 1.0), c.a);
            }
        """

        private val POS_TEMPLATE = floatArrayOf(
            -1f, -1f,
            1f, -1f,
            -1f, 1f,
            1f, 1f,
        )

        private val UV = floatArrayOf(
            0f, 1f,
            1f, 1f,
            0f, 0f,
            1f, 0f,
        )
    }

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        program = buildProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        uvBuffer = floatBufferOf(UV)
        posBuffer = floatBufferOf(POS_TEMPLATE)
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        surfaceW = maxOf(1, width)
        surfaceH = maxOf(1, height)
        GLES20.glViewport(0, 0, surfaceW, surfaceH)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        RetroBridge.nativeFrameInfo(info)
        val w = info[0]
        val h = info[1]
        if (w <= 0 || h <= 0) return

        var buffer = frameBuffer
        if (buffer == null || buffer.capacity() < w * h * 4) {
            buffer = ByteBuffer.allocateDirect(w * h * 4).order(ByteOrder.nativeOrder())
            frameBuffer = buffer
            texW = 0
            texH = 0
        }
        buffer.clear()

        val updated = RetroBridge.nativeCopyFrame(buffer)
        buffer.position(0)

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        if (updated || texW != w || texH != h) {
            if (texW != w || texH != h) {
                GLES20.glTexImage2D(
                    GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, w, h, 0,
                    GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer
                )
                texW = w
                texH = h
            } else {
                GLES20.glTexSubImage2D(
                    GLES20.GL_TEXTURE_2D, 0, 0, 0, w, h,
                    GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer
                )
            }
        }

        // Proporção declarada pelo núcleo (0 = quadrada)
        val coreAspect = if (info[3] > 0) info[3] / 1000f else w.toFloat() / h.toFloat()
        val displayAspect = if (coreAspect > 0f) coreAspect else w.toFloat() / h.toFloat()

        val layout = computeLayout(w, h, displayAspect)

        posBuffer.clear()
        posBuffer.put(layout.pos)
        posBuffer.position(0)
        uvBuffer.clear()
        uvBuffer.put(layout.uv)
        uvBuffer.position(0)

        GLES20.glUseProgram(program)
        val aPos = GLES20.glGetAttribLocation(program, "aPos")
        val aUV = GLES20.glGetAttribLocation(program, "aUV")
        val uTex = GLES20.glGetUniformLocation(program, "uTex")
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "uBrightness"), brightness)
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "uContrast"), contrast)
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "uSaturation"), saturation)

        GLES20.glEnableVertexAttribArray(aPos)
        GLES20.glVertexAttribPointer(aPos, 2, GLES20.GL_FLOAT, false, 0, posBuffer)
        GLES20.glEnableVertexAttribArray(aUV)
        GLES20.glVertexAttribPointer(aUV, 2, GLES20.GL_FLOAT, false, 0, uvBuffer)
        GLES20.glUniform1i(uTex, 0)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(aPos)
        GLES20.glDisableVertexAttribArray(aUV)
    }

    private data class Layout(val pos: FloatArray, val uv: FloatArray)

    private fun computeLayout(frameW: Int, frameH: Int, displayAspect: Float): Layout {
        val surfaceAspect = surfaceW.toFloat() / surfaceH.toFloat()
        return when (scaleMode) {
            EmuSettings.SCALE_FILL -> {
                // Estica tudo
                Layout(
                    POS_TEMPLATE.copyOf(),
                    UV.copyOf(),
                )
            }
            EmuSettings.SCALE_CROP -> {
                // Preenche a tela mantendo proporção (recorta o excedente)
                var uvW = 1f
                var uvH = 1f
                if (surfaceAspect > displayAspect) {
                    uvH = displayAspect / surfaceAspect
                } else {
                    uvW = surfaceAspect / displayAspect
                }
                val u0 = (1f - uvW) / 2f
                val v0 = (1f - uvH) / 2f
                Layout(
                    POS_TEMPLATE.copyOf(),
                    floatArrayOf(
                        u0, 1f - v0,
                        1f - u0, 1f - v0,
                        u0, v0,
                        1f - u0, v0,
                    ),
                )
            }
            EmuSettings.SCALE_INTEGER -> {
                // Escala inteira em pixels exatos (nunca distorce nem serra)
                val scaleX = max(1f, (surfaceW / frameW).toFloat())
                val scaleY = max(1f, (surfaceH / frameH).toFloat())
                val scale = min(scaleX, scaleY).toInt().coerceAtLeast(1)
                val drawW = frameW * scale
                val drawH = frameH * scale
                val sx = drawW.toFloat() / surfaceW
                val sy = drawH.toFloat() / surfaceH
                Layout(
                    floatArrayOf(-sx, -sy, sx, -sy, -sx, sy, sx, sy),
                    UV.copyOf(),
                )
            }
            else -> {
                // FIT: mantém proporção com letterbox/pillarbox
                var sx = 1f
                var sy = 1f
                if (surfaceAspect > displayAspect) {
                    sx = displayAspect / surfaceAspect
                } else {
                    sy = surfaceAspect / displayAspect
                }
                Layout(
                    floatArrayOf(-sx, -sy, sx, -sy, -sx, sy, sx, sy),
                    UV.copyOf(),
                )
            }
        }
    }

    private fun floatBufferOf(values: FloatArray): FloatBuffer =
        ByteBuffer.allocateDirect(values.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(values)
                position(0)
            }

    private fun buildProgram(vertexSrc: String, fragmentSrc: String): Int {
        val vertex = compileShader(GLES20.GL_VERTEX_SHADER, vertexSrc)
        val fragment = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSrc)
        val prog = GLES20.glCreateProgram()
        GLES20.glAttachShader(prog, vertex)
        GLES20.glAttachShader(prog, fragment)
        GLES20.glLinkProgram(prog)
        val status = IntArray(1)
        GLES20.glGetProgramiv(prog, GLES20.GL_LINK_STATUS, status, 0)
        if (status[0] == 0) {
            Log.e(TAG, "Falha ao linkar programa GL: " + GLES20.glGetProgramInfoLog(prog))
        }
        GLES20.glDeleteShader(vertex)
        GLES20.glDeleteShader(fragment)
        return prog
    }

    private fun compileShader(type: Int, src: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, src)
        GLES20.glCompileShader(shader)
        val status = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, status, 0)
        if (status[0] == 0) {
            Log.e(TAG, "Falha ao compilar shader: " + GLES20.glGetShaderInfoLog(shader))
        }
        return shader
    }
}
