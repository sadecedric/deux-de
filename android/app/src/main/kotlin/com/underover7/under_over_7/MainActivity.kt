package com.underover7.under_over_7

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val DEVICE_CHANNEL = "under_over_7/device"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "stableDeviceId") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val androidId = Settings.Secure.getString(
                    contentResolver,
                    Settings.Secure.ANDROID_ID,
                )
                if (androidId.isNullOrBlank()) {
                    result.error("DEVICE_ID_UNAVAILABLE", "Identifiant Android indisponible.", null)
                } else {
                    result.success("android:$androidId")
                }
            }
    }
}
