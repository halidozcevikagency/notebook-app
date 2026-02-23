/// Profil ve ayarlar ekranı
/// KVKK/GDPR uyumlu hesap silme, tema değiştirme, profil güncelleme
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
          );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(AppStrings.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authRepositoryProvider).deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(AppStrings.save),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => profile == null
            ? const Center(child: Text('No profile found'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary,
                          backgroundImage: profile.avatarUrl != null
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? Text(
                                  (profile.fullName?.isNotEmpty == true
                                          ? profile.fullName![0]
                                          : profile.email[0])
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.borderLight,
                            child: IconButton(
                              icon: const Icon(PhosphorIconsRegular.pencil, size: 14),
                              onPressed: () => setState(() => _isEditing = true),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 24),

                  // İsim alanı
                  _SettingsSection(
                    title: 'Personal Info',
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsRegular.user,
                        label: 'Full Name',
                        trailing: _isEditing
                            ? SizedBox(
                                width: 180,
                                child: TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  autofocus: true,
                                ),
                              )
                            : Text(
                                profile.fullName ?? 'Not set',
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                        onTap: () => setState(() => _isEditing = true),
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.envelope,
                        label: 'Email',
                        trailing: Text(
                          profile.email,
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Görünüm ayarları
                  _SettingsSection(
                    title: 'Appearance',
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsRegular.sun,
                        label: 'Theme',
                        trailing: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(PhosphorIconsRegular.sun, size: 14)),
                            ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(PhosphorIconsRegular.moon, size: 14)),
                            ButtonSegment(value: 'system', label: Text('Auto')),
                          ],
                          selected: {currentTheme},
                          onSelectionChanged: (set) {
                            ref.read(themeProvider.notifier).setTheme(set.first);
                            ref.read(profileProvider.notifier).updateProfile(theme: set.first);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Premium durumu
                  if (profile.isPremium)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsBold.crown, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pro Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              Text('Unlimited notes & AI features', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Tehlikeli bölge
                  _SettingsSection(
                    title: 'Danger Zone',
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsRegular.signOut,
                        label: AppStrings.signOut,
                        textColor: AppColors.error,
                        onTap: () => ref.read(authRepositoryProvider).signOut(),
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.trash,
                        label: AppStrings.deleteAccount,
                        textColor: AppColors.error,
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, size: 20, color: textColor ?? AppColors.primary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: textColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(PhosphorIconsRegular.caretRight, size: 16) : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
