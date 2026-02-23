/// Not editörü - Blok tabanlı zengin metin editörü
/// 2000ms debounce ile sessiz arka plan kaydı - yazma akışını KESINTISIZ korur
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/version_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/tag_providers.dart';
import '../../widgets/tag_manager_widget.dart';
import 'version_history_screen.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late quill.QuillController _controller;
  late TextEditingController _titleController;
  Timer? _saveTimer;

  // Save durumu - ValueNotifier kullanarak editörü YENIDEN OLUŞTURMADAN güncellenir
  final ValueNotifier<bool> _isSaving = ValueNotifier(false);
  final ValueNotifier<DateTime?> _lastSaved = ValueNotifier(null);

  // Yerel not kopyası - provider'ı tetiklemeden takip edilir
  NoteModel? _localNote;
  bool _isLoaded = false;
  bool _showAiPanel = false;
  bool _isAiLoading = false;
  List<String> _noteTagIds = [];
  final VersionRepository _versionRepo = VersionRepository();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _controller = quill.QuillController.basic();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final repo = NoteRepository();
    _localNote = await repo.fetchNote(widget.noteId);

    if (_localNote != null && mounted) {
      _titleController.text = _localNote!.title == AppStrings.untitled ? '' : _localNote!.title;

      // İçerik varsa editöre yükle
      if (_localNote!.blocks.isNotEmpty) {
        final delta = _blocksToQuillDelta(_localNote!.blocks);
        _controller = quill.QuillController(
          document: quill.Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }

      // Etiketleri yükle
      _noteTagIds = await ref.read(tagRepositoryProvider).fetchNoteTagIds(widget.noteId);

      setState(() => _isLoaded = true);

      // Listener'ları sadece yükleme tamamlandıktan SONRA ekle
      _controller.document.changes.listen((_) => _scheduleBackgroundSave());
      _titleController.addListener(_scheduleBackgroundSave);
    }
  }

  /// Kaydı programla - kullanıcı yazmayı bıraktıktan 2 saniye sonra
  /// setState veya provider tetiklemez → yazma akışı hiç kesilmez
  void _scheduleBackgroundSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 2000), _saveInBackground);
  }

  /// Arka planda sessiz kayıt - UI yeniden oluşturulmaz
  Future<void> _saveInBackground() async {
    if (_localNote == null || !mounted) return;

    _isSaving.value = true;

    try {
      final plainText = _controller.document.toPlainText().trim();
      final blocks = _quillDeltaToBlocks(_controller.document);
      final title = _titleController.text.trim();

      _localNote = _localNote!.copyWith(
        title: title.isEmpty ? AppStrings.untitled : title,
        blocks: blocks,
        contentText: plainText,
      );

      // Sadece repository'ye kaydet - HİÇBİR provider tetiklenmiyor
      final repo = NoteRepository();
      await repo.updateNote(_localNote!);

      _lastSaved.value = DateTime.now();
    } catch (e) {
      // Sessiz hata - yazma akışını kesme
    } finally {
      _isSaving.value = false;
    }
  }

  /// Editörden çıkarken dashboard listesini güncelle
  Future<void> _onLeave() async {
    _saveTimer?.cancel();
    await _saveInBackground();

    // Şimdi dashboard state'ini güncelle (sayfa kapanıyor, yeniden oluşturma önemli değil)
    if (_localNote != null && mounted) {
      ref.read(notesProvider.notifier).updateNoteInState(_localNote!);
    }
  }

  // Quill Document → NoteBlock dönüşümü
  List<NoteBlock> _quillDeltaToBlocks(quill.Document doc) {
    return [
      NoteBlock(
        id: 'main',
        type: BlockType.paragraph,
        content: doc.toPlainText().trim(),
      ),
    ];
  }

  // NoteBlock → Quill Delta dönüşümü
  Delta _blocksToQuillDelta(List<NoteBlock> blocks) {
    final ops = <Map<String, dynamic>>[];
    for (final block in blocks) {
      if (block.content.isNotEmpty) {
        ops.add({'insert': '${block.content}\n'});
      }
    }
    if (ops.isEmpty) ops.add({'insert': '\n'});
    return Delta.fromJson(ops);
  }

  // AI işlemleri
  Future<void> _runAiOperation(String operation) async {
    final plainText = _controller.document.toPlainText().trim();
    if (plainText.isEmpty) return;

    setState(() => _isAiLoading = true);
    final ai = AiService();

    try {
      String result;
      switch (operation) {
        case 'summarize':
          result = await ai.summarizeNote(plainText);
          _showAiResult('Summary', result);
          break;
        case 'spellcheck':
          result = await ai.spellCheck(plainText);
          _replaceContent(result);
          break;
        case 'translate_tr':
          result = await ai.translateText(plainText, 'Turkish');
          _showAiResult('Turkish Translation', result);
          break;
        case 'translate_en':
          result = await ai.translateText(plainText, 'English');
          _showAiResult('English Translation', result);
          break;
        default:
          result = plainText;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  void _showAiResult(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(PhosphorIconsBold.sparkle, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  IconButton(icon: const Icon(PhosphorIconsRegular.x), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(content, style: const TextStyle(height: 1.6)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(PhosphorIconsRegular.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _replaceContent(String newContent) {
    _controller.replaceText(0, _controller.document.length - 1, newContent, null);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _isSaving.dispose();
    _lastSaved.dispose();
    _titleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _onLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () async {
              await _onLeave();
              if (mounted) Navigator.of(context).pop();
            },
          ),
          // Save göstergesi - sadece kendi ValueNotifier'ına bağlı, editörü etkilemez
          title: ValueListenableBuilder<bool>(
            valueListenable: _isSaving,
            builder: (_, saving, __) => ValueListenableBuilder<DateTime?>(
              valueListenable: _lastSaved,
              builder: (_, lastSaved, __) {
                if (saving) {
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(AppStrings.saving, style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    )),
                  ]);
                }
                if (lastSaved != null) {
                  return Text(AppStrings.saved, style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: _isAiLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(PhosphorIconsBold.sparkle),
              onPressed: () => setState(() => _showAiPanel = !_showAiPanel),
              tooltip: 'AI Assistant',
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.tag),
              onPressed: _showTagManager,
              tooltip: 'Tags',
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.clockCounterClockwise),
              onPressed: _showVersionHistory,
              tooltip: 'Version History',
            ),
            PopupMenuButton<String>(
              icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'save_version', child: Row(children: [
                  const Icon(PhosphorIconsRegular.clockCounterClockwise, size: 16), const SizedBox(width: 8),
                  const Text('Save Version'),
                ])),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'export_pdf', child: Row(children: [
                  const Icon(PhosphorIconsRegular.filePdf, size: 16), const SizedBox(width: 8),
                  const Text(AppStrings.exportAsPdf),
                ])),
                PopupMenuItem(value: 'export_md', child: Row(children: [
                  const Icon(PhosphorIconsRegular.fileMd, size: 16), const SizedBox(width: 8),
                  const Text(AppStrings.exportAsMarkdown),
                ])),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'trash', child: Row(children: [
                  const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.error), const SizedBox(width: 8),
                  const Text(AppStrings.moveToTrash, style: TextStyle(color: AppColors.error)),
                ])),
              ],
              onSelected: (value) async {
                if (value == 'trash' && _localNote != null) {
                  await NoteRepository().moveToTrash(_localNote!.id);
                  ref.read(notesProvider.notifier).removeNoteFromState(_localNote!.id);
                  if (mounted) Navigator.pop(context);
                } else if (value == 'export_pdf' || value == 'export_md') {
                  _exportNote(value);
                } else if (value == 'save_version') {
                  await _saveInBackground();
                  await _saveVersion();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Version saved!')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: !_isLoaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_showAiPanel)
                    _AiPanel(onOperation: _runAiOperation, isLoading: _isAiLoading)
                        .animate().fadeIn().slideY(begin: -0.2),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      border: Border(bottom: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      )),
                    ),
                    child: quill.QuillSimpleToolbar(
                      controller: _controller,
                      config: const quill.QuillSimpleToolbarConfig(
                        showAlignmentButtons: false,
                        showBackgroundColorButton: false,
                        showClearFormat: true,
                        showColorButton: true,
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: true,
                        showHeaderStyle: true,
                        showListBullets: true,
                        showListNumbers: true,
                        showListCheck: true,
                        showCodeBlock: true,
                        showQuote: true,
                        showLink: true,
                        showDividers: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık - ayrı TextField, Quill'den tamamen bağımsız
                          TextField(
                            controller: _titleController,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.untitled,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.next,
                          ),
                          if (_localNote != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                DateFormatter.fullFormat(_localNote!.updatedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                ),
                              ),
                            ),
                          // Etiketler
                          if (_noteTagIds.isNotEmpty) ...[
                            _NoteTagRow(tagIds: _noteTagIds),
                            const SizedBox(height: 12),
                          ],
                          // Quill editör - focus ve cursor tamamen korunur
                          quill.QuillEditor.basic(
                            controller: _controller,
                            config: quill.QuillEditorConfig(
                              placeholder: AppStrings.startWriting,
                              padding: EdgeInsets.zero,
                              expands: false,
                              autoFocus: false,
                            ),
                          ),
                          const SizedBox(height: 200),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showTagManager() {
    if (_localNote == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TagManagerWidget(
        noteId: widget.noteId,
        selectedTagIds: _noteTagIds,
        onTagsChanged: (ids) => setState(() => _noteTagIds = ids),
      ),
    );
  }

  void _showVersionHistory() {
    if (_localNote == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: VersionHistoryScreen(
          noteId: widget.noteId,
          onRestore: (title, blocksJson) => _restoreVersion(title, blocksJson),
        ),
      ),
    );
  }

  Future<void> _restoreVersion(String title, List blocksJson) async {
    final blocks = blocksJson
        .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
        .toList();
    setState(() {
      _titleController.text = title;
      final delta = _blocksToQuillDelta(blocks);
      _controller.document = quill.Document.fromDelta(delta);
      if (_localNote != null) {
        _localNote = _localNote!.copyWith(title: title, blocks: blocks);
      }
    });
    // Geri yüklenen versiyonu yeni bir versiyon olarak kaydet
    // Böylece versiyon geçmişinde "Latest" etiketi doğru versiyona işaret eder
    await _saveInBackground();
    await _saveVersion();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version restored and saved as new version.')),
      );
    }
  }

  Future<void> _saveVersion() async {
    if (_localNote == null) return;
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    try {
      final nextVersion = await _versionRepo.getLastVersionNumber(widget.noteId) + 1;
      await _versionRepo.saveVersion(
        noteId: widget.noteId,
        editorId: profile.id,
        title: _localNote!.title,
        blocks: _localNote!.blocks,
        contentText: _localNote!.plainText,
        versionNumber: nextVersion,
      );
    } catch (_) {
      // Versiyon kaydetme başarısız olsa da not kaydedilmeye devam etsin
    }
  }

  void _exportNote(String type) async {
    if (_localNote == null) return;
    
    // Önce kaydet
    await _saveInBackground();
    
    final plainText = _controller.document.toPlainText().trim();
    
    try {
      if (type == 'export_pdf') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Generating PDF...')),
          );
        }
        await ExportService.exportAsPdf(context, _localNote!, plainText);
      } else {
        ExportService.exportAsMarkdown(_localNote!, plainText);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Markdown file downloaded')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ─── Note Tag Row ────────────────────────────────────────────────────────────

class _NoteTagRow extends ConsumerWidget {
  final List<String> tagIds;
  const _NoteTagRow({required this.tagIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    return tagsAsync.when(
      data: (allTags) {
        final noteTags = allTags.where((t) => tagIds.contains(t.id)).toList();
        if (noteTags.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: noteTags.map((tag) {
            final color = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(tag.name,
                  style: TextStyle(
                      fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── AI Panel ────────────────────────────────────────────────────────────────

class _AiPanel extends StatelessWidget {
  final void Function(String) onOperation;
  final bool isLoading;

  const _AiPanel({required this.onOperation, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operations = [
      ('summarize', PhosphorIconsRegular.textAlignLeft, 'Summarize'),
      ('spellcheck', PhosphorIconsRegular.pencil, 'Spell Check'),
      ('translate_tr', PhosphorIconsRegular.globe, 'To Turkish'),
      ('translate_en', PhosphorIconsRegular.globe, 'To English'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        )),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsBold.sparkle, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          const Text('AI', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: operations.map((op) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: isLoading
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                        : Icon(op.$2, size: 14),
                    label: Text(op.$3, style: const TextStyle(fontSize: 12)),
                    onPressed: isLoading ? null : () => onOperation(op.$1),
                    backgroundColor: isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
