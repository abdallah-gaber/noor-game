package dev.noor.noor

import android.content.Context
import android.content.pm.ApplicationInfo
import android.media.AudioAttributes
import android.media.SoundPool
import android.util.Log

internal class PilotEffects(private val context: Context) {
    private val sounds = mapOf(
        "tap" to R.raw.noor_tap, "correct" to R.raw.noor_correct,
        "retry" to R.raw.noor_retry, "complete" to R.raw.noor_complete,
    )
    private val samples = mutableMapOf<String, Int>()
    private val ready = mutableSetOf<Int>()
    private var pool: SoundPool? = null
    private var stream = 0
    private var pending: String? = null

    fun play(name: String) {
        if (name !in sounds) return
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
                for ((effect, resource) in sounds) {
                    samples[effect] = created.load(context, resource, 1)
                }
            }
        val sample = samples.getValue(name)
        if (sample !in ready) {
            pending = name
            return
        }
        stop()
        stream = player.play(sample, 0.78f, 0.78f, 1, 0, 1f)
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            Log.d("NoorAudio", "effect=$name streamStarted=${stream != 0}")
        }
    }

    fun stop() {
        pending = null
        if (stream != 0) pool?.stop(stream)
        stream = 0
    }

    fun dispose() {
        stop()
        pool?.release()
        pool = null
    }
}
