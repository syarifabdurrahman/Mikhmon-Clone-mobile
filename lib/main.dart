import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/app_providers.dart';
import 'services/cache_service.dart';
import 'services/log_service.dart';
import 'services/search_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Initialize cache service
  await CacheService().init();

  // Initialize log service for activity logging
  await LogService.init();

  // Initialize search service for recent searches
  await SearchService.init();

  // Pre-load theme for instant display (no flash)
  final preloadedTheme = await ThemeService.loadThemeMode();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider
            .overrideWith((ref) => ThemeModeNotifier.preloaded(preloadedTheme)),
      ],
      child: const OmmonApp(),
    ),
  );
}

class OmmonApp extends ConsumerWidget {
  const OmmonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ΩMMON - Open Mikrotik Monitor',
      theme: ThemeService.getThemeData(themeMode),
      routerConfig: router,
    );
  }
}
