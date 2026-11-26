package dev.noor.noor

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.plugin.common.MethodChannel

internal class OfflineArabicSpeech(private val context: Context) {
    private data class Request(
        val id: String,
        val text: String,
        val result: MethodChannel.Result,
    )

    private val main = Handler(Looper.getMainLooper())
    private var engine: TextToSpeech? = null
    private var initialized = false
    private var generation = 0
    private var sequence = 0L
    private var request: Request? = null

    fun read(text: String, result: MethodChannel.Result) {
        stop()
        if (text.isBlank() || text.length > TextToSpeech.getMaxSpeechInputLength()) {
            result.success(false)
            return
        }

        val next = Request((++sequence).toString(), text, result)
        request = next
        if (initialized) {
            speakPending()
        } else if (engine == null) {
            val expected = ++generation
            engine = TextToSpeech(context) { status ->
                main.post {
                    if (generation == expected) onInitialized(status)
                }
            }
        }
    }

    private fun onInitialized(status: Int) {
        val service = engine
        if (status != TextToSpeech.SUCCESS || service == null) {
            dispose()
            return
        }

        val listener = object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String) = Unit
            override fun onDone(utteranceId: String) {
                main.post { finish(utteranceId, true) }
            }
            @Suppress("DEPRECATION")
            override fun onError(utteranceId: String) {
                main.post { finish(utteranceId, false) }
            }
            override fun onError(utteranceId: String, errorCode: Int) {
                main.post { finish(utteranceId, false) }
            }
            override fun onStop(utteranceId: String, interrupted: Boolean) {
                main.post { finish(utteranceId, false) }
            }
        }
        if (service.setOnUtteranceProgressListener(listener) != TextToSpeech.SUCCESS) {
            dispose()
            return
        }
        initialized = true
        speakPending()
    }

    private fun speakPending() {
        val current = request ?: return
        val service = engine ?: return
        val accepted = runCatching {
            val voice = service.voices.orEmpty()
                .filter {
                    it.locale.language == "ar" &&
                        !it.isNetworkConnectionRequired &&
                        it.features?.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) == false
                }
                .sortedWith(compareByDescending<Voice> { it.quality }.thenBy { it.latency }.thenBy { it.name })
                .firstOrNull { service.setVoice(it) == TextToSpeech.SUCCESS }

            if (voice == null) {
                false
            } else {
                service.setSpeechRate(0.88f)
                service.speak(current.text, TextToSpeech.QUEUE_FLUSH, null, current.id) ==
                    TextToSpeech.SUCCESS
            }
        }.getOrDefault(false)
        if (!accepted) finish(current.id, false)
    }

    private fun finish(id: String, played: Boolean) {
        val current = request ?: return
        if (current.id != id) return
        request = null
        current.result.success(played)
    }

    fun stop() {
        request?.let { finish(it.id, false) }
        if (initialized) engine?.stop()
    }

    fun dispose() {
        stop()
        ++generation
        initialized = false
        engine?.shutdown()
        engine = null
    }
}
