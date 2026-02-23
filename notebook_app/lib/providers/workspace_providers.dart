/// Workspace ve Klasör Riverpod Provider'ları
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/base_models.dart';
import '../data/repositories/workspace_repository.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository();
});

/// Workspace listesi
final workspacesProvider =
    StateNotifierProvider<WorkspacesNotifier, AsyncValue<List<WorkspaceModel>>>((ref) {
  return WorkspacesNotifier(ref.watch(workspaceRepositoryProvider));
});

class WorkspacesNotifier extends StateNotifier<AsyncValue<List<WorkspaceModel>>> {
  final WorkspaceRepository _repo;
  WorkspacesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final ws = await _repo.fetchWorkspaces();
      state = AsyncValue.data(ws);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<WorkspaceModel> create({required String name, String icon = '📁', String color = '#6366F1'}) async {
    final ws = await _repo.createWorkspace(name: name, icon: icon, color: color);
    final current = state.value ?? [];
    state = AsyncValue.data([...current, ws]);
    return ws;
  }

  Future<void> update({required String id, String? name, String? icon, String? color}) async {
    final ws = await _repo.updateWorkspace(id: id, name: name, icon: icon, color: color);
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((w) => w.id == id ? ws : w).toList());
  }

  Future<void> delete(String id) async {
    await _repo.deleteWorkspace(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((w) => w.id != id).toList());
  }
}

/// Seçili workspace klasörleri
final foldersProvider =
    StateNotifierProvider.family<FoldersNotifier, AsyncValue<List<FolderModel>>, String>(
  (ref, workspaceId) => FoldersNotifier(ref.watch(workspaceRepositoryProvider), workspaceId),
);

class FoldersNotifier extends StateNotifier<AsyncValue<List<FolderModel>>> {
  final WorkspaceRepository _repo;
  final String _workspaceId;

  FoldersNotifier(this._repo, this._workspaceId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final folders = await _repo.fetchFolders(_workspaceId);
      state = AsyncValue.data(folders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FolderModel> create({required String name, String? parentId, String icon = '📂'}) async {
    final f = await _repo.createFolder(workspaceId: _workspaceId, name: name, parentId: parentId, icon: icon);
    final current = state.value ?? [];
    state = AsyncValue.data([...current, f]);
    return f;
  }

  Future<void> update({required String id, String? name, String? icon}) async {
    final f = await _repo.updateFolder(id: id, name: name, icon: icon);
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((x) => x.id == id ? f : x).toList());
  }

  Future<void> delete(String id) async {
    await _repo.deleteFolder(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((x) => x.id != id).toList());
  }
}
