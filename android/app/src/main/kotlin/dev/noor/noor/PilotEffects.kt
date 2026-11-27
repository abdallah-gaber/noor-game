package dev.noor.noor

import android.content.Context
import android.content.pm.ApplicationInfo
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.SystemClock
import android.util.Log
import io.flutter.FlutterInjector

internal class PilotEffects(private val context: Context) {
    private val holdMillis = mapOf("tap" to 66L, "correct" to 230L, "retry" to 158L, "complete" to 336L)
    private val samples = mutableMapOf<String, Int>()
    private val ready = mutableSetOf<Int>()
    private var pool: SoundPool? = null
    private var stream = 0
    private var protectUntil = 0L
    private var pending: String? = null

    fun play(name: String) {
        val duration = holdMillis[name] ?: return
        if (name == "tap" && SystemClock.uptimeMillis() < protectUntil) return
        val player = pool ?: SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build(),
            )
            .build().also { created ->
                pool = created
                created.setOnLoadCompleteListener { source, sample, status ->
                    if (pool === source && status == 0) {
                        ready += sample
                        val next = pending
                        if (next != null && samples[next] == sample) play(next)
                    }
                }
                val loader = FlutterInjector.instance().flutterLoader()
                for (effect in holdMillis.keys) {
                    val asset = loader.getLookupKeyForAsset("assets/audio/noor_$effect.wav")
                    try {
                        context.assets.openFd(asset).use { descriptor ->
                            val sample = created.load(descriptor, 1)
                            if (sample != 0) samples[effect] = sample
                        }
                    } catch (_: java.io.IOException) {
                        // Missing audio is optional and must not interrupt play.
                    }
                }
            }
        val sample = samples[name] ?: return
        if (sample !in ready) {
            pending = name
            return
        }
        stop()
        stream = player.play(sample, 1f, 1f, 1, 0, 1f)
        if (name != "tap" && stream != 0) protectUntil = SystemClock.uptimeMillis() + duration
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            Log.d("NoorAudio", "effect=$name streamStarted=${stream != 0}")
        }
    }

    fun stop() {
        pending = null
        if (stream != 0) pool?.stop(stream)
        stream = 0
        protectUntil = 0L
    }

    fun dispose() {
        stop()
        pool?.release()
        pool = null
    }
}
