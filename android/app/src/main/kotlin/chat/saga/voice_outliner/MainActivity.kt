package chat.saga.voice_outliner

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.vosk.Recognizer
import org.vosk.Model

class MainActivity: FlutterActivity() {
    private val CHANNEL = "voiceoutliner.saga.chat/androidtx"
    private val model = Model()

    private fun transcribe(path: String) {
        try {
        } catch (e: Exception) {

        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "transcribe") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("Null path provided", "Cannot transcribe null path", null)
                }
                transcribe(path!!)
            } else {
                result.notImplemented()
            }
        }
    }
}
