/// Dashboard / Ana ekran
/// Sol kenar çubuğu (Workspace, Klasörler, Etiketler) + Not listesi
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/app_providers.dart';
import '../../providers/workspace_providers.dart';
import '../../data/models/note_model.dart';
import '../../data/models/base_models.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../search/search_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _sidebarOpen = true;
  int _selectedNavIndex = 0; // 0=All, 1=Pinned, 2=Favorites, 3=Trash

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes();
    });
  }

  Future<void> _createNote() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final selectedWorkspace = ref.read(selectedWorkspaceProvider);
    final selectedFolder = ref.read(selectedFolderProvider);

    final note = await ref.read(notesProvider.notifier).createNote(
      ownerId: profile.id,
      workspaceId: selectedWorkspace?.id,
      folderId: selectedFolder?.id,
    );
    if (mounted) context.go('/editor/${note.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      body: Row(
        children: [
          // Kenar çubuğu
          AnimatedContainer(
            duration: 250.ms,
            width: (_sidebarOpen || isWide) ? 260 : 0,
            child: (_sidebarOpen || isWide)
                ? _SidebarWidget(
                    selectedIndex: _selectedNavIndex,
                    onIndexChanged: (i) {
                      setState(() => _selectedNavIndex = i);
                      _loadByIndex(i);
                    },
                  )
                : const SizedBox.shrink(),
          ),

          // Dikey ayraç
          if (_sidebarOpen || isWide)
            Container(
              width: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),

          // Ana içerik
          Expanded(
            child: Column(
              children: [
                // Üst bar
                _TopBar(
                  onMenuTap: () => setState(() => _sidebarOpen = !_sidebarOpen),
                  onNewNote: _createNote,
                ),

                // Not listesi
                Expanded(
                  child: notesAsync.when(
                    data: (notes) => notes.isEmpty
                        ? const EmptyStateWidget()
                        : _NotesList(notes: notes),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIconsBold.warning, size: 48,
                              color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(AppStrings.error),
                          TextButton(
                            onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating action button (mobil)
      floatingActionButton: MediaQuery.of(context).size.width < 900
          ? FloatingActionButton(
              onPressed: _createNote,
              backgroundColor: AppColors.primary,
              child: const Icon(PhosphorIconsBold.plus, color: Colors.white),
            )
          : null,
    );
  }

  void _loadByIndex(int index) {
    final notifier = ref.read(notesProvider.notifier);
    switch (index) {
      case 0:
        notifier.loadNotes();
        break;
      case 1:
        notifier.loadNotes(pinnedOnly: true);
        break;
      case 2:
        notifier.loadNotes(favoritesOnly: true);
        break;
      case 3:
        notifier.loadTrashedNotes();
        break;
    }
  }
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onNewNote;

  const _TopBar({required this.onMenuTap, required this.onNewNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.list),
            onPressed: onMenuTap,
            tooltip: 'Toggle Sidebar',
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => showSearch(
                context: context,
                delegate: NoteSearchDelegate(ref),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceSecondaryDark
                      : AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.magnifyingGlass,
                      size: 16,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.search,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: onNewNote,
            icon: const Icon(PhosphorIconsBold.plus, size: 16),
            label: const Text(AppStrings.newNote),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar ────────────────────────────────────────────────────────────────

class _SidebarWidget extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const _SidebarWidget({
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).value;

    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        children: [
          // Kullanıcı bilgisi
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          (profile?.fullName?.isNotEmpty == true
                                  ? profile!.fullName![0]
                                  : profile?.email[0] ?? 'U')
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile?.email ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.gear, size: 18),
                  onPressed: () => context.go('/profile'),
                  tooltip: AppStrings.settings,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Navigasyon öğeleri
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _NavItem(
                  icon: PhosphorIconsRegular.note,
                  activeIcon: PhosphorIconsBold.note,
                  label: AppStrings.allNotes,
                  isSelected: selectedIndex == 0,
                  onTap: () => onIndexChanged(0),
                ),
                _NavItem(
                  icon: PhosphorIconsRegular.pushPin,
                  activeIcon: PhosphorIconsBold.pushPin,
                  label: AppStrings.pinned,
                  isSelected: selectedIndex == 1,
                  onTap: () => onIndexChanged(1),
                ),
                _NavItem(
                  icon: PhosphorIconsRegular.star,
                  activeIcon: PhosphorIconsBold.star,
                  label: AppStrings.favorites,
                  isSelected: selectedIndex == 2,
                  onTap: () => onIndexChanged(2),
                ),
                _NavItem(
                  icon: PhosphorIconsRegular.trash,
                  activeIcon: PhosphorIconsBold.trash,
                  label: AppStrings.trash,
                  isSelected: selectedIndex == 3,
                  onTap: () => onIndexChanged(3),
                ),
              ],
            ),
          ),

          // Alt butonlar
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _NavItem(
              icon: PhosphorIconsRegular.signOut,
              label: AppStrings.signOut,
              isSelected: false,
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? (activeIcon ?? icon) : icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Notes List ──────────────────────────────────────────────────────────────

class _NotesList extends ConsumerWidget {
  final List<NoteModel> notes;

  const _NotesList({required this.notes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final regularNotes = notes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pinnedNotes.isNotEmpty) ...[
          _SectionHeader(label: AppStrings.pinned, icon: PhosphorIconsBold.pushPin),
          const SizedBox(height: 8),
          ...pinnedNotes.map((note) => NoteCard(note: note, key: ValueKey(note.id))),
          const SizedBox(height: 16),
          _SectionHeader(label: AppStrings.recent, icon: PhosphorIconsRegular.clock),
          const SizedBox(height: 8),
        ],
        ...regularNotes.map((note) => NoteCard(note: note, key: ValueKey(note.id))),
      ].animate(interval: 30.ms).fadeIn().slideY(begin: 0.1),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }
}
