/// Not repository'si
/// CRUD işlemleri, arama, çöp kutusu yönetimi ve offline-first cache
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';
import '../../core/services/local_cache_service.dart';

class NoteRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalCacheService _cache = LocalCacheService();

  /// Kullanıcının tüm aktif notlarını yükle
  Future<List<NoteModel>> fetchNotes({
    String? workspaceId,
    String? folderId,
    bool pinnedOnly = false,
    bool favoritesOnly = false,
  }) async {
    try {
      var query = _supabase
          .from('notes')
          .select()
          .isFilter('deleted_at', null)
          .eq('is_archived', false)
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      if (workspaceId != null) {
        query = query.eq('workspace_id', workspaceId);
      }
      if (folderId != null) {
        query = query.eq('folder_id', folderId);
      }
      if (pinnedOnly) {
        query = query.eq('is_pinned', true);
      }
      if (favoritesOnly) {
        query = query.eq('is_favorite', true);
      }

      final List<dynamic> data = await query;
      final notes = data.map((j) => NoteModel.fromJson(j as Map<String, dynamic>)).toList();
      
      // Yerel cache'e kaydet (offline-first)
      await _cache.saveNotes(notes);
      return notes;
    } catch (e) {
      // Internet yoksa cache'den yükle
      return await _cache.getNotes(workspaceId: workspaceId, folderId: folderId);
    }
  }

  /// Çöp kutusundaki notları getir
  Future<List<NoteModel>> fetchTrashedNotes() async {
    final List<dynamic> data = await _supabase
        .from('notes')
        .select()
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);

    return data.map((j) => NoteModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Tek not yükle
  Future<NoteModel?> fetchNote(String noteId) async {
    try {
      final data = await _supabase
          .from('notes')
          .select()
          .eq('id', noteId)
          .maybeSingle();

      if (data == null) return null;
      final note = NoteModel.fromJson(data);
      await _cache.saveNote(note);
      return note;
    } catch (e) {
      return await _cache.getNote(noteId);
    }
  }

  /// Yeni not oluştur
  Future<NoteModel> createNote({
    required String ownerId,
    String? workspaceId,
    String? folderId,
    String title = 'Untitled',
  }) async {
    final data = await _supabase
        .from('notes')
        .insert({
          'owner_id': ownerId,
          'workspace_id': workspaceId,
          'folder_id': folderId,
          'title': title,
          'content': [],
        })
        .select()
        .single();

    return NoteModel.fromJson(data);
  }

  /// Not güncelle (500ms debounce ile çağrılır)
  Future<void> updateNote(NoteModel note) async {
    final payload = {
      'title': note.title,
      'content': note.blocks.map((b) => b.toJson()).toList(),
      'content_text': note.plainText,
      'is_pinned': note.isPinned,
      'is_favorite': note.isFavorite,
      'cover_image_url': note.coverImageUrl,
      'icon': note.icon,
      'word_count': note.plainText.split(' ').length,
    };

    // Önce cache'e kaydet
    await _cache.saveNote(note);

    // Sonra Supabase'e sync et
    await _supabase.from('notes').update(payload).eq('id', note.id);
  }

  /// Notu çöp kutusuna taşı (soft delete)
  Future<void> moveToTrash(String noteId) async {
    await _supabase.from('notes').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', noteId);
  }

  /// Notu çöp kutusundan kurtar
  Future<void> restoreFromTrash(String noteId) async {
    await _supabase.from('notes').update({
      'deleted_at': null,
    }).eq('id', noteId);
  }

  /// Notu kalıcı olarak sil
  Future<void> permanentlyDelete(String noteId) async {
    await _supabase.from('notes').delete().eq('id', noteId);
    await _cache.deleteNote(noteId);
  }

  /// Full-text arama
  Future<List<NoteModel>> searchNotes(
    String query, {
    String? workspaceId,
    List<String>? tagIds,
  }) async {
    final List<dynamic> data = await _supabase.rpc('search_notes', params: {
      'p_user_id': _supabase.auth.currentUser!.id,
      'p_query': query,
      'p_workspace_id': workspaceId,
      'p_tag_ids': tagIds,
      'p_limit': 50,
      'p_offset': 0,
    });

    return data.map((j) => NoteModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Notu iğnele / iğnesini kaldır
  Future<void> togglePin(String noteId, bool isPinned) async {
    await _supabase.from('notes').update({'is_pinned': isPinned}).eq('id', noteId);
  }

  /// Notu favoriye ekle / çıkar
  Future<void> toggleFavorite(String noteId, bool isFavorite) async {
    await _supabase
        .from('notes')
        .update({'is_favorite': isFavorite})
        .eq('id', noteId);
  }

  /// Realtime not değişikliklerini dinle
  RealtimeChannel subscribeToNotes(
    String userId,
    void Function(NoteModel) onInsert,
    void Function(NoteModel) onUpdate,
    void Function(String) onDelete,
  ) {
    return _supabase
        .channel('notes:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: userId,
          ),
          callback: (payload) {
            final note = NoteModel.fromJson(payload.newRecord);
            onInsert(note);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: userId,
          ),
          callback: (payload) {
            final note = NoteModel.fromJson(payload.newRecord);
            onUpdate(note);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notes',
          callback: (payload) {
            final id = payload.oldRecord['id'] as String;
            onDelete(id);
          },
        )
        .subscribe();
  }
}
