import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_controller.dart';
import 'providers/core_providers.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  runApp(const ProviderScope(child: AldiafaApp()));
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
