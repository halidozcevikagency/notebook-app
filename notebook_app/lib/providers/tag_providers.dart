/// Etiket Riverpod Provider'ları
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/base_models.dart';
import '../data/repositories/tag_repository.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) => TagRepository());

/// Tüm etiketler
final tagsProvider = StateNotifierProvider<TagsNotifier, AsyncValue<List<TagModel>>>((ref) {
  return TagsNotifier(ref.watch(tagRepositoryProvider));
});

class TagsNotifier extends StateNotifier<AsyncValue<List<TagModel>>> {
  final TagRepository _repo;
  TagsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.fetchTags());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TagModel> create({required String name, String color = '#6366F1'}) async {
    final tag = await _repo.createTag(name: name, color: color);
    final current = state.value ?? [];
    state = AsyncValue.data([...current, tag]..sort((a, b) => a.name.compareTo(b.name)));
    return tag;
  }

  Future<void> update({required String id, String? name, String? color}) async {
    final tag = await _repo.updateTag(id: id, name: name, color: color);
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((t) => t.id == id ? tag : t).toList());
  }

  Future<void> delete(String id) async {
    await _repo.deleteTag(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((t) => t.id != id).toList());
  }
}

/// Belirli bir notun etiketlerini getirir
final noteTagsProvider = FutureProvider.family<List<String>, String>((ref, noteId) async {
  return ref.watch(tagRepositoryProvider).fetchNoteTagIds(noteId);
});

/// Tüm kullanıcı not-etiket ilişkileri tek sorguda (badge gösterimi için)
/// Map<noteId, List<tagId>>
final allNoteTagsMapProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  return ref.watch(tagRepositoryProvider).fetchAllNoteTagsMap();
});

/// Seçili etiket filtresi (dashboard filtreleme için)
final selectedTagFilterProvider = StateProvider<String?>((ref) => null);
