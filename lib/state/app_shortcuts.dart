import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:everythingbgone/l10n/app_localizations.dart';
import 'package:everythingbgone/state/startup_prefs.dart';

// TODO: reintroduce real dynamic-shortcut actions once the Everything-B-Gone
// home screen exists. Every action this used to dispatch to (last remote,
// Signal Tester, Learning Mode, last macro, Universal Power) pointed at a
// screen that has since been removed, so for now this only keeps the native
// method-channel plumbing alive for a later phase to build on.
class AppShortcutController {
  AppShortcutController._();

  static final AppShortcutController instance = AppShortcutController._();
  static const MethodChannel _channel =
      MethodChannel('com.example.everythingbgone/app_shortcuts');

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingAction;
  bool _initialized = false;
  bool _bootstrapReady = false;
  bool _dispatchScheduled = false;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    if (!_initialized) {
      _initialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'openShortcut') return;
        final action = _readAction(call.arguments);
        if (action == null) return;
        StartupPrefsController.instance.suppressAutoOpenForCurrentLaunch();
        _pendingAction = action;
        _scheduleDispatch();
      });
      try {
        final initial =
            await _channel.invokeMethod<String>('consumeInitialShortcutAction');
        if (initial != null && initial.trim().isNotEmpty) {
          StartupPrefsController.instance.suppressAutoOpenForCurrentLaunch();
          _pendingAction = initial.trim();
        }
      } catch (_) {}
    }
    _scheduleDispatch();
  }

  void markBootstrapReady() {
    _bootstrapReady = true;
    _scheduleDispatch();
  }

  Future<void> sync(AppLocalizations l10n) async {
    try {
      await _channel.invokeMethod<void>(
        'updateDynamicShortcuts',
        <String, dynamic>{'items': const <Map<String, String>>[]},
      );
    } catch (_) {}
  }

  String? _readAction(dynamic arguments) {
    if (arguments is String && arguments.trim().isNotEmpty) {
      return arguments.trim();
    }
    if (arguments is Map) {
      final raw = arguments['action'];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
  }

  void _scheduleDispatch() {
    if (_dispatchScheduled) return;
    _dispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dispatchScheduled = false;
      unawaited(_dispatchPendingShortcut());
    });
  }

  Future<void> _dispatchPendingShortcut() async {
    if (!_bootstrapReady) {
      _scheduleDispatch();
      return;
    }
    final action = _pendingAction;
    if (action == null || action.isEmpty) return;
    final navigator = _navigatorKey?.currentState;
    final context = _navigatorKey?.currentContext;
    if (navigator == null || context == null) {
      _scheduleDispatch();
      return;
    }

    // No shortcut actions are currently wired up; just drop the pending one.
    _pendingAction = null;
  }
}
