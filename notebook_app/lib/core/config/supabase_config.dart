/// Supabase bağlantı yapılandırması
/// Tüm Supabase erişim bilgilerini merkezi olarak yönetir
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase proje URL'si
  static const String url = 'https://lugshtlpcgcrbelsombz.supabase.co';

  /// Supabase anonim (public) anahtar
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1Z3NodGxwY2djcmJlbHNvbWJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MTk2MzAsImV4cCI6MjA4NzM5NTYzMH0.FeLzVIpYmbMErW3-sbIg1LgrzbaysmpwTBX0ht0YVi8';

  /// AI işlemleri için Emergent LLM Universal Key
  static const String emergentLlmKey = 'sk-emergent-1E8478eC2F15265873';

  /// Depolama bucket isimleri
  static const String noteMediaBucket = 'note-media';
  static const String avatarsBucket = 'avatars';

  /// Supabase Auth callback URL (OAuth için)
  static const String authRedirectUrl = 'io.supabase.notebookapp://login-callback/';
}
