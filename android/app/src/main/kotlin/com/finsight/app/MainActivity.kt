package com.finsight.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.finsight.app/widget"
    private var initialRoute: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Check if widget launched the app with a specific action
        val action = intent.getStringExtra("action")
        if (action == "add_expense") {
            initialRoute = "/add-expense"
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    try {
                        val todayAmount = call.argument<Double>("todayAmount") ?: 0.0
                        val expenseCount = call.argument<Int>("expenseCount") ?: 0
                        
                        ExpenseWidgetProvider.updateWidgetData(
                            applicationContext,
                            todayAmount,
                            expenseCount
                        )
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_ERROR", e.message, null)
                    }
                }
                "getInitialRoute" -> {
                    result.success(initialRoute)
                    initialRoute = null // Clear after reading
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
