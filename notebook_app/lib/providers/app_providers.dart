/// Riverpod provider'ları
/// Uygulama state'ini yönetir
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/base_models.dart';
import '../data/models/note_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/note_repository.dart';

// ─── Repository Providers ───────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

// ─── Auth State ─────────────────────────────────────────────────────────────

/// Auth state provider - Kullanıcı oturum durumunu izler
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Aktif kullanıcı profili
final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  return ProfileNotifier(ref.watch(authRepositoryProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthRepository _repo;

  ProfileNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repo.loadProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl, String? theme}) async {
    try {
      final updated = await _repo.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        theme: theme,
      );
      state = AsyncValue.data(updated);
    } catch (e) {
      rethrow;
    }
  }
}

// ─── Theme Provider ──────────────────────────────────────────────────────────

/// Uygulama teması ('light', 'dark', 'system')
final themeProvider = StateNotifierProvider<ThemeNotifier, String>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<String> {
  ThemeNotifier() : super('system');

  void setTheme(String theme) {
    state = theme;
  }
}

// ─── Notes State ─────────────────────────────────────────────────────────────

/// Seçili workspace
final selectedWorkspaceProvider = StateProvider<WorkspaceModel?>((ref) => null);

/// Seçili folder
final selectedFolderProvider = StateProvider<FolderModel?>((ref) => null);

/// Seçili not ID
final selectedNoteIdProvider = StateProvider<String?>((ref) => null);

/// Not listesi provider
final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteModel>>>((ref) {
  return NotesNotifier(ref.watch(noteRepositoryProvider));
});

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  final NoteRepository _repo;

  NotesNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> loadNotes({
    String? workspaceId,
    String? folderId,
    bool pinnedOnly = false,
    bool favoritesOnly = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repo.fetchNotes(
        workspaceId: workspaceId,
        folderId: folderId,
        pinnedOnly: pinnedOnly,
        favoritesOnly: favoritesOnly,
      );
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadTrashedNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repo.fetchTrashedNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<NoteModel> createNote({
    required String ownerId,
    String? workspaceId,
    String? folderId,
  }) async {
    final note = await _repo.createNote(
      ownerId: ownerId,
      workspaceId: workspaceId,
      folderId: folderId,
    );
    // State'e yeni notu ekle
    final current = state.value ?? [];
    state = AsyncValue.data([note, ...current]);
    return note;
  }

  void updateNoteInState(NoteModel updatedNote) {
    final current = state.value ?? [];
    final idx = current.indexWhere((n) => n.id == updatedNote.id);
    if (idx != -1) {
      final updated = [...current];
      updated[idx] = updatedNote;
      state = AsyncValue.data(updated);
    }
  }

  void removeNoteFromState(String noteId) {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((n) => n.id != noteId).toList());
  }

  Future<void> togglePin(String noteId, bool isPinned) async {
    await _repo.togglePin(noteId, isPinned);
    final current = state.value ?? [];
    final updated = current.map((n) {
      if (n.id == noteId) return n.copyWith(isPinned: isPinned);
      return n;
    }).toList();
    // Pinned notları üste taşı
    updated.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    state = AsyncValue.data(updated);
  }

  Future<void> moveToTrash(String noteId) async {
    await _repo.moveToTrash(noteId);
    removeNoteFromState(noteId);
  }
}

/// Arama sorgu provider'ı
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Arama sonuçları
final searchResultsProvider = FutureProvider.family<List<NoteModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(noteRepositoryProvider);
  return repo.searchNotes(query);
});

/// Aktif not provider'ı (editor için)
final activeNoteProvider = StateNotifierProvider<ActiveNoteNotifier, NoteModel?>((ref) {
  return ActiveNoteNotifier(ref.watch(noteRepositoryProvider));
});

class ActiveNoteNotifier extends StateNotifier<NoteModel?> {
  final NoteRepository _repo;

  ActiveNoteNotifier(this._repo) : super(null);

  Future<void> loadNote(String noteId) async {
    final note = await _repo.fetchNote(noteId);
    state = note;
  }

  void setNote(NoteModel note) {
    state = note;
  }

  void updateTitle(String title) {
    if (state == null) return;
    state = state!.copyWith(title: title);
  }

  void updateBlocks(List<NoteBlock> blocks) {
    if (state == null) return;
    state = state!.copyWith(
      blocks: blocks,
      contentText: blocks.map((b) => b.content).join('\n'),
    );
  }

  Future<void> save() async {
    if (state == null) return;
    await _repo.updateNote(state!);
  }

  void clear() {
    state = null;
  }
}
