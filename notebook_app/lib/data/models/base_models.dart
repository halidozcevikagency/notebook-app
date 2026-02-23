/// Uygulama genelinde kullanılan veri modelleri
/// Supabase'den gelen JSON verilerini Dart objelerine dönüştürür

/// Kullanıcı profil modeli
class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool isPremium;
  final String locale;
  final String theme;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.isPremium = false,
    this.locale = 'en',
    this.theme = 'system',
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      locale: json['locale'] as String? ?? 'en',
      theme: json['theme'] as String? ?? 'system',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'is_premium': isPremium,
        'locale': locale,
        'theme': theme,
      };

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    bool? isPremium,
    String? locale,
    String? theme,
  }) {
    return ProfileModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
      locale: locale ?? this.locale,
      theme: theme ?? this.theme,
      createdAt: createdAt,
    );
  }
}

/// Çalışma alanı modeli
class WorkspaceModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkspaceModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.icon = '📁',
    this.color = '#6366F1',
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? '📁',
      color: json['color'] as String? ?? '#6366F1',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'is_default': isDefault,
      };
}

/// Klasör modeli
class FolderModel {
  final String id;
  final String workspaceId;
  final String? parentId;
  final String ownerId;
  final String name;
  final String icon;
  final String color;
  final int position;
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.workspaceId,
    this.parentId,
    required this.ownerId,
    required this.name,
    this.icon = '📂',
    this.color = '#6366F1',
    this.position = 0,
    required this.createdAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      parentId: json['parent_id'] as String?,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '📂',
      color: json['color'] as String? ?? '#6366F1',
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'workspace_id': workspaceId,
        'parent_id': parentId,
        'owner_id': ownerId,
        'name': name,
        'icon': icon,
        'color': color,
        'position': position,
      };

  FolderModel copyWith({String? name, String? icon, String? color, int? position}) {
    return FolderModel(
      id: id,
      workspaceId: workspaceId,
      parentId: parentId,
      ownerId: ownerId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      position: position ?? this.position,
      createdAt: createdAt,
    );
  }
}

/// Etiket modeli
class TagModel {
  final String id;
  final String ownerId;
  final String? workspaceId;
  final String name;
  final String color;
  final DateTime createdAt;

  const TagModel({
    required this.id,
    required this.ownerId,
    this.workspaceId,
    required this.name,
    this.color = '#6366F1',
    required this.createdAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      workspaceId: json['workspace_id'] as String?,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6366F1',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'workspace_id': workspaceId,
        'name': name,
        'color': color,
      };
}
