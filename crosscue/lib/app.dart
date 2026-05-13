import 'dart:ui';

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/app_router.dart';
import 'package:crosscue/core/theme/app_theme.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ThemeMode _toFlutterThemeMode(AppThemeMode m) => switch (m) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

/// Root application widget. Reads the router and theme mode from Riverpod
/// and wraps MaterialApp.router with Material You dynamic color support.
class CrosscueApp extends ConsumerStatefulWidget {
  const CrosscueApp({super.key});

  @override
  ConsumerState<CrosscueApp> createState() => _CrosscueAppState();
}

class _CrosscueAppState extends ConsumerState<CrosscueApp> {
  late final _CrosshareLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _CrosshareLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _installCrashHandlers();
    ref.listenManual(
      crashReportingProvider,
      (_, next) {
        next.whenData((enabled) {
          ref.read(crashReporterProvider).init(enabled: enabled);
        });
      },
      fireImmediately: true,
    );
    // Trigger auto-download on first launch (post-frame so providers are ready).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded();
    });
  }

  void _installCrashHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      ref
          .read(crashReporterProvider)
          .reportError(details.exception, details.stack ?? StackTrace.current);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      ref.read(crashReporterProvider).reportError(error, stack);
      return false;
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.when(
      data: (m) => _toFlutterThemeMode(m),
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'Crosscue',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dynamicScheme: lightDynamic),
          darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}

class _CrosshareLifecycleObserver extends WidgetsBindingObserver {
  _CrosshareLifecycleObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded();
    }
  }
}
