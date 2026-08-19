package com.example.qr_pro_app

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "qr_kod/system_settings"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "openWifiPanel" -> {
          try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
              Intent(Settings.Panel.ACTION_WIFI)
            } else {
              Intent(Settings.ACTION_WIFI_SETTINGS)
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(true)
          } catch (e: Exception) {
            result.success(false)
          }
        }
        "openWifiSettings" -> {
          try {
            val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(true)
          } catch (e: Exception) {
            result.success(false)
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}
