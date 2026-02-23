/// Not paylaşım ekranı
/// Link oluşturma, şifreli koruma, e-posta daveti
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/config/supabase_config.dart';

class ShareNoteScreen extends ConsumerStatefulWidget {
  final String noteId;

  const ShareNoteScreen({super.key, required this.noteId});

  @override
  ConsumerState<ShareNoteScreen> createState() => _ShareNoteScreenState();
}

class _ShareNoteScreenState extends ConsumerState<ShareNoteScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _permission = 'view';
  bool _isLoading = false;
  String? _shareLink;
  List<Map<String, dynamic>> _existingShares = [];

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  Future<void> _loadShares() async {
    final data = await Supabase.instance.client
        .from('note_shares')
        .select()
        .eq('note_id', widget.noteId)
        .eq('is_active', true);

    setState(() => _existingShares = List<Map<String, dynamic>>.from(data as List));
  }

  Future<void> _createPublicLink() async {
    setState(() { _isLoading = true; });
    try {
      final result = await Supabase.instance.client
          .from('note_shares')
          .insert({
            'note_id': widget.noteId,
            'owner_id': Supabase.instance.client.auth.currentUser!.id,
            'share_type': 'link',
            'permission': _permission,
          })
          .select()
          .single();

      final token = result['share_token'] as String;
      final link = '${SupabaseConfig.url}/share/$token';
      setState(() => _shareLink = link);
      await _loadShares();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPasswordLink() async {
    if (_passwordController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be exactly 6 characters')),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      await Supabase.instance.client
          .from('note_shares')
          .insert({
            'note_id': widget.noteId,
            'owner_id': Supabase.instance.client.auth.currentUser!.id,
            'share_type': 'password',
            'permission': _permission,
            'password_hash': _passwordController.text,
          });
      await _loadShares();
      _passwordController.clear();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _inviteByEmail() async {
    if (_emailController.text.isEmpty) return;
    setState(() { _isLoading = true; });
    try {
      await Supabase.instance.client
          .from('note_invitations')
          .insert({
            'note_id': widget.noteId,
            'inviter_id': Supabase.instance.client.auth.currentUser!.id,
            'invitee_email': _emailController.text.trim(),
            'permission': _permission,
          });
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent!')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeShare(String shareId) async {
    await Supabase.instance.client
        .from('note_shares')
        .update({'is_active': false})
        .eq('id', shareId);
    await _loadShares();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.share)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // İzin seçimi
          _PermissionToggle(
            selected: _permission,
            onChanged: (v) => setState(() => _permission = v),
          ),

          const SizedBox(height: 20),

          // Açık link oluştur
          _ShareCard(
            icon: PhosphorIconsRegular.link,
            title: 'Public Link',
            subtitle: 'Anyone with the link can access',
            child: Column(
              children: [
                if (_shareLink != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _shareLink!,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _shareLink!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.linkCopied)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createPublicLink,
                  icon: const Icon(PhosphorIconsRegular.link, size: 16),
                  label: Text(_shareLink != null ? 'Create Another Link' : 'Create Link'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Şifreli link
          _ShareCard(
            icon: PhosphorIconsRegular.lockKey,
            title: 'Password Protected',
            subtitle: '6-character password required',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: '6-char password',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createPasswordLink,
                  child: const Text('Create'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // E-posta daveti
          _ShareCard(
            icon: PhosphorIconsRegular.envelope,
            title: 'Invite by Email',
            subtitle: 'Send an invitation directly',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'user@example.com'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _inviteByEmail,
                  child: const Text('Invite'),
                ),
              ],
            ),
          ),

          // Mevcut paylaşımlar
          if (_existingShares.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Active Shares',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 8),
            ..._existingShares.map((share) => ListTile(
              leading: Icon(
                share['share_type'] == 'link'
                    ? PhosphorIconsRegular.link
                    : PhosphorIconsRegular.lockKey,
                size: 18,
              ),
              title: Text(
                share['share_type'] == 'link' ? 'Public Link' : 'Password Link',
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                '${share['permission']} · ${share['use_count']} uses',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(PhosphorIconsRegular.x, size: 16, color: AppColors.error),
                onPressed: () => _revokeShare(share['id'] as String),
              ),
            )),
          ],
        ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1),
      ),
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PermissionToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Permission:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'view', label: Text(AppStrings.viewOnly)),
            ButtonSegment(value: 'edit', label: Text(AppStrings.canEdit)),
          ],
          selected: {selected},
          onSelectionChanged: (set) => onChanged(set.first),
        ),
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _ShareCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
