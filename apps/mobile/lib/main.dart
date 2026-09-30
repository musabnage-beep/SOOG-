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
  // Safety net: if the app fails to boot, show a clean message instead of a
  // blank screen.
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) => FlutterError.presentError(details);
    await initializeDateFormatting('ar');
    runApp(const ProviderScope(child: AldiafaApp()));
  }, (error, stack) {
    runApp(const _ErrorApp());
  });
}

/// Minimal standalone app shown only if the app fails to start.
class _ErrorApp extends StatelessWidget {
  const _ErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            // Literal colors: this runs when the app failed to boot, so it
            // must not depend on anything that could itself have thrown.
            backgroundColor: const Color(0xFFF6F8F5),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.error_outline, size: 48, color: Color(0xFFD92D20)),
                    SizedBox(height: 16),
                    Text(
                      'حدث خطأ غير متوقع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14211A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'يرجى إغلاق التطبيق وإعادة فتحه',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7A70)),
                    ),
                  ],
                ),
              ),
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
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
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

