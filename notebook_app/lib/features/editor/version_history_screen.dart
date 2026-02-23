/// Not Versiyon Geçmişi Ekranı
/// Bir notun önceki sürümlerini gösterir ve geri yüklemeye olanak tanır
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/version_repository.dart';

class VersionHistoryScreen extends ConsumerWidget {
  final String noteId;
  final void Function(String title, List content) onRestore;

  const VersionHistoryScreen({
    super.key,
    required this.noteId,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Tutamaç çubuğu
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              children: [
                const Icon(PhosphorIconsBold.clockCounterClockwise,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Version History',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Expanded(
            child: FutureBuilder<List<NoteVersion>>(
              future: VersionRepository().fetchVersions(noteId),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsRegular.warning,
                            size: 40, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final versions = snapshot.data ?? [];
                if (versions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.clockCounterClockwise,
                          size: 52,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No versions saved yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versions are saved on each manual save',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: versions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final v = versions[i];
                    final isLatest = i == 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLatest
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isLatest
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (isDark
                                    ? AppColors.surfaceVariantDark
                                    : AppColors.surfaceVariantLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'v${v.versionNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isLatest
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                v.title,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isLatest)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Latest',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          DateFormatter.fullFormat(v.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        trailing: isLatest
                            ? null
                            : TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onRestore(
                                    v.title,
                                    v.blocks.map((b) => b.toJson()).toList(),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                ),
                                child: const Text(
                                  'Restore',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
