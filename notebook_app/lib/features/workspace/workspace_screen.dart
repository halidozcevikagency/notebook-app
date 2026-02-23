/// Workspace Yönetim Ekranı
/// Workspace oluşturma, düzenleme, silme; içindeki klasörler (sürükle-bırak, iç içe) ve notları listeleme
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/base_models.dart';
import '../../providers/workspace_providers.dart';
import '../../providers/app_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WORKSPACE LİSTESİ EKRANI
// ─────────────────────────────────────────────────────────────────────────────

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
            ? _EmptyWorkspaces(
                onCreate: () => _showCreateWorkspaceDialog(context, ref))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: workspaces.length,
                itemBuilder: (ctx, i) => _WorkspaceCard(
                  workspace: workspaces[i],
                  onTap: () =>
                      context.push('/workspace/${workspaces[i].id}'),
                  onEdit: () =>
                      _showEditWorkspaceDialog(context, ref, workspaces[i]),
                  onDelete: () =>
                      _confirmDeleteWorkspace(context, ref, workspaces[i]),
                ),
              ).animate().fadeIn(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showCreateWorkspaceDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => _WorkspaceDialog(
        title: 'New Workspace',
        nameController: nameCtrl,
        initialIcon: '📁',
        initialColor: '#6366F1',
        onConfirm: (name, icon, color) async {
          if (name.trim().isEmpty) return;
          await ref
              .read(workspacesProvider.notifier)
              .create(name: name.trim(), icon: icon, color: color);
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
              id: ws.id, name: name.trim(), icon: icon, color: color);
        },
      ),
    );
  }

  Future<void> _confirmDeleteWorkspace(
      BuildContext context, WidgetRef ref, WorkspaceModel ws) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Text(
            'Delete "${ws.name}"? Folders inside will be removed but notes will remain.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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

// ─────────────────────────────────────────────────────────────────────────────
// WORKSPACE DETAY EKRANI (Klasörler + Notlar)
// ─────────────────────────────────────────────────────────────────────────────

class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  const WorkspaceDetailScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceDetailScreen> createState() =>
      _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState
    extends ConsumerState<WorkspaceDetailScreen> {
  FolderModel? _selectedFolder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notesProvider.notifier)
          .loadNotes(workspaceId: widget.workspaceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspaces = ref.watch(workspacesProvider).value ?? [];
    final ws = workspaces
        .where((w) => w.id == widget.workspaceId)
        .firstOrNull;
    final foldersAsync = ref.watch(foldersProvider(widget.workspaceId));
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: ws != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Text(ws.icon,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(ws.name),
              ])
            : const Text('Workspace'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.folderPlus),
            onPressed: () => _showCreateFolderDialog(context, parentId: null),
            tooltip: 'New Folder',
          ),
          IconButton(
            icon: const Icon(PhosphorIconsBold.notePencil),
            onPressed: _createNote,
            tooltip: 'New Note',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sol: Klasör ağacı (Sürükle-bırak)
          if (foldersAsync.value?.isNotEmpty == true)
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: foldersAsync.when(
                data: (folders) => _FolderTreePanel(
                  folders: folders,
                  workspaceId: widget.workspaceId,
                  selectedFolder: _selectedFolder,
                  onFolderSelect: (folder) {
                    setState(() => _selectedFolder = folder);
                    ref.read(notesProvider.notifier).loadNotes(
                          workspaceId: widget.workspaceId,
                          folderId: folder?.id,
                        );
                  },
                  onCreateSubfolder: (parentId) =>
                      _showCreateFolderDialog(context, parentId: parentId),
                  onEditFolder: (folder) =>
                      _showEditFolderDialog(context, folder),
                  onDeleteFolder: (folder) =>
                      _confirmDeleteFolder(context, folder),
                  onReorder: (folders) => _reorderFolders(folders),
                ),
                loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5)),
                error: (e, _) =>
                    Center(child: Text('Error: $e', style: const TextStyle(fontSize: 12))),
              ),
            ),

          // Sağ: Notlar
          Expanded(
            child: Column(
              children: [
                // Başlık bar
                if (_selectedFolder != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(_selectedFolder!.icon,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          _selectedFolder!.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _selectedFolder = null);
                            ref
                                .read(notesProvider.notifier)
                                .loadNotes(workspaceId: widget.workspaceId);
                          },
                          icon: const Icon(
                              PhosphorIconsRegular.x,
                              size: 14),
                          label: const Text('Clear filter',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                // Not listesi
                Expanded(
                  child: notesAsync.when(
                    data: (notes) => notes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.noteBlank,
                                  size: 48,
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                ),
                                const SizedBox(height: 12),
                                const Text('No notes yet'),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: _createNote,
                                  icon: const Icon(PhosphorIconsBold.plus, size: 14),
                                  label: const Text('New Note'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: notes.length,
                            itemBuilder: (ctx, i) {
                              final note = notes[i];
                              return _NoteRow(
                                title: note.title,
                                icon: note.icon,
                                updatedAt: note.updatedAt,
                                onTap: () =>
                                    context.go('/editor/${note.id}'),
                              );
                            },
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        backgroundColor: AppColors.primary,
        child: const Icon(PhosphorIconsBold.plus, color: Colors.white),
      ),
    );
  }

  Future<void> _createNote() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    final note = await ref.read(notesProvider.notifier).createNote(
          ownerId: profile.id,
          workspaceId: widget.workspaceId,
          folderId: _selectedFolder?.id,
        );
    if (mounted) context.go('/editor/${note.id}');
  }

  Future<void> _showCreateFolderDialog(BuildContext context,
      {String? parentId}) async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => _FolderDialog(
        title: parentId != null ? 'New Subfolder' : 'New Folder',
        nameController: nameCtrl,
        initialIcon: '📂',
        initialColor: '#6366F1',
        onConfirm: (name, icon, color) async {
          if (name.trim().isEmpty) return;
          await ref.read(foldersProvider(widget.workspaceId).notifier).create(
                name: name.trim(),
                parentId: parentId,
                icon: icon,
                color: color,
              );
        },
      ),
    );
  }

  Future<void> _showEditFolderDialog(
      BuildContext context, FolderModel folder) async {
    final nameCtrl = TextEditingController(text: folder.name);
    await showDialog(
      context: context,
      builder: (ctx) => _FolderDialog(
        title: 'Edit Folder',
        nameController: nameCtrl,
        initialIcon: folder.icon,
        initialColor: folder.color,
        onConfirm: (name, icon, color) async {
          await ref
              .read(foldersProvider(widget.workspaceId).notifier)
              .update(id: folder.id, name: name.trim(), icon: icon, color: color);
        },
      ),
    );
  }

  Future<void> _confirmDeleteFolder(
      BuildContext context, FolderModel folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
            'Delete "${folder.name}"? Notes inside will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(foldersProvider(widget.workspaceId).notifier)
          .delete(folder.id);
      if (_selectedFolder?.id == folder.id) {
        setState(() => _selectedFolder = null);
        ref
            .read(notesProvider.notifier)
            .loadNotes(workspaceId: widget.workspaceId);
      }
    }
  }

  Future<void> _reorderFolders(List<FolderModel> reorderedFolders) async {
    await ref
        .read(foldersProvider(widget.workspaceId).notifier)
        .reorder(reorderedFolders);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KLASÖR AĞACI PANELİ (Sürükle-Bırak)
// ─────────────────────────────────────────────────────────────────────────────

class _FolderTreePanel extends StatefulWidget {
  final List<FolderModel> folders;
  final String workspaceId;
  final FolderModel? selectedFolder;
  final ValueChanged<FolderModel?> onFolderSelect;
  final ValueChanged<String?> onCreateSubfolder;
  final ValueChanged<FolderModel> onEditFolder;
  final ValueChanged<FolderModel> onDeleteFolder;
  final ValueChanged<List<FolderModel>> onReorder;

  const _FolderTreePanel({
    required this.folders,
    required this.workspaceId,
    required this.selectedFolder,
    required this.onFolderSelect,
    required this.onCreateSubfolder,
    required this.onEditFolder,
    required this.onDeleteFolder,
    required this.onReorder,
  });

  @override
  State<_FolderTreePanel> createState() => _FolderTreePanelState();
}

class _FolderTreePanelState extends State<_FolderTreePanel> {
  final Set<String> _expandedFolders = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rootFolders =
        widget.folders.where((f) => f.parentId == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Row(
            children: [
              Text(
                'FOLDERS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onCreateSubfolder(null),
                child: Icon(
                  PhosphorIconsRegular.plus,
                  size: 14,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ),

        // Tüm notlar butonu
        _FolderItem(
          label: 'All Notes',
          icon: '📝',
          color: '#6366F1',
          isSelected: widget.selectedFolder == null,
          isExpanded: false,
          hasChildren: false,
          onTap: () => widget.onFolderSelect(null),
          onExpandToggle: null,
          onAddSubfolder: null,
          onEdit: null,
          onDelete: null,
        ),

        // Sürükle-bırak liste (kök klasörler)
        Expanded(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            itemCount: rootFolders.length,
            onReorder: (oldIdx, newIdx) {
              final updated = [...rootFolders];
              if (newIdx > oldIdx) newIdx--;
              final item = updated.removeAt(oldIdx);
              updated.insert(newIdx, item);
              // tüm alt klasörler ile birleştir
              final subFolders = widget.folders
                  .where((f) => f.parentId != null)
                  .toList();
              widget.onReorder([...updated, ...subFolders]);
            },
            itemBuilder: (ctx, i) {
              final folder = rootFolders[i];
              final subFolders = widget.folders
                  .where((f) => f.parentId == folder.id)
                  .toList();
              final isExpanded = _expandedFolders.contains(folder.id);

              return KeyedSubtree(
                key: ValueKey(folder.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: _FolderItem(
                        label: folder.name,
                        icon: folder.icon,
                        color: folder.color,
                        isSelected: widget.selectedFolder?.id == folder.id,
                        isExpanded: isExpanded,
                        hasChildren: subFolders.isNotEmpty,
                        onTap: () => widget.onFolderSelect(folder),
                        onExpandToggle: subFolders.isNotEmpty
                            ? () => setState(() {
                                  if (isExpanded) {
                                    _expandedFolders.remove(folder.id);
                                  } else {
                                    _expandedFolders.add(folder.id);
                                  }
                                })
                            : null,
                        onAddSubfolder: () =>
                            widget.onCreateSubfolder(folder.id),
                        onEdit: () => widget.onEditFolder(folder),
                        onDelete: () => widget.onDeleteFolder(folder),
                      ),
                    ),
                    if (isExpanded && subFolders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: subFolders
                              .map((sub) => _FolderItem(
                                    label: sub.name,
                                    icon: sub.icon,
                                    color: sub.color,
                                    isSelected:
                                        widget.selectedFolder?.id == sub.id,
                                    isExpanded: false,
                                    hasChildren: false,
                                    onTap: () => widget.onFolderSelect(sub),
                                    onExpandToggle: null,
                                    onAddSubfolder: null,
                                    onEdit: () => widget.onEditFolder(sub),
                                    onDelete: () =>
                                        widget.onDeleteFolder(sub),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KLASÖR ÖĞE
// ─────────────────────────────────────────────────────────────────────────────

class _FolderItem extends StatelessWidget {
  final String label;
  final String icon;
  final String color;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback? onExpandToggle;
  final VoidCallback? onAddSubfolder;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FolderItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isExpanded,
    required this.hasChildren,
    required this.onTap,
    this.onExpandToggle,
    this.onAddSubfolder,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final folderColor = Color(int.parse(color.replaceFirst('#', '0xFF')));

    return Material(
      color: isSelected
          ? folderColor.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              if (onExpandToggle != null)
                GestureDetector(
                  onTap: onExpandToggle,
                  child: Icon(
                    isExpanded
                        ? PhosphorIconsBold.caretDown
                        : PhosphorIconsRegular.caretRight,
                    size: 10,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                )
              else
                const SizedBox(width: 10),
              const SizedBox(width: 4),
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? folderColor
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onEdit != null || onDelete != null || onAddSubfolder != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    PhosphorIconsRegular.dotsThree,
                    size: 14,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  itemBuilder: (_) => [
                    if (onAddSubfolder != null)
                      PopupMenuItem(
                        value: 'sub',
                        child: Row(children: [
                          const Icon(PhosphorIconsRegular.folderPlus, size: 14),
                          const SizedBox(width: 8),
                          const Text('Add subfolder',
                              style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(PhosphorIconsRegular.pencil, size: 14),
                          const SizedBox(width: 8),
                          const Text('Edit',
                              style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'del',
                        child: Row(children: [
                          const Icon(PhosphorIconsRegular.trash,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: 8),
                          const Text('Delete',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.error)),
                        ]),
                      ),
                  ],
                  onSelected: (v) {
                    if (v == 'sub') onAddSubfolder!();
                    if (v == 'edit') onEdit!();
                    if (v == 'del') onDelete!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKSPACE KARTI
// ─────────────────────────────────────────────────────────────────────────────

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
    final wsColor =
        Color(int.parse(workspace.color.replaceFirst('#', '0xFF')));

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
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: wsColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(workspace.icon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workspace.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      if (workspace.description?.isNotEmpty == true)
                        Text(
                          workspace.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(PhosphorIconsRegular.dotsThree,
                      size: 18,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(PhosphorIconsRegular.pencil, size: 16),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ])),
                    PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(PhosphorIconsRegular.trash,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          const Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                        ])),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOT SATIRI
// ─────────────────────────────────────────────────────────────────────────────

class _NoteRow extends StatelessWidget {
  final String title;
  final String? icon;
  final DateTime updatedAt;
  final VoidCallback onTap;

  const _NoteRow(
      {required this.title,
      this.icon,
      required this.updatedAt,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                icon != null
                    ? Text(icon!, style: const TextStyle(fontSize: 18))
                    : Icon(PhosphorIconsRegular.note,
                        size: 18,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                  _formatDate(updatedAt),
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                ),
                const SizedBox(width: 4),
                const Icon(PhosphorIconsRegular.caretRight, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month]} ${date.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOŞ WORKSPACE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyWorkspaces extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyWorkspaces({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsRegular.folder,
              size: 64, color: AppColors.textTertiaryLight),
          const SizedBox(height: 16),
          const Text('No Workspaces Yet',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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

// ─────────────────────────────────────────────────────────────────────────────
// WORKSPACE DIALOG (İkon + Renk seçici)
// ─────────────────────────────────────────────────────────────────────────────

class _WorkspaceDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final String initialIcon;
  final String initialColor;
  final Future<void> Function(String name, String icon, String color)
      onConfirm;

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

  static const _icons = [
    '📁', '📂', '🗂️', '📒', '📔', '📕', '📗', '📘', '📙',
    '🏠', '💼', '🎨', '🔬', '💡', '⚡', '🚀', '🎯', '🌟',
    '🌿', '🔮', '🎵', '📊', '🧪', '🏆',
  ];
  static const _colors = [
    '#6366F1', '#8B5CF6', '#EC4899', '#EF4444', '#F59E0B',
    '#10B981', '#3B82F6', '#06B6D4', '#84CC16', '#F97316',
    '#64748B', '#78716C',
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
        width: 380,
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
            const Text('Icon',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _icons.map((icon) => GestureDetector(
                    onTap: () => setState(() => _icon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _icon == icon
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: _icon == icon
                            ? Border.all(
                                color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                          child: Text(icon,
                              style: const TextStyle(fontSize: 20))),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ColorPicker(
              colors: _colors,
              selected: _color,
              onSelect: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  if (widget.nameController.text.trim().isEmpty) return;
                  setState(() => _loading = true);
                  await widget.onConfirm(
                      widget.nameController.text.trim(), _icon, _color);
                  if (context.mounted) Navigator.pop(context);
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KLASÖR DIALOG (İkon + Renk seçici)
// ─────────────────────────────────────────────────────────────────────────────

class _FolderDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final String initialIcon;
  final String initialColor;
  final Future<void> Function(String name, String icon, String color)
      onConfirm;

  const _FolderDialog({
    required this.title,
    required this.nameController,
    required this.initialIcon,
    required this.initialColor,
    required this.onConfirm,
  });

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  late String _icon;
  late String _color;
  bool _loading = false;

  static const _icons = [
    '📂', '📁', '📒', '📔', '📕', '📗', '📘', '📙',
    '🗂️', '💼', '🎨', '🔬', '💡', '🌿', '🎵', '🏆',
  ];
  static const _colors = [
    '#6366F1', '#8B5CF6', '#EC4899', '#EF4444', '#F59E0B',
    '#10B981', '#3B82F6', '#06B6D4', '#84CC16', '#F97316',
    '#64748B', '#78716C',
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
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Folder name'),
            ),
            const SizedBox(height: 14),
            const Text('Icon',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _icons.map((icon) => GestureDetector(
                    onTap: () => setState(() => _icon = icon),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _icon == icon
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(7),
                        border: _icon == icon
                            ? Border.all(
                                color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                          child: Text(icon,
                              style: const TextStyle(fontSize: 18))),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Color',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _ColorPicker(
              colors: _colors,
              selected: _color,
              onSelect: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  if (widget.nameController.text.trim().isEmpty) return;
                  setState(() => _loading = true);
                  await widget.onConfirm(
                      widget.nameController.text.trim(), _icon, _color);
                  if (context.mounted) Navigator.pop(context);
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RENK SEÇİCİ WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final c = Color(int.parse(color.replaceFirst('#', '0xFF')));
        final isSelected = selected == color;
        return GestureDetector(
          onTap: () => onSelect(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: c.withValues(alpha: 0.55), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
