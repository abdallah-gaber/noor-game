package dev.noor.noor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var speech: OfflineArabicSpeech? = null
    private var speechChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val reader = OfflineArabicSpeech(applicationContext)
        speech = reader
        speechChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.noor.noor/speech",
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> reader.read(call.arguments as? String ?: "", result)
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
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        speechChannel?.setMethodCallHandler(null)
        speechChannel = null
        speech?.dispose()
        speech = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
