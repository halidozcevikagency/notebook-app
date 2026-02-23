/// Kimlik doğrulama repository'si
/// Supabase Auth ile Google, GitHub, Apple ve email/password girişini yönetir
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_models.dart';
import '../../core/config/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mevcut kullanıcı session'ını döner
  Session? get currentSession => _supabase.auth.currentSession;

  /// Mevcut kullanıcı ID'sini döner
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Auth durum değişikliklerini dinler
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// E-posta ve şifre ile kayıt
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// E-posta ve şifre ile giriş
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Google ile giriş (OAuth)
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// GitHub ile giriş (OAuth)
  Future<bool> signInWithGitHub() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// Apple ile giriş (OAuth)
  Future<bool> signInWithApple() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Kullanıcı profilini yükle
  Future<ProfileModel?> loadProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  /// Kullanıcı profilini güncelle
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? theme,
    String? locale,
  }) async {
    final userId = currentUserId!;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (theme != null) updates['theme'] = theme;
    if (locale != null) updates['locale'] = locale;

    final data = await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromJson(data);
  }

  /// KVKK/GDPR: Hesap silme
  Future<void> deleteAccount() async {
    final userId = currentUserId!;
    await _supabase.rpc('delete_user_account', params: {'p_user_id': userId});
    await signOut();
  }
}
