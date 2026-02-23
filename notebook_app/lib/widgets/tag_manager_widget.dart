/// Etiket Yöneticisi Widget'ı
/// Not editöründe etiket ekleme/kaldırma ve yeni etiket oluşturma
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/app_colors.dart';
import '../data/models/base_models.dart';
import '../providers/tag_providers.dart';

class TagManagerWidget extends ConsumerStatefulWidget {
  final String noteId;
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onTagsChanged;

  const TagManagerWidget({
    super.key,
    required this.noteId,
    required this.selectedTagIds,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<TagManagerWidget> createState() => _TagManagerWidgetState();
}

class _TagManagerWidgetState extends ConsumerState<TagManagerWidget> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tagsAsync = ref.watch(tagsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsBold.tag, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Tags',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCreateTagDialog(context),
                icon: const Icon(PhosphorIconsBold.plus, size: 14),
                label: const Text('New Tag', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          tagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(PhosphorIconsRegular.tag, size: 36,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                        const SizedBox(height: 8),
                        Text('No tags yet. Create one!',
                            style: TextStyle(
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
                      ],
                    ),
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) => _TagChip(
                  tag: tag,
                  isSelected: _selectedIds.contains(tag.id),
                  onToggle: () => _toggleTag(tag),
                  onDelete: () => _deleteTag(tag),
                )).toList(),
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onTagsChanged(_selectedIds);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTag(TagModel tag) async {
    final repo = ref.read(tagRepositoryProvider);
    setState(() {
      if (_selectedIds.contains(tag.id)) {
        _selectedIds.remove(tag.id);
      } else {
        _selectedIds.add(tag.id);
      }
    });
    try {
      if (_selectedIds.contains(tag.id)) {
        await repo.addTagToNote(noteId: widget.noteId, tagId: tag.id);
      } else {
        await repo.removeTagFromNote(noteId: widget.noteId, tagId: tag.id);
      }
    } catch (e) {
      // Hata durumunda geri al
      setState(() {
        if (_selectedIds.contains(tag.id)) {
          _selectedIds.remove(tag.id);
        } else {
          _selectedIds.add(tag.id);
        }
      });
    }
  }

  Future<void> _deleteTag(TagModel tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Delete "${tag.name}"?'),
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
      await ref.read(tagsProvider.notifier).delete(tag.id);
      setState(() => _selectedIds.remove(tag.id));
    }
  }

  Future<void> _showCreateTagDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String selectedColor = '#6366F1';
    const colors = [
      '#6366F1', '#8B5CF6', '#EC4899', '#EF4444', '#F59E0B',
      '#10B981', '#3B82F6', '#06B6D4', '#84CC16', '#F97316',
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration:
                    const InputDecoration(hintText: 'Tag name'),
              ),
              const SizedBox(height: 12),
              const Text('Color',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) {
                  final c = Color(int.parse(color.replaceFirst('#', '0xFF')));
                  return GestureDetector(
                    onTap: () => setDialog(() => selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: selectedColor == color
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                            : null,
                      ),
                      child: selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await ref.read(tagsProvider.notifier).create(
                        name: nameCtrl.text.trim(),
                        color: selectedColor,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tag Chip ────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final TagModel tag;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: FilterChip(
          label: Text(tag.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : color,
              )),
          selected: isSelected,
          onSelected: (_) => onToggle(),
          backgroundColor: color.withValues(alpha: 0.1),
          selectedColor: color,
          checkmarkColor: Colors.white,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}

// ─── Inline Tag Display (Not kartı için) ─────────────────────────────────────

class TagBadge extends StatelessWidget {
  final String name;
  final String color;

  const TagBadge({super.key, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = Color(int.parse(color.replaceFirst('#', '0xFF')));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
