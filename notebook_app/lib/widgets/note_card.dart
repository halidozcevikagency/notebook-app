/// Not kartı bileşeni
/// Dashboard'da notları gösterir - pin, favori, etiket rozetleri, bağlam menüsü
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/note_model.dart';
import '../data/models/base_models.dart';
import '../providers/app_providers.dart';
import '../providers/tag_providers.dart';

class NoteCard extends ConsumerWidget {
  final NoteModel note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/editor/${note.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.icon != null) ...[
                      Text(note.icon!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? AppStrings.untitled : note.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          PhosphorIconsBold.pushPin,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    if (note.isFavorite)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          PhosphorIconsBold.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                      ),
                    _NoteContextMenu(note: note),
                  ],
                ),
                if (note.contentText?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    note.contentText!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  DateFormatter.format(note.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
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

// ─── Not Bağlam Menüsü ──────────────────────────────────────────────────────

class _NoteContextMenu extends ConsumerWidget {
  final NoteModel note;

  const _NoteContextMenu({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        PhosphorIconsRegular.dotsThree,
        size: 18,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(children: [
            Icon(
              note.isPinned ? PhosphorIconsRegular.pushPin : PhosphorIconsRegular.pushPin,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(note.isPinned ? AppStrings.unpin : AppStrings.pin),
          ]),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(children: [
            Icon(
              note.isFavorite ? PhosphorIconsRegular.star : PhosphorIconsRegular.star,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(note.isFavorite ? 'Remove Favorite' : AppStrings.favorites),
          ]),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(children: [
            const Icon(PhosphorIconsRegular.share, size: 16),
            const SizedBox(width: 8),
            const Text(AppStrings.share),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'trash',
          child: Row(children: [
            const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            const Text(AppStrings.moveToTrash, style: TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'pin':
            await ref.read(notesProvider.notifier).togglePin(note.id, !note.isPinned);
            break;
          case 'favorite':
            await ref.read(noteRepositoryProvider).toggleFavorite(note.id, !note.isFavorite);
            ref.read(notesProvider.notifier).loadNotes();
            break;
          case 'share':
            if (context.mounted) context.push('/share/${note.id}');
            break;
          case 'trash':
            await ref.read(notesProvider.notifier).moveToTrash(note.id);
            break;
        }
      },
    );
  }
}
