/// Workspace Yönetim Ekranı
/// Workspace oluşturma, düzenleme, silme; içindeki klasörler ve notları listeleme
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/base_models.dart';
import '../../providers/workspace_providers.dart';
import '../../providers/app_providers.dart';

class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspacesAsync = ref.watch(workspacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspaces'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.plus),
            onPressed: () => _showCreateWorkspaceDialog(context, ref),
            tooltip: 'New Workspace',
          ),
        ],
      ),
      body: workspacesAsync.when(
        data: (workspaces) => workspaces.isEmpty
            ? _EmptyWorkspaces(onCreate: () => _showCreateWorkspaceDialog(context, ref))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: workspaces.length,
                itemBuilder: (ctx, i) => _WorkspaceCard(
                  workspace: workspaces[i],
                  onTap: () => context.push('/workspace/${workspaces[i].id}'),
                  onEdit: () => _showEditWorkspaceDialog(context, ref, workspaces[i]),
                  onDelete: () => _confirmDelete(context, ref, workspaces[i]),
                ),
              ).animate().fadeIn(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showCreateWorkspaceDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    String selectedIcon = '📁';
    String selectedColor = '#6366F1';

    await showDialog(
      context: context,
      builder: (ctx) => _WorkspaceDialog(
        title: 'New Workspace',
        nameController: nameCtrl,
        initialIcon: selectedIcon,
        initialColor: selectedColor,
        onConfirm: (name, icon, color) async {
          if (name.trim().isEmpty) return;
          await ref.read(workspacesProvider.notifier).create(
            name: name.trim(),
            icon: icon,
            color: color,
          );
        },
      ),
    );
  }

  Future<void> _showEditWorkspaceDialog(
    BuildContext context, WidgetRef ref, WorkspaceModel ws) async {
    final nameCtrl = TextEditingController(text: ws.name);

    await showDialog(
      context: context,
      builder: (ctx) => _WorkspaceDialog(
        title: 'Edit Workspace',
        nameController: nameCtrl,
        initialIcon: ws.icon,
        initialColor: ws.color,
        onConfirm: (name, icon, color) async {
          await ref.read(workspacesProvider.notifier).update(
            id: ws.id, name: name.trim(), icon: icon, color: color,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, WorkspaceModel ws) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Text('Delete "${ws.name}"? Notes inside will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workspacesProvider.notifier).delete(ws.id);
    }
  }
}

// ─── Workspace Detail (Klasörler + Notlar) ────────────────────────────────

class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  const WorkspaceDetailScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes(workspaceId: widget.workspaceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspaces = ref.watch(workspacesProvider).value ?? [];
    final ws = workspaces.where((w) => w.id == widget.workspaceId).firstOrNull;
    final foldersAsync = ref.watch(foldersProvider(widget.workspaceId));
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: ws != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Text(ws.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(ws.name),
              ])
            : const Text('Workspace'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.folderPlus),
            onPressed: () => _showCreateFolderDialog(context),
            tooltip: 'New Folder',
          ),
          IconButton(
            icon: const Icon(PhosphorIconsBold.notePencil),
            onPressed: () => _createNote(),
            tooltip: 'New Note',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Klasörler bölümü
          if (foldersAsync.value?.isNotEmpty == true) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'FOLDERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 80,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final folder = foldersAsync.value![i];
                    return _FolderCard(
                      folder: folder,
                      onTap: () {
                        ref.read(selectedFolderProvider.notifier).state = folder;
                        ref.read(notesProvider.notifier).loadNotes(
                          workspaceId: widget.workspaceId,
                          folderId: folder.id,
                        );
                      },
                      onDelete: () async {
                        await ref.read(foldersProvider(widget.workspaceId).notifier)
                            .delete(folder.id);
                      },
                    );
                  },
                  childCount: foldersAsync.value!.length,
                ),
              ),
            ),
          ],

          // Notlar bölümü
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'NOTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
            ),
          ),

          notesAsync.when(
            data: (notes) => notes.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(PhosphorIconsRegular.noteBlank, size: 48,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                            const SizedBox(height: 12),
                            const Text('No notes in this workspace yet'),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final note = notes[i];
                          return _NoteRow(
                            title: note.title,
                            icon: note.icon,
                            updatedAt: note.updatedAt,
                            onTap: () => context.go('/editor/${note.id}'),
                          );
                        },
                        childCount: notes.length,
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _createNote() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    final note = await ref.read(notesProvider.notifier).createNote(
      ownerId: profile.id,
      workspaceId: widget.workspaceId,
    );
    if (mounted) context.go('/editor/${note.id}');
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(foldersProvider(widget.workspaceId).notifier)
          .create(name: nameCtrl.text.trim());
    }
  }
}

// ─── Alt Widget'lar ──────────────────────────────────────────────────────────

class _WorkspaceCard extends StatelessWidget {
  final WorkspaceModel workspace;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkspaceCard({
    required this.workspace,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(int.parse(workspace.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(workspace.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workspace.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      if (workspace.description?.isNotEmpty == true)
                        Text(workspace.description!, style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        )),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(PhosphorIconsRegular.dotsThree, size: 18,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [
                      const Icon(PhosphorIconsRegular.pencil, size: 16), const SizedBox(width: 8), const Text('Edit'),
                    ])),
                    PopupMenuItem(value: 'delete', child: Row(children: [
                      const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.error),
                      const SizedBox(width: 8), const Text('Delete', style: TextStyle(color: AppColors.error)),
                    ])),
                  ],
                  onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FolderCard({required this.folder, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(int.parse(folder.color.replaceFirst('#', '0xFF')));

    return Material(
      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(folder.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final String title;
  final String? icon;
  final DateTime updatedAt;
  final VoidCallback onTap;

  const _NoteRow({required this.title, this.icon, required this.updatedAt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: icon != null
          ? Text(icon!, style: const TextStyle(fontSize: 20))
          : Icon(PhosphorIconsRegular.note, size: 20,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(
        _formatDate(updatedAt),
        style: TextStyle(fontSize: 11,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
      ),
      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 16),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month]} ${date.day}';
  }
}

class _EmptyWorkspaces extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyWorkspaces({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsRegular.folder, size: 64, color: AppColors.textTertiaryLight),
          const SizedBox(height: 16),
          const Text('No Workspaces Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Organize your notes into workspaces'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(PhosphorIconsBold.plus, size: 16),
            label: const Text('Create Workspace'),
          ),
        ],
      ),
    );
  }
}

// ─── Workspace Dialog ────────────────────────────────────────────────────────

class _WorkspaceDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final String initialIcon;
  final String initialColor;
  final Future<void> Function(String name, String icon, String color) onConfirm;

  const _WorkspaceDialog({
    required this.title,
    required this.nameController,
    required this.initialIcon,
    required this.initialColor,
    required this.onConfirm,
  });

  @override
  State<_WorkspaceDialog> createState() => _WorkspaceDialogState();
}

class _WorkspaceDialogState extends State<_WorkspaceDialog> {
  late String _icon;
  late String _color;
  bool _loading = false;

  static const _icons = ['📁', '📂', '🗂️', '📒', '📔', '📕', '📗', '📘', '📙', '🏠', '💼', '🎨', '🔬', '💡', '⚡', '🚀'];
  static const _colors = [
    '#6366F1', '#8B5CF6', '#EC4899', '#EF4444', '#F59E0B',
    '#10B981', '#3B82F6', '#06B6D4', '#84CC16', '#F97316',
  ];

  @override
  void initState() {
    super.initState();
    _icon = widget.initialIcon;
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Workspace name'),
            ),
            const SizedBox(height: 16),
            const Text('Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) => GestureDetector(
                onTap: () => setState(() => _icon = icon),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _icon == icon ? AppColors.primary.withValues(alpha: 0.15) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: _icon == icon ? Border.all(color: AppColors.primary, width: 2) : null,
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                final c = Color(int.parse(color.replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _color == color
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: _color == color ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
            if (widget.nameController.text.trim().isEmpty) return;
            setState(() => _loading = true);
            await widget.onConfirm(widget.nameController.text.trim(), _icon, _color);
            if (context.mounted) Navigator.pop(context);
          },
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
