/// Uygulama başlangıç noktası
/// Supabase başlatma, yerel cache ve Riverpod konfigürasyonu
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/supabase_config.dart';
import 'core/services/local_cache_service.dart';
import 'app.dart';

void main() async {
  // Flutter binding başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Intl locale - Flutter web için gerekli
  Intl.defaultLocale = 'en_US';
  await initializeDateFormatting('en_US', null);

  // Supabase'i başlat
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Yerel önbelleği başlat (Offline-First)
  await LocalCacheService().initialize();

  // Uygulamayı başlat
  runApp(
    const ProviderScope(
      child: NotebookApp(),
    ),
  );
}
