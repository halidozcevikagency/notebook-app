/// Workspace ve Klasör repository'si
/// CRUD işlemleri, hiyerarşik klasör yapısı
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_models.dart';

class WorkspaceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  // ─── WORKSPACE ────────────────────────────────────────────────────────────

  /// Tüm workspace'leri yükle
  Future<List<WorkspaceModel>> fetchWorkspaces() async {
    final data = await _supabase
        .from('workspaces')
        .select()
        .eq('owner_id', _userId)
        .order('is_default', ascending: false)
        .order('created_at');

    return (data as List).map((j) => WorkspaceModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Yeni workspace oluştur
  Future<WorkspaceModel> createWorkspace({
    required String name,
    String icon = '📁',
    String color = '#6366F1',
  }) async {
    final data = await _supabase.from('workspaces').insert({
      'owner_id': _userId,
      'name': name,
      'icon': icon,
      'color': color,
    }).select().single();

    return WorkspaceModel.fromJson(data);
  }

  /// Workspace güncelle
  Future<WorkspaceModel> updateWorkspace({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;

    final data = await _supabase
        .from('workspaces')
        .update(updates)
        .eq('id', id)
        .eq('owner_id', _userId)
        .select()
        .single();

    return WorkspaceModel.fromJson(data);
  }

  /// Workspace sil
  Future<void> deleteWorkspace(String id) async {
    await _supabase
        .from('workspaces')
        .delete()
        .eq('id', id)
        .eq('owner_id', _userId);
  }

  // ─── FOLDER ───────────────────────────────────────────────────────────────

  /// Workspace'e ait klasörleri yükle
  Future<List<FolderModel>> fetchFolders(String workspaceId) async {
    final data = await _supabase
        .from('folders')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('owner_id', _userId)
        .order('position')
        .order('created_at');

    return (data as List).map((j) => FolderModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Yeni klasör oluştur
  Future<FolderModel> createFolder({
    required String workspaceId,
    required String name,
    String? parentId,
    String icon = '📂',
    String color = '#6366F1',
  }) async {
    final data = await _supabase.from('folders').insert({
      'workspace_id': workspaceId,
      'owner_id': _userId,
      'name': name,
      'parent_id': parentId,
      'icon': icon,
      'color': color,
    }).select().single();

    return FolderModel.fromJson(data);
  }

  /// Klasör güncelle
  Future<FolderModel> updateFolder({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;

    final data = await _supabase
        .from('folders')
        .update(updates)
        .eq('id', id)
        .eq('owner_id', _userId)
        .select()
        .single();

    return FolderModel.fromJson(data);
  }

  /// Klasör sil
  Future<void> deleteFolder(String id) async {
    await _supabase
        .from('folders')
        .delete()
        .eq('id', id)
        .eq('owner_id', _userId);
  }
}
