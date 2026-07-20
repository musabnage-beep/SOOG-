import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_controller.dart';
import 'providers/core_providers.dart';
import 'router/app_router.dart';

Future<void> main() async {
  // TEMP DIAGNOSTIC: surface any startup error on screen (works in release)
  // instead of a blank white screen. Remove once the white-screen bug is fixed.
  ErrorWidget.builder = (FlutterErrorDetails details) => _ErrorScreen(
        '${details.exceptionAsString()}\n\n${details.stack}',
      );

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    try {
      await initializeDateFormatting('ar');
    } catch (e, s) {
      runApp(_ErrorApp('initializeDateFormatting failed:\n$e\n\n$s'));
      return;
    }
    runApp(const ProviderScope(child: AldiafaApp()));
  }, (error, stack) {
    runApp(_ErrorApp('Uncaught startup error:\n$error\n\n$stack'));
  });
}

/// Minimal standalone app that renders a fatal startup error on screen.
class _ErrorApp extends StatelessWidget {
  const _ErrorApp(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _ErrorScreen(message),
      );
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: const Color(0xFF7A0000),
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
          child: SingleChildScrollView(
            child: SelectableText(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      );
}

class AldiafaApp extends ConsumerStatefulWidget {
  const AldiafaApp({super.key});

  @override
  ConsumerState<AldiafaApp> createState() => _AldiafaAppState();
}

class _AldiafaAppState extends ConsumerState<AldiafaApp> {
  @override
  void initState() {
    super.initState();
    // Initialize push messaging (best-effort) and register/unregister the FCM
    // device token as the auth state changes.
    Future.microtask(() async {
      final push = ref.read(pushServiceProvider);
      await push.init();
      if (ref.read(authControllerProvider).isAuthenticated) {
        await push.registerToken();
      }
    });
    ref.listenManual(authControllerProvider, (prev, next) async {
      final push = ref.read(pushServiceProvider);
      if (next.isAuthenticated && prev?.isAuthenticated != true) {
        await push.registerToken();
      } else if (!next.isAuthenticated && prev?.isAuthenticated == true) {
        await push.unregister();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'الضيافة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

