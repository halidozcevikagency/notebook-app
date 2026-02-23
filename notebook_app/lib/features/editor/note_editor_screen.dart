/// Not editörü - Blok tabanlı zengin metin editörü
/// / komutu ile blok ekleme, 500ms debounce ile otomatik kayıt
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/ai_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/note_model.dart';
import '../../providers/app_providers.dart';

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
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _showAiPanel = false;
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _controller = quill.QuillController.basic();
    _loadNote();
  }

  Future<void> _loadNote() async {
    await ref.read(activeNoteProvider.notifier).loadNote(widget.noteId);
    final note = ref.read(activeNoteProvider);
    if (note != null && mounted) {
      _titleController.text = note.title;
      // Quill formatına dönüştür
      if (note.blocks.isNotEmpty) {
        final delta = _blocksToQuillDelta(note.blocks);
        _controller = quill.QuillController(
          document: quill.Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
      setState(() {});
    }
    _controller.document.changes.listen((_) => _onContentChanged());
    _titleController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    _hasUnsavedChanges = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveNote);
    setState(() {});
  }

  Future<void> _saveNote() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    final note = ref.read(activeNoteProvider);
    if (note == null) return;

    final plainText = _controller.document.toPlainText().trim();
    final blocks = _quillDeltaToBlocks(_controller.document);

    final updatedNote = note.copyWith(
      title: _titleController.text.trim().isEmpty
          ? AppStrings.untitled
          : _titleController.text.trim(),
      blocks: blocks,
      contentText: plainText,
    );

    ref.read(activeNoteProvider.notifier).setNote(updatedNote);
    await ref.read(activeNoteProvider.notifier).save();
    ref.read(notesProvider.notifier).updateNoteInState(updatedNote);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });
    }
  }

  // Quill Delta -> NoteBlock dönüşümü
  List<NoteBlock> _quillDeltaToBlocks(quill.Document doc) {
    return [
      NoteBlock(
        id: 'main',
        type: BlockType.paragraph,
        content: doc.toPlainText().trim(),
      ),
    ];
  }

  // NoteBlock -> Quill Delta dönüşümü
  quill.Delta _blocksToQuillDelta(List<NoteBlock> blocks) {
    final delta = quill.Delta();
    for (final block in blocks) {
      if (block.content.isNotEmpty) {
        delta.insert('${block.content}\n');
      }
    }
    if (delta.isEmpty) delta.insert('\n');
    return delta;
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
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.pop(ctx),
                  ),
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
              Row(
                children: [
                  Expanded(
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
            ],
          ),
        ),
      ),
    );
  }

  void _replaceContent(String newContent) {
    _controller.replaceText(
      0,
      _controller.document.length - 1,
      newContent,
      null,
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_hasUnsavedChanges) _saveNote();
    _titleController.dispose();
    _controller.dispose();
    ref.read(activeNoteProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final note = ref.watch(activeNoteProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSaving
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(AppStrings.saving, style: const TextStyle(fontSize: 13)),
              ])
            : Text(AppStrings.saved, style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              )),
        centerTitle: true,
        actions: [
          // AI asistan butonu
          IconButton(
            icon: _isAiLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(PhosphorIconsBold.sparkle),
            onPressed: () => setState(() => _showAiPanel = !_showAiPanel),
            tooltip: 'AI Assistant',
          ),
          // Paylaş
          IconButton(
            icon: const Icon(PhosphorIconsRegular.share),
            onPressed: note != null ? () => _showShareOptions(context, note) : null,
            tooltip: AppStrings.share,
          ),
          // Daha fazla
          PopupMenuButton<String>(
            icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'export_pdf',
                child: Row(children: [
                  const Icon(PhosphorIconsRegular.filePdf, size: 16),
                  const SizedBox(width: 8),
                  const Text(AppStrings.exportAsPdf),
                ]),
              ),
              PopupMenuItem(
                value: 'export_md',
                child: Row(children: [
                  const Icon(PhosphorIconsRegular.fileMd, size: 16),
                  const SizedBox(width: 8),
                  const Text(AppStrings.exportAsMarkdown),
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
              if (value == 'trash' && note != null) {
                await ref.read(notesProvider.notifier).moveToTrash(note.id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Panel
          if (_showAiPanel)
            _AiPanel(
              onOperation: _runAiOperation,
              isLoading: _isAiLoading,
            ).animate().fadeIn().slideY(begin: -0.2),

          // Quill toolbar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
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

          // Editör içeriği
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Not başlığı
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

                  // Zaman damgası
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        DateFormatter.fullFormat(note.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),

                  // Quill editörü
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
    );
  }

  void _showShareOptions(BuildContext context, NoteModel note) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Placeholder(), // Share screen placeholder
    ));
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
      ('spellcheck', PhosphorIconsRegular.spellCheck, 'Spell Check'),
      ('translate_tr', PhosphorIconsRegular.translate, 'To Turkish'),
      ('translate_en', PhosphorIconsRegular.translate, 'To English'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
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
                children: operations.map((op) {
                  return Padding(
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
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
