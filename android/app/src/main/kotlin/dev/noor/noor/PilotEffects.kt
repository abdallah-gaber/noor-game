package dev.noor.noor

import android.content.Context
import android.content.pm.ApplicationInfo
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.SystemClock
import android.util.Log
import io.flutter.FlutterInjector

internal class PilotEffects(private val context: Context) {
    private val debuggable = context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
    private val holdMillis = mapOf(
        "tap" to 66L, "correct" to 230L, "retry" to 158L, "complete" to 336L,
    ) + if (debuggable) mapOf(
        "wudu_pickup" to 85L, "wudu_place" to 116L, "wudu_splash" to 244L,
        "wudu_wipe" to 199L, "wudu_retry" to 172L, "wudu_finish" to 382L,
        "wudu_reveal" to 472L,
    ) else emptyMap()
    private fun isLight(name: String) =
        name == "tap" || name == "wudu_pickup" || name == "wudu_place"
    private val samples = mutableMapOf<String, Int>()
    private val ready = mutableSetOf<Int>()
    private var pool: SoundPool? = null
    private var stream = 0
    private var activeName: String? = null
    private var protectUntil = 0L
    private var pending: String? = null

    fun play(name: String) {
        val duration = holdMillis[name] ?: return
        val now = SystemClock.uptimeMillis()
        val active = activeName
        if (now < protectUntil && active != null) {
            if (isLight(name) && !isLight(active)) return
            if (name.startsWith("wudu_") && name == active) return
        }
        if (name.startsWith("wudu_") && isLight(name) && pending?.let { !isLight(it) } == true) return
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
        if (stream != 0) {
            activeName = name
            protectUntil = SystemClock.uptimeMillis() + duration
        }
        if (debuggable) {
            Log.d("NoorAudio", "effect=$name streamStarted=${stream != 0}")
        }
    }

    fun stop() {
        pending = null
        if (stream != 0) pool?.stop(stream)
        stream = 0
        activeName = null
        protectUntil = 0L
    }

    fun dispose() {
        stop()
        pool?.release()
        pool = null
    }
}
