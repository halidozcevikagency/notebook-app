/// Ana uygulama widget'ı
/// Tema, routing ve Supabase entegrasyonunu bir araya getirir
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';

class NotebookApp extends ConsumerWidget {
  const NotebookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode_ = ref.watch(themeProvider);

    ThemeMode themeMode;
    switch (themeMode_) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      title: 'Notebook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
