package com.peraatmuu.app.emulator

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build

/**
 * Thread que drena o buffer de áudio PCM do núcleo para o AudioTrack.
 * O tamanho do buffer do AudioTrack também atua como regulador de ritmo.
 */
class AudioPlayer(private val sampleRate: Int) : Thread("PeraatMuuAudio") {

    @Volatile
    var running = true
        private set

    private val bufferSize: Int
    private val track: AudioTrack
    private val chunk = ByteArray(8192)

    init {
        val min = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        bufferSize = maxOf(min, 16384)
        track = createTrack(sampleRate, bufferSize)
    }

    private fun createTrack(rate: Int, size: Int): AudioTrack {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(rate)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                        .build()
                )
                .setBufferSizeInBytes(size)
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()
        } else {
            @Suppress("DEPRECATION")
            AudioTrack(
                AudioManager.STREAM_MUSIC, rate,
                AudioFormat.CHANNEL_OUT_STEREO,
                AudioFormat.ENCODING_PCM_16BIT, size,
                AudioTrack.MODE_STREAM,
            )
        }
    }

    override fun run() {
        try {
            track.play()
        } catch (e: Exception) {
            return
        }
        while (running) {
            val n = RetroBridge.nativeReadAudio(chunk, chunk.size)
            if (n > 0) {
                track.write(chunk, 0, n)
            } else {
                try {
                    sleep(2)
                } catch (_: InterruptedException) {
                    break
                }
            }
        }
        try {
            track.pause()
            track.flush()
            track.stop()
            track.release()
        } catch (_: Exception) {
        }
    }

    fun shutdown() {
        running = false
        interrupt()
        try {
            join(800)
        } catch (_: InterruptedException) {
        }
    }
}
