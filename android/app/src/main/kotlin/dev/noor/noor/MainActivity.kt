package dev.noor.noor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var speech: OfflineArabicSpeech? = null
    private var effects: PilotEffects? = null
    private var speechChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val reader = OfflineArabicSpeech(applicationContext)
        val player = PilotEffects(applicationContext)
        effects = player
        speech = reader
        speechChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.noor.noor/speech",
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> {
                        player.stop()
                        reader.read(call.arguments as? String ?: "", result)
                    }
                    "effect" -> {
                        if (!reader.isReading) player.play(call.arguments as? String ?: "")
                        result.success(null)
                    }
                    "stopEffects" -> {
                        player.stop()
                        result.success(null)
                    }
                    "stop" -> {
                        reader.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onPause() {
        speech?.stop()
        effects?.stop()
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        speechChannel?.setMethodCallHandler(null)
        speechChannel = null
        effects?.dispose()
        effects = null
        speech?.dispose()
        speech = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
