package com.littleus.little_us

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "little_us/fridge_widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) { result.error("BAD_ARGS", "Missing widget data", null); return@setMethodCallHandler }
                        val enabled = args["enabled"] == true
                        val prefs = getSharedPreferences(FridgeNoteWidget.PREFS, Context.MODE_PRIVATE)
                        val editor = prefs.edit().clear().putBoolean("enabled", enabled)
                        if (enabled) {
                            editor.putString("body", (args["body"] as? String ?: "").take(500))
                            editor.putString("author", (args["author"] as? String ?: "Little us").take(30))
                            editor.putBoolean("demo", args["demo"] == true)
                            editor.putLong("updatedAt", (args["updatedAt"] as? Number)?.toLong() ?: 0L)
                        }
                        editor.apply()
                        FridgeNoteWidget.refreshAll(this)
                        result.success(null)
                    }
                    "requestPin" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.isRequestPinAppWidgetSupported) {
                            result.success(manager.requestPinAppWidget(ComponentName(this, FridgeNoteWidget::class.java), null, null))
                        } else { result.success(false) }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
