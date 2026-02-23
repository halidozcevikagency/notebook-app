/// Not Versiyon Repository'si  
/// Otomatik kaydedilen not sürümlerini yönetir
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_models.dart';
import '../models/note_model.dart';

class VersionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Bir nota ait versiyon geçmişini getir (en yeni önce)
  Future<List<NoteVersion>> fetchVersions(String noteId) async {
    final data = await _supabase
        .from('note_versions')
        .select()
        .eq('note_id', noteId)
        .order('version_number', ascending: false)
        .limit(50);
    return (data as List).map((j) => NoteVersion.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Yeni versiyon kaydet
  Future<void> saveVersion({
    required String noteId,
    required String editorId,
    required String title,
    required List<NoteBlock> blocks,
    required String contentText,
    required int versionNumber,
  }) async {
    await _supabase.from('note_versions').insert({
      'note_id': noteId,
      'editor_id': editorId,
      'title': title,
      'content': blocks.map((b) => b.toJson()).toList(),
      'content_text': contentText,
      'version_number': versionNumber,
    });
  }

  /// Son versiyon numarasını al
  Future<int> getLastVersionNumber(String noteId) async {
    final data = await _supabase
        .from('note_versions')
        .select('version_number')
        .eq('note_id', noteId)
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return 0;
    return data['version_number'] as int? ?? 0;
  }
}

/// Not versiyonu modeli
class NoteVersion {
  final String id;
  final String noteId;
  final String editorId;
  final String title;
  final List<NoteBlock> blocks;
  final String? contentText;
  final int versionNumber;
  final DateTime createdAt;

  const NoteVersion({
    required this.id,
    required this.noteId,
    required this.editorId,
    required this.title,
    required this.blocks,
    this.contentText,
    required this.versionNumber,
    required this.createdAt,
  });

  factory NoteVersion.fromJson(Map<String, dynamic> json) {
    List<NoteBlock> parseBlocks(dynamic content) {
      if (content == null) return [];
      if (content is List) {
        return content.map((b) => NoteBlock.fromJson(b as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return NoteVersion(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      editorId: json['editor_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      blocks: parseBlocks(json['content']),
      contentText: json['content_text'] as String?,
      versionNumber: json['version_number'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
