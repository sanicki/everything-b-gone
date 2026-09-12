package com.example.everythingbgone

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings tiles are fixed to a single kill-switch action each —
 * there are no more saved remotes to bind a tile to, so a tap always
 * launches [MainActivity] with the tile's action ("power"/"mute") via the
 * same cold-start-safe dispatch [DeviceControlsService] uses. The engine
 * (once running) forwards that action straight to
 * `fireKillSwitchAction` — see MainActivity.dispatchControlAction and
 * lib/main.dart's `_initControlChannel`.
 */
abstract class BaseQuickTileService : TileService() {
    abstract val action: String
    abstract val label: String
    abstract val iconRes: Int

    override fun onStartListening() {
        super.onStartListening()
        val t = qsTile ?: return
        t.label = label
        t.icon = Icon.createWithResource(this, iconRes)
        t.state = Tile.STATE_ACTIVE
        t.updateTile()
    }

    override fun onClick() {
        super.onClick()
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(DeviceControlsService.EXTRA_CONTROL_ACTION, action)
        }
        val pending = PendingIntent.getActivity(
            this,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        launchActivityFromTile(intent, pending)
    }

    @Suppress("DEPRECATION")
    private fun launchActivityFromTile(intent: Intent, pending: PendingIntent) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startActivityAndCollapse(pending)
            } else {
                startActivityAndCollapse(intent)
            }
        } catch (_: Throwable) {
            try {
                startActivity(intent)
            } catch (_: Throwable) {
            }
        }
    }
}

class PowerTileService : BaseQuickTileService() {
    override val action = "power"
    override val label = "Power"
    override val iconRes = R.drawable.ic_qs_power
}

class MuteTileService : BaseQuickTileService() {
    override val action = "mute"
    override val label = "Mute"
    override val iconRes = R.drawable.ic_qs_mute
}
