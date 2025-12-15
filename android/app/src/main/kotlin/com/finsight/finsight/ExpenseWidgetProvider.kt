package com.finsight.finsight

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

/**
 * Implementation of App Widget functionality for FinSight Expense Tracker
 * Shows today's spending total and provides quick add expense action
 */
class ExpenseWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "ExpenseWidgetPrefs"
        private const val PREF_TODAY_AMOUNT = "today_amount"
        private const val PREF_EXPENSE_COUNT = "expense_count"
        private const val PREF_LAST_UPDATE = "last_update"
        
        const val ACTION_WIDGET_CLICK = "com.finsight.finsight.WIDGET_CLICK"
        const val ACTION_ADD_EXPENSE = "com.finsight.finsight.ADD_EXPENSE"
        const val ACTION_REFRESH_WIDGET = "com.finsight.finsight.REFRESH_WIDGET"

        /**
         * Update widget data from Flutter side
         */
        fun updateWidgetData(context: Context, todayAmount: Double, expenseCount: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putFloat(PREF_TODAY_AMOUNT, todayAmount.toFloat())
                putInt(PREF_EXPENSE_COUNT, expenseCount)
                putLong(PREF_LAST_UPDATE, System.currentTimeMillis())
                apply()
            }

            // Update all widgets
            val intent = Intent(context, ExpenseWidgetProvider::class.java)
            intent.action = ACTION_REFRESH_WIDGET
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update all widget instances
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_ADD_EXPENSE -> {
                // Open app with add expense screen
                val launchIntent = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                launchIntent?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra("action", "add_expense")
                }
                context.startActivity(launchIntent)
            }
            ACTION_REFRESH_WIDGET -> {
                // Refresh all widgets
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val widgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, ExpenseWidgetProvider::class.java)
                )
                onUpdate(context, appWidgetManager, widgetIds)
            }
            ACTION_WIDGET_CLICK -> {
                // Open app to dashboard
                val launchIntent = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
            }
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
        super.onDisabled(context)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.expense_widget)

        // Get widget data from SharedPreferences
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val todayAmount = prefs.getFloat(PREF_TODAY_AMOUNT, 0.0f).toDouble()
        val expenseCount = prefs.getInt(PREF_EXPENSE_COUNT, 0)

        // Format amount
        val currencyFormat = NumberFormat.getCurrencyInstance(Locale.US)
        val formattedAmount = currencyFormat.format(todayAmount)

        // Format date
        val dateFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
        val today = dateFormat.format(Date())

        // Update widget views
        views.setTextViewText(R.id.widget_amount, formattedAmount)
        views.setTextViewText(
            R.id.widget_expense_count,
            "$expenseCount ${if (expenseCount == 1) "expense" else "expenses"}"
        )
        views.setTextViewText(R.id.widget_date, today)

        // Set up click intents
        setupClickIntents(context, views, appWidgetId)

        // Tell the AppWidgetManager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun setupClickIntents(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int
    ) {
        // Widget background click - open app
        val widgetIntent = Intent(context, ExpenseWidgetProvider::class.java)
        widgetIntent.action = ACTION_WIDGET_CLICK
        val widgetPendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            widgetIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_amount, widgetPendingIntent)

        // Add expense button click
        val addIntent = Intent(context, ExpenseWidgetProvider::class.java)
        addIntent.action = ACTION_ADD_EXPENSE
        val addPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_add_button, addPendingIntent)
    }
}

/**
 * Widget data class for easier handling
 */
data class WidgetData(
    val todayAmount: Double,
    val expenseCount: Int,
    val lastUpdate: Long
)
