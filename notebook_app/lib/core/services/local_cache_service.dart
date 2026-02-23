/// Yerel önbellek servisi (Offline-First)
/// Hive kullanarak notları yerel olarak saklar
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';
import 'dart:convert';

class LocalCacheService {
  static const String _notesBoxName = 'notes_cache';
  static const String _prefsBoxName = 'app_prefs';

  static LocalCacheService? _instance;
  LocalCacheService._();
  factory LocalCacheService() {
    _instance ??= LocalCacheService._();
    return _instance!;
  }

  late Box _notesBox;
  late Box _prefsBox;
  bool _initialized = false;

  /// Hive'ı başlat
  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _notesBox = await Hive.openBox(_notesBoxName);
    _prefsBox = await Hive.openBox(_prefsBoxName);
    _initialized = true;
  }

  /// Notları cache'e kaydet
  Future<void> saveNotes(List<NoteModel> notes) async {
    for (final note in notes) {
      await _notesBox.put(note.id, jsonEncode(note.toJson()));
    }
  }

  /// Tek notu cache'e kaydet
  Future<void> saveNote(NoteModel note) async {
    await _notesBox.put(note.id, jsonEncode(note.toJson()));
  }

  /// Cache'den notları yükle
  Future<List<NoteModel>> getNotes({
    String? workspaceId,
    String? folderId,
  }) async {
    final notes = <NoteModel>[];
    for (final key in _notesBox.keys) {
      try {
        final jsonStr = _notesBox.get(key) as String?;
        if (jsonStr == null) continue;
        final note = NoteModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
        if (note.deletedAt != null) continue;
        if (workspaceId != null && note.workspaceId != workspaceId) continue;
        if (folderId != null && note.folderId != folderId) continue;
        notes.add(note);
      } catch (_) {}
    }
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  /// Tek notu cache'den yükle
  Future<NoteModel?> getNote(String noteId) async {
    try {
      final jsonStr = _notesBox.get(noteId) as String?;
      if (jsonStr == null) return null;
      return NoteModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Notu cache'den sil
  Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
  }

  /// Uygulama tercihleri
  Future<void> setPreference(String key, dynamic value) async {
    await _prefsBox.put(key, value);
  }

  dynamic getPreference(String key, {dynamic defaultValue}) {
    return _prefsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> clearAll() async {
    await _notesBox.clear();
  }
}
