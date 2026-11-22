package com.pocketbrew.pocket_brew

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    companion object {
        private const val AUDIO_CHANNEL = "com.pocketbrew.pocket_brew/audio_cue"
        private const val SAMPLE_RATE = 44100
    }

    private val audioExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playCue" -> {
                        val type = call.argument<String>("type") ?: "test"
                        val remainingSec = call.argument<Int>("remainingSec") ?: 3
                        playNativeCueAsync(type, remainingSec)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        audioExecutor.shutdownNow()
        super.onDestroy()
    }

    private data class ToneSpec(
        val freqHz: Double,
        val delayMs: Int,
        val durationMs: Int,
        val gain: Double,
    )

    private fun playNativeCueAsync(type: String, remainingSec: Int) {
        if (audioExecutor.isShutdown) return
        val tones: List<ToneSpec> = when (type) {
            "countdown" -> {
                val isFinal = remainingSec <= 1
                listOf(
                    ToneSpec(
                        freqHz = if (isFinal) 783.99 else 587.33,
                        delayMs = 0,
                        durationMs = if (isFinal) 165 else 125,
                        gain = if (isFinal) 0.78 else 0.62,
                    )
                )
            }
            "pourStart" -> listOf(
                ToneSpec(523.25, 0, 165, 0.74),
                ToneSpec(783.99, 100, 290, 0.82),
            )
            "waitCue" -> listOf(
                ToneSpec(659.25, 0, 130, 0.56),
                ToneSpec(493.88, 95, 195, 0.52),
            )
            "drawdownTarget" -> listOf(
                ToneSpec(587.33, 0, 155, 0.68),
                ToneSpec(659.25, 125, 250, 0.72),
            )
            "finish" -> listOf(
                ToneSpec(523.25, 0, 160, 0.74),
                ToneSpec(659.25, 105, 195, 0.78),
                ToneSpec(783.99, 210, 380, 0.84),
            )
            else -> listOf(
                ToneSpec(523.25, 0, 130, 0.70),
                ToneSpec(659.25, 95, 220, 0.76),
            )
        }

        audioExecutor.execute {
            try {
                playSynthesizedTones(tones)
            } catch (_: Throwable) {
                // Never disrupt brew timer if device audio hardware is busy
            }
        }
    }

    private fun playSynthesizedTones(tones: List<ToneSpec>) {
        if (tones.isEmpty()) return
        val totalMs = tones.maxOf { it.delayMs + it.durationMs } + 40
        val totalSamples = (SAMPLE_RATE * totalMs) / 1000
        if (totalSamples <= 0) return

        val mix = DoubleArray(totalSamples)
        for (tone in tones) {
            val startIdx = (SAMPLE_RATE * tone.delayMs) / 1000
            val lenSamples = (SAMPLE_RATE * tone.durationMs) / 1000
            val attackSamples = (SAMPLE_RATE * 10) / 1000
            val omega = 2.0 * PI * tone.freqHz / SAMPLE_RATE

            for (i in 0 until lenSamples) {
                val idx = startIdx + i
                if (idx >= totalSamples) break
                val progress = i.toDouble() / lenSamples.toDouble()
                val attackEnv = if (i < attackSamples) {
                    i.toDouble() / attackSamples.coerceAtLeast(1).toDouble()
                } else {
                    1.0
                }
                val decayEnv = exp(-4.6 * progress)
                val sample =
                    (0.84 * sin(omega * i) + 0.16 * sin(2.0 * omega * i)) *
                        attackEnv * decayEnv * tone.gain
                mix[idx] += sample
            }
        }

        val pcm = ShortArray(totalSamples) { i ->
            val clamped = mix[i].coerceIn(-0.95, 0.95)
            (clamped * Short.MAX_VALUE).toInt().toShort()
        }

        val minBuf = AudioTrack.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val bufferSize = maxOf(minBuf, 4096)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val audioFormat = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()

        val track = AudioTrack(
            audioAttributes,
            audioFormat,
            bufferSize,
            AudioTrack.MODE_STREAM,
            AudioManager.AUDIO_SESSION_ID_GENERATE,
        )

        try {
            track.play()
            track.write(pcm, 0, pcm.size)
            Thread.sleep(totalMs.toLong() + 45L)
        } finally {
            try {
                track.stop()
            } catch (_: Throwable) {
            }
            track.release()
        }
    }
}
