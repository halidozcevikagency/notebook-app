/// Etiket (Tag) Repository'si
/// Etiket CRUD işlemleri ve not-etiket ilişkilendirme
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_models.dart';

class TagRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  String get _userId => _supabase.auth.currentUser!.id;

  /// Kullanıcının tüm etiketlerini yükle
  Future<List<TagModel>> fetchTags() async {
    final data = await _supabase
        .from('tags')
        .select()
        .eq('owner_id', _userId)
        .order('name');
    return (data as List).map((j) => TagModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Yeni etiket oluştur
  Future<TagModel> createTag({required String name, String color = '#6366F1'}) async {
    final data = await _supabase.from('tags').insert({
      'owner_id': _userId,
      'name': name,
      'color': color,
    }).select().single();
    return TagModel.fromJson(data);
  }

  /// Etiket güncelle
  Future<TagModel> updateTag({required String id, String? name, String? color}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (color != null) updates['color'] = color;
    final data = await _supabase
        .from('tags')
        .update(updates)
        .eq('id', id)
        .eq('owner_id', _userId)
        .select()
        .single();
    return TagModel.fromJson(data);
  }

  /// Etiket sil
  Future<void> deleteTag(String id) async {
    await _supabase.from('tags').delete().eq('id', id).eq('owner_id', _userId);
  }

  /// Nota etiket ekle
  Future<void> addTagToNote({required String noteId, required String tagId}) async {
    await _supabase.from('note_tags').upsert({
      'note_id': noteId,
      'tag_id': tagId,
    });
  }

  /// Nottan etiket kaldır
  Future<void> removeTagFromNote({required String noteId, required String tagId}) async {
    await _supabase
        .from('note_tags')
        .delete()
        .eq('note_id', noteId)
        .eq('tag_id', tagId);
  }

  /// Bir nota ait etiket ID'lerini getir
  Future<List<String>> fetchNoteTagIds(String noteId) async {
    final data = await _supabase
        .from('note_tags')
        .select('tag_id')
        .eq('note_id', noteId);
    return (data as List).map((j) => j['tag_id'] as String).toList();
  }
}
