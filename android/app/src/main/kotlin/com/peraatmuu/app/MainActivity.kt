package com.peraatmuu.app

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channelName = "peraatmuu/emulator"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPaths" -> result.success(
                        mapOf(
                            "coresDir" to applicationInfo.nativeLibraryDir,
                            "systemDir" to ensureDir("system"),
                            "statesDir" to ensureDir("states"),
                            "savesDir" to ensureDir("saves"),
                        )
                    )

                    "getAbi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a")

                    "isCoreAvailable" -> {
                        val coreFile = call.argument<String>("coreFile").orEmpty()
                        result.success(
                            coreFile.isNotEmpty() &&
                                File(applicationInfo.nativeLibraryDir, coreFile).exists()
                        )
                    }

                    "play" -> {
                        val corePath = call.argument<String>("corePath")
                        val romPath = call.argument<String>("romPath")
                        val systemId = call.argument<String>("systemId") ?: "generic"
                        val coreOptions =
                            call.argument<Map<String, String>>("coreOptions").orEmpty()
                        when {
                            corePath.isNullOrBlank() ->
                                result.error("NO_CORE", "Caminho do núcleo não informado", null)
                            !File(corePath).exists() ->
                                result.error("CORE_NOT_FOUND", "Núcleo não encontrado: $corePath", null)
                            romPath.isNullOrBlank() || !File(romPath).exists() ->
                                result.error("ROM_NOT_FOUND", "ROM não encontrada: $romPath", null)
                            else -> {
                                startActivity(
                                    com.peraatmuu.app.emulator.GameActivity.createIntent(
                                        this, corePath, romPath, systemId, coreOptions,
                                    )
                                )
                                result.success(null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun ensureDir(name: String): String =
        File(filesDir, name).apply { mkdirs() }.absolutePath
}
