package com.example.everythingbgone

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.controls.Control
import android.service.controls.ControlsProviderService
import android.service.controls.actions.ControlAction
import androidx.annotation.RequiresApi
import java.util.concurrent.Flow

/**
 * Exposes exactly two Android Device Controls — Power and Mute — that
 * fire the app's kill-switch cycle directly. There are no more saved
 * remotes to bind a control slot to, so every user sees the same two
 * fixed controls; tapping one launches [MainActivity] with a fixed
 * action extra that the (possibly cold-started) Flutter engine forwards
 * straight to `fireKillSwitchAction` (see MainActivity.dispatchControlAction
 * and lib/main.dart's `_initControlChannel`).
 */
@RequiresApi(Build.VERSION_CODES.R)
class DeviceControlsService : ControlsProviderService() {
    override fun createPublisherForAllAvailable(): Flow.Publisher<Control> {
        return SimplePublisher(ACTIONS.map { buildControl(it) })
    }

    override fun createPublisherFor(controlIds: MutableList<String>): Flow.Publisher<Control> {
        val controls = controlIds.filter { it in ACTIONS }.map { buildControl(it) }
        return SimplePublisher(controls)
    }

    override fun performControlAction(controlId: String, action: ControlAction, consumer: java.util.function.Consumer<Int>) {
        if (controlId !in ACTIONS) {
            consumer.accept(ControlAction.RESPONSE_FAIL)
            return
        }
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_CONTROL_ACTION, controlId)
        }
        startActivity(intent)
        consumer.accept(ControlAction.RESPONSE_OK)
    }

    private fun buildControl(action: String): Control {
        val pendingIntent = PendingIntent.getActivity(
            this,
            action.hashCode(),
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(EXTRA_CONTROL_ACTION, action)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val (title, iconRes) = when (action) {
            "mute" -> "Mute" to R.drawable.ic_dc_mute
            else -> "Power" to R.drawable.ic_dc_power
        }
        return Control.StatelessBuilder(action, pendingIntent)
            .setTitle(title)
            .setSubtitle("Everything-B-Gone")
            .setDeviceType(0)
            .setCustomIcon(Icon.createWithResource(this, iconRes))
            .build()
    }

    companion object {
        const val EXTRA_CONTROL_ACTION = "control_action"
        private val ACTIONS = listOf("power", "mute")
    }
}

private class SimplePublisher(private val items: List<Control>) : Flow.Publisher<Control> {
    override fun subscribe(subscriber: Flow.Subscriber<in Control>) {
        val sub = object : Flow.Subscription {
            private var cancelled = false
            private var sent = false

            override fun request(n: Long) {
                if (cancelled || sent) return
                sent = true
                if (n <= 0) {
                    subscriber.onError(IllegalArgumentException("n must be > 0"))
                    return
                }
                for (c in items) {
                    if (cancelled) return
                    subscriber.onNext(c)
                }
                if (!cancelled) subscriber.onComplete()
            }

            override fun cancel() {
                cancelled = true
            }
        }
        subscriber.onSubscribe(sub)
    }
}
