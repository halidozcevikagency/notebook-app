# Notebook App - PRD (Product Requirements Document)

## Proje Vizyonu
Modern bir not alma ekosistemi: Apple Notes'un sadeliği + Notion'ın esnekliği + Google Docs'un hızı.

**Tasarım Dili:** "Zen" - Minimalist, yüksek kontrastlı, Glassmorphism dokunuşlu  
**Slogan:** "Your thoughts, beautifully organized"

---

## Mimari

### Tech Stack
- **Frontend/Mobile:** Flutter 3.42.x (flutter_riverpod state management)
- **Backend/DB:** Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Local Cache:** Hive (Offline-First)
- **AI:** OpenAI GPT-4o-mini + Emergent Universal LLM Key
- **Minimal Backend:** FastAPI (sağlık kontrolü + Supabase proxy)

### Klasör Yapısı
```
/app/notebook_app/
├── lib/
│   ├── main.dart              # Uygulama başlangıcı (Supabase init, Hive, Locale fix)
│   ├── app.dart               # MaterialApp.router (tema, routing, localizations)
│   ├── core/
│   │   ├── config/            # Supabase config, GoRouter
│   │   ├── constants/         # AppColors, AppStrings
│   │   ├── services/          # LocalCacheService (Hive), AiService (OpenAI), ExportService
│   │   ├── theme/             # Light/Dark AppTheme (Material 3)
│   │   └── utils/             # DateFormatter
│   ├── data/
│   │   ├── models/            # NoteModel, ProfileModel, WorkspaceModel, FolderModel, TagModel
│   │   └── repositories/      # AuthRepository, NoteRepository, WorkspaceRepository, TagRepository
│   ├── providers/             # app_providers, workspace_providers, tag_providers
│   ├── features/
│   │   ├── auth/              # AuthScreen (Email/Google/GitHub/Apple)
│   │   ├── dashboard/         # DashboardScreen (sidebar: notes, workspaces, tags, folders)
│   │   ├── editor/            # NoteEditorScreen (Quill editör, AI panel, tag manager, export)
│   │   ├── workspace/         # WorkspaceScreen + WorkspaceDetailScreen (drag & drop klasörler)
│   │   ├── search/            # SearchDelegate
│   │   ├── profile/           # ProfileScreen (ayarlar, tema, hesap silme)
│   │   ├── share/             # ShareNoteScreen
│   │   └── trash/             # TrashScreen
│   └── widgets/               # NoteCard, EmptyState, TagManagerWidget
├── web/
│   └── index.html             # Locale patch (Flutter web fix)
└── pubspec.yaml
```

### Supabase Şeması
- `profiles` - Kullanıcı profilleri (Auth ile entegre trigger)
- `workspaces` - Çalışma alanları (RLS: owner_id)
- `folders` - Klasörler (nested, iç içe, RLS: owner_id)
- `notes` - Notlar (JSONB blok içerik, Full-text arama)
- `note_tags`, `tags` - Etiket sistemi (RLS: owner_id)
- `note_shares` - Paylaşım linkleri (UUID token, şifreli)
- `note_invitations` - E-posta davetleri
- `note_change_requests` - Git-flow onay mekanizması
- `note_versions` - Versiyon geçmişi
- `note_attachments` - Medya dosyaları
- `ai_operations` - AI işlem geçmişi
- `premium_plans` - Ücretli paketler
- `device_tokens` - Push notification token'ları

---

## Ne Yapıldı (Tarihli)

### 2026-02-23 - İlk MVP
- [x] Flutter 3.41.2 kurulumu (ARM64 Linux)
- [x] Supabase şema (14 tablo, RLS politikaları, full-text search)
- [x] Auth ekranı (Email/Şifre + Google + GitHub + Apple OAuth UI)
- [x] Dashboard (sidebar, not listesi, pin/favori sistemi)
- [x] Note Editor (flutter_quill, 500ms debounce auto-save)
- [x] AI Panel (özetleme, yazım düzeltme, çeviri - Emergent LLM Key)
- [x] Paylaşım ekranı (UUID link, şifreli link, e-posta daveti)
- [x] Profil ve ayarlar (tema değiştirme, KVKK hesap silme)
- [x] Çöp kutusu (30 gün soft delete, geri yükleme)
- [x] Arama (SearchDelegate, full-text search via Supabase RPC)
- [x] Offline-First (Hive cache, internet yoksa cache'den yükle)
- [x] Flutter web build (locale patch, CanvasKit renderer)
- [x] Backend sağlık API (FastAPI /api/health, /api/config)
- [x] Demo user: demo@notebook.app / Demo1234!

### 2026-02-23 - Sprint 2 (Bu Oturum)
- [x] **Workspace & Klasör Yönetimi (Gelişmiş - B şıkkı)**:
  - Router'a `/workspaces` ve `/workspace/:id` rotaları eklendi
  - Dashboard sidebar'ına Workspaces bölümü + genişletilebilir klasör ağacı eklendi
  - WorkspaceScreen: emoji ikon + 12 renk seçicili workspace CRUD
  - WorkspaceDetailScreen: iki kolonlu layout (klasör paneli + notlar)
  - Klasör ağacı: iç içe alt klasörler (2 seviye)
  - **Drag & Drop** klasör sıralama (ReorderableListView)
  - Klasöre renk + emoji ikon atama
  - Alt klasör oluşturma (parent context menüsü)
- [x] **PDF Export**: ExportService ile bir tıkla PDF indirme (dart:html + pdf paketi)
- [x] **Markdown Export**: Not içeriğini `.md` dosyası olarak indirme
- [x] **Renkli Etiket (Tag) Sistemi**:
  - TagRepository: CRUD + not-etiket ilişkilendirme
  - tag_providers.dart: TagsNotifier
  - TagManagerWidget: renk seçicili etiket oluşturma/seçme
  - Not editöründe Tag butonu (AppBar) → Modal bottom sheet
  - Editörde etiket rozetleri görüntüleme
  - Dashboard sidebar'da Tags bölümü (filtreleme desteği)

---

## Kullanıcı Kişilikleri
1. **Knowledge Worker**: Notları organize etmek, araştırma yapmak
2. **Student**: Ders notları, ödev takibi
3. **Creative**: Yaratıcı yazarlık, beyin fırtınası

---

## Backlog (P0/P1/P2)

### P0 - Kritik (Sonraki Sprint)
- [ ] Supabase OAuth provider yapılandırması (Google, GitHub, Apple dashboard ayarları - kullanıcı tarafından yapılacak)
- [ ] Email confirmation bypass (production'da OTP veya magic link)
- [ ] Supabase Storage bucket oluşturma ve görsel yükleme

### P1 - Önemli
- [ ] Not versiyonlama (geçmiş görüntüleme)
- [ ] WhatsApp/Instagram hızlı paylaşım butonları
- [ ] Not kartlarında etiket görüntüleme (NoteCard'da TagBadge)
- [ ] Etiket filtreleme entegrasyonu (seçili tag ile not listesi yenileme)
- [ ] Realtime işbirliği (imleç takibi)

### P2 - Gelecek
- [ ] Admin Panel (Laravel 11 + FilamentPHP v4)
- [ ] Sesli not + Whisper STT
- [ ] OCR (belge tarama)
- [ ] Çizim modu + sticker
- [ ] Konum etiketi
- [ ] Push notification
- [ ] iOS/Android native build (App Store / Play Store)
- [ ] Isar DB migration (Hive → Isar v4 when dependencies resolve)

---

## Sonraki Adımlar
1. Supabase Dashboard > Auth > Providers'da Google/GitHub/Apple'ı etkinleştir (kullanıcı)
2. Not kartlarında etiket görüntüleme (NoteCard güncelleme)
3. Etiket filtresi ile not listesi entegrasyonu
4. Not versiyonlama
5. Admin panel (Laravel/Filament) kurulumu
