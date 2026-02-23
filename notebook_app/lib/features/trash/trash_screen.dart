/// Çöp kutusu ekranı
/// Silinen notları listeler, geri yükleme ve kalıcı silme
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/note_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state_widget.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadTrashedNotes();
    });
  }

  Future<void> _restore(String noteId) async {
    await ref.read(noteRepositoryProvider).restoreFromTrash(noteId);
    ref.read(notesProvider.notifier).removeNoteFromState(noteId);
  }

  Future<void> _permanentDelete(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: const Text('This note will be deleted forever. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(noteRepositoryProvider).permanentlyDelete(noteId);
      ref.read(notesProvider.notifier).removeNoteFromState(noteId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.trash),
        actions: [
          TextButton(
            onPressed: () async {
              final notes = notesAsync.value ?? [];
              if (notes.isEmpty) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(AppStrings.emptyTrash),
                  content: Text('Delete all ${notes.length} notes permanently?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                for (final n in notes) {
                  await ref.read(noteRepositoryProvider).permanentlyDelete(n.id);
                }
                ref.read(notesProvider.notifier).loadTrashedNotes();
              }
            },
            child: const Text(AppStrings.emptyTrash, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) => notes.isEmpty
            ? const EmptyStateWidget(
                title: 'Trash is empty',
                subtitle: 'Deleted notes appear here for 30 days',
                icon: PhosphorIconsRegular.trash,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                itemBuilder: (ctx, i) {
                  final note = notes[i];
                  return _TrashedNoteCard(
                    note: note,
                    onRestore: () => _restore(note.id),
                    onDelete: () => _permanentDelete(note.id),
                  );
                },
              ).animate().fadeIn(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _TrashedNoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashedNoteCard({
    required this.note,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (note.deletedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Deleted ${DateFormatter.format(note.deletedAt!)} · Will be permanently deleted after 30 days',
                style: const TextStyle(fontSize: 11, color: AppColors.error),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: onRestore,
                icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 14),
                label: const Text(AppStrings.restore),
                style: TextButton.styleFrom(foregroundColor: AppColors.success),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(PhosphorIconsRegular.trash, size: 14),
                label: const Text(AppStrings.delete),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
