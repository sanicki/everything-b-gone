package com.example.everythingbgone

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * A fixed-purpose home-screen widget: every instance fires the app's
 * Power kill-switch cycle. There is no more per-instance "pick a button"
 * configuration — a widget means the same thing wherever it's placed, so
 * tapping it always launches [MainActivity] with a fixed "power" action
 * extra, the same dispatch mechanism the Quick Settings tiles and Device
 * Controls use (see MainActivity.dispatchControlAction).
 */
class IrButtonWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { updateWidget(context, manager, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_SEND) return
        try {
            context.startActivity(
                Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra(DeviceControlsService.EXTRA_CONTROL_ACTION, "power")
                },
            )
        } catch (_: Throwable) {
        }
    }

    companion object {
        const val ACTION_SEND = "com.example.everythingbgone.widget.SEND_BUTTON"

        fun updateWidget(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
            val views = RemoteViews(context.packageName, R.layout.ir_button_widget)
            views.setTextViewText(R.id.ir_button_widget_title, "Power")
            views.setTextViewText(R.id.ir_button_widget_subtitle, "Tap to send")
            views.setImageViewResource(R.id.ir_button_widget_icon, R.drawable.ic_dc_power)
            views.setOnClickPendingIntent(
                R.id.ir_button_widget_root,
                PendingIntent.getBroadcast(
                    context,
                    appWidgetId,
                    Intent(context, IrButtonWidgetProvider::class.java).apply {
                        action = ACTION_SEND
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
