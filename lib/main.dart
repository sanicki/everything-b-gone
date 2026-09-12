import 'dart:async';
import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:everythingbgone/state/app_locale.dart';
import 'package:everythingbgone/state/app_shortcuts.dart';
import 'package:everythingbgone/state/app_theme.dart';
import 'package:everythingbgone/state/dynamic_color.dart';
import 'package:everythingbgone/state/haptics.dart';
import 'package:everythingbgone/state/orientation_pref.dart';
import 'package:everythingbgone/state/remote_display_prefs.dart';
import 'package:everythingbgone/state/startup_prefs.dart';
import 'package:everythingbgone/state/transmitter_prefs.dart';
import 'package:everythingbgone/state/remotes_state.dart';
import 'package:everythingbgone/flipper_irdb/kill_switch_action.dart';
import 'package:flutter/services.dart';
import 'package:everythingbgone/l10n/app_localizations.dart';
import 'package:everythingbgone/l10n/l10n.dart';
import 'package:everythingbgone/utils/remote.dart';
import 'package:everythingbgone/widgets/home_shell.dart';
import 'package:media_store_plus/media_store_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initControlChannel();
  await AppShortcutController.instance.initialize(_navKey);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return true;
  };
  try {
    await AppThemeController.instance.load();
    await AppLocaleController.instance.load();
    await DynamicColorController.instance.load();
    // Load global interaction preferences
    await Future.wait([
      HapticsController.instance.load(),
      RemoteOrientationController.instance.load(),
      RemoteDisplayController.instance.load(),
      StartupPrefsController.instance.load(),
      TransmitterPrefs.instance.load(),
      // lazy import to avoid circulars; we refer by string to keep tool happy
    ]);
  } catch (e, st) {
    debugPrint('Failed to load theme preference: $e\n$st');
  }
  runZonedGuarded(() {
    runApp(const _App());
  }, (error, stack) {
    debugPrint('Zone error: $error\n$stack');
  });
}

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

/// Single channel every headless trigger (Quick Settings tiles, Android
/// Device Controls, the home-screen widget) dispatches through. The
/// native side (see MainActivity.kt's `dispatchControlAction`) launches
/// the app — possibly cold, possibly with the screen off — and forwards a
/// fixed "power"/"mute" action string here once the Flutter engine is
/// ready; there is nothing left to look up since there are no more saved
/// remotes, so this just fires the kill-switch cycle directly.
const MethodChannel _controlChannel =
    MethodChannel('com.example.everythingbgone/irtransmitter_controls');

void _initControlChannel() {
  _controlChannel.setMethodCallHandler((call) async {
    if (call.method != 'fireAction') return;
    final args = call.arguments;
    String? action;
    if (args is Map) {
      final raw = args['action'];
      if (raw is String) action = raw;
    }
    final killSwitchAction = _killSwitchActionFromString(action);
    if (killSwitchAction == null) return;
    StartupPrefsController.instance.suppressAutoOpenForCurrentLaunch();
    try {
      await fireKillSwitchAction(killSwitchAction);
    } catch (e, st) {
      debugPrint('Headless kill-switch action failed: $e\n$st');
    }
  });
}

KillSwitchAction? _killSwitchActionFromString(String? raw) {
  switch ((raw ?? '').trim()) {
    case 'power':
      return KillSwitchAction.power;
    case 'mute':
      return KillSwitchAction.mute;
    default:
      return null;
  }
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppThemeController.instance,
        AppLocaleController.instance,
        DynamicColorController.instance,
      ]),
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final useDynamic = DynamicColorController.instance.enabled;
            final ColorScheme lightScheme = useDynamic
                ? (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue))
                : ColorScheme.fromSeed(seedColor: Colors.blue);
            final ColorScheme darkScheme = useDynamic
                ? (darkDynamic ??
                    ColorScheme.fromSeed(
                        seedColor: Colors.blue, brightness: Brightness.dark))
                : ColorScheme.fromSeed(
                    seedColor: Colors.blue, brightness: Brightness.dark);
            return MaterialApp(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              navigatorKey: _navKey,
              locale: AppLocaleController.instance.overrideLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              localeResolutionCallback: (locale, supportedLocales) {
                return AppLocaleController.instance
                    .resolveActiveLocale(supportedLocales.toList(), locale);
              },
              themeMode: AppThemeController.instance.mode,
              theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: lightScheme,
                  brightness: Brightness.light),
              darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkScheme,
                  brightness: Brightness.dark),
              home: const _BootstrapScreen(),
            );
          },
        );
      },
    );
  }
}

class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  late Future<void> _future = _bootstrap();

  Future<void> _bootstrap() async {
    final supportedLocales = AppLocalizations.supportedLocales.toList();
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final bootstrapLocale = AppLocaleController.instance.resolveActiveLocale(
      supportedLocales,
      systemLocale,
    );
    AppLocalizations bootstrapL10n;
    try {
      bootstrapL10n = await AppLocalizations.delegate.load(bootstrapLocale);
    } catch (_) {
      bootstrapL10n = await AppLocalizations.delegate.load(
        AppLocaleController.instance
            .resolveActiveLocale(supportedLocales, const Locale('en')),
      );
    }
    await MediaStore.ensureInitialized().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        throw TimeoutException('MediaStore.ensureInitialized() timed out');
      },
    );
    MediaStore.appFolder = 'IRBlaster';
    remotes = await readRemotes().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        throw TimeoutException('readRemotes() timed out');
      },
    );
    if (remotes.isEmpty) {
      remotes =
          writeDefaultRemotes(demoRemoteName: bootstrapL10n.demoRemoteName);
    }
    notifyRemotesChanged();
    AppShortcutController.instance.markBootstrapReady();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Splash();
        }
        if (snap.hasError) {
          return _BootstrapError(
            error: snap.error,
            onRetry: () => setState(() => _future = _bootstrap()),
          );
        }
        return const HomeShell();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 14),
            Text(context.l10n.loading, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _BootstrapError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final msg = (error == null) ? context.l10n.unknownError : error.toString();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 44, color: cs.error),
                const SizedBox(height: 12),
                Text(
                  context.l10n.failedToStart,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: SelectableText(
                    msg,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.retry),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
