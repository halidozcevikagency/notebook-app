/// Not veri modeli
/// Blok tabanlı içeriği JSONB formatında saklar
import 'dart:convert';

/// Not bloğunun türleri
enum BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  todo,
  quote,
  code,
  image,
  divider,
  table,
}

/// Not bloğu modeli (Notion benzeri blok yapısı)
class NoteBlock {
  final String id;
  final BlockType type;
  final String content;
  final Map<String, dynamic> attributes;
  final bool? isChecked; // Todo blokları için

  const NoteBlock({
    required this.id,
    required this.type,
    required this.content,
    this.attributes = const {},
    this.isChecked,
  });

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      id: json['id'] as String,
      type: BlockType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => BlockType.paragraph,
      ),
      content: json['content'] as String? ?? '',
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      isChecked: json['is_checked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'attributes': attributes,
        'is_checked': isChecked,
      };

  NoteBlock copyWith({
    String? content,
    BlockType? type,
    Map<String, dynamic>? attributes,
    bool? isChecked,
  }) {
    return NoteBlock(
      id: id,
      type: type ?? this.type,
      content: content ?? this.content,
      attributes: attributes ?? this.attributes,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

/// Not ana modeli
class NoteModel {
  final String id;
  final String ownerId;
  final String? workspaceId;
  final String? folderId;
  final String title;
  final List<NoteBlock> blocks;
  final String? contentText; // Full-text arama için
  final String? coverImageUrl;
  final String? icon;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final DateTime? deletedAt;
  final int wordCount;
  final String? locationName;
  final double? locationLat;
  final double? locationLng;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tagIds;

  const NoteModel({
    required this.id,
    required this.ownerId,
    this.workspaceId,
    this.folderId,
    this.title = 'Untitled',
    this.blocks = const [],
    this.contentText,
    this.coverImageUrl,
    this.icon,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.deletedAt,
    this.wordCount = 0,
    this.locationName,
    this.locationLat,
    this.locationLng,
    required this.createdAt,
    required this.updatedAt,
    this.tagIds = const [],
  });

  bool get isDeleted => deletedAt != null;

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    List<NoteBlock> parseBlocks(dynamic content) {
      if (content == null) return [];
      if (content is String) {
        try {
          final parsed = jsonDecode(content) as List;
          return parsed
              .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
              .toList();
        } catch (_) {
          return [];
        }
      }
      if (content is List) {
        return content
            .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return NoteModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      workspaceId: json['workspace_id'] as String?,
      folderId: json['folder_id'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      blocks: parseBlocks(json['content']),
      contentText: json['content_text'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      icon: json['icon'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      wordCount: json['word_count'] as int? ?? 0,
      locationName: json['location_name'] as String?,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tagIds: (json['tag_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'workspace_id': workspaceId,
        'folder_id': folderId,
        'title': title,
        'content': blocks.map((b) => b.toJson()).toList(),
        'content_text': contentText,
        'cover_image_url': coverImageUrl,
        'icon': icon,
        'is_pinned': isPinned,
        'is_archived': isArchived,
        'is_favorite': isFavorite,
        'word_count': wordCount,
        'location_name': locationName,
        'location_lat': locationLat,
        'location_lng': locationLng,
      };

  NoteModel copyWith({
    String? title,
    List<NoteBlock>? blocks,
    String? contentText,
    String? coverImageUrl,
    String? icon,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    DateTime? deletedAt,
    String? workspaceId,
    String? folderId,
  }) {
    return NoteModel(
      id: id,
      ownerId: ownerId,
      workspaceId: workspaceId ?? this.workspaceId,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      contentText: contentText ?? this.contentText,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      icon: icon ?? this.icon,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      deletedAt: deletedAt ?? this.deletedAt,
      wordCount: wordCount,
      locationName: locationName,
      locationLat: locationLat,
      locationLng: locationLng,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tagIds: tagIds,
    );
  }

  /// Not içeriğinden düz metin oluşturur
  String get plainText {
    return blocks.map((b) => b.content).join('\n');
  }
}
