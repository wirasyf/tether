package com.example.tether

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Tether Home Screen Widget Provider
 * Provides a quick-touch button for sending love to your partner
 */
class TetherWidgetProvider : HomeWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.tether_widget)
            
            // Get saved data
            val isPartnerOnline = widgetData.getBoolean("partner_online", false)
            val pendingTouches = widgetData.getInt("pending_touches", 0)
            
            // Update partner status text
            val statusText = when {
                pendingTouches > 0 -> "$pendingTouches touches waiting!"
                isPartnerOnline -> "Partner is online"
                else -> "Tap to send love"
            }
            views.setTextViewText(R.id.partner_status, statusText)
            
            // Set up touch button click - sends a tap
            val tapIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("tetherwidget://tap")
            )
            views.setOnClickPendingIntent(R.id.touch_button, tapIntent)
            
            // Update the widget
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
