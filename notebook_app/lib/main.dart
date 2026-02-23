/// Uygulama başlangıç noktası
/// Supabase başlatma, yerel cache ve Riverpod konfigürasyonu
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/services/local_cache_service.dart';
import 'app.dart';

void main() async {
  // Flutter binding başlat
  WidgetsFlutterBinding.ensureInitialized();

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
