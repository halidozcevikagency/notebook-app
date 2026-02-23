# Notebook App - PRD (Product Requirements Document)

## Proje Vizyonu
Modern bir not alma ekosistemi: Apple Notes'un sadeliği + Notion'ın esnekliği + Google Docs'un hızı.

**Tasarım Dili:** "Zen" - Minimalist, yüksek kontrastlı, Glassmorphism dokunuşlu  
**Slogan:** "Your thoughts, beautifully organized"

---

## Mimari

### Tech Stack
- **Frontend/Mobile:** Flutter 3.41.2 (flutter_riverpod state management)
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
│   │   ├── services/          # LocalCacheService (Hive), AiService (OpenAI)
│   │   ├── theme/             # Light/Dark AppTheme (Material 3)
│   │   └── utils/             # DateFormatter
│   ├── data/
│   │   ├── models/            # NoteModel, ProfileModel, WorkspaceModel, etc.
│   │   └── repositories/      # AuthRepository, NoteRepository
│   ├── providers/             # Riverpod providers (auth, notes, theme)
│   ├── features/
│   │   ├── auth/              # AuthScreen (Email/Google/GitHub/Apple)
│   │   ├── dashboard/         # DashboardScreen (sidebar, not listesi)
│   │   ├── editor/            # NoteEditorScreen (Quill editör, AI panel)
│   │   ├── search/            # SearchDelegate
│   │   ├── profile/           # ProfileScreen (ayarlar, tema, hesap silme)
│   │   ├── share/             # ShareNoteScreen
│   │   └── trash/             # TrashScreen
│   └── widgets/               # NoteCard, EmptyState
├── web/
│   └── index.html             # Locale patch (Flutter web fix)
└── pubspec.yaml
```

### Supabase Şeması
- `profiles` - Kullanıcı profilleri (Auth ile entegre trigger)
- `workspaces` - Çalışma alanları
- `folders` - Klasörler (nested, iç içe)
- `notes` - Notlar (JSONB blok içerik, Full-text arama)
- `note_tags`, `tags` - Etiket sistemi
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

---

## Kullanıcı Kişilikleri
1. **Knowledge Worker**: Notları organize etmek, araştırma yapmak
2. **Student**: Ders notları, ödev takibi
3. **Creative**: Yaratıcı yazarlık, beyin fırtınası

---

## Backlog (P0/P1/P2)

### P0 - Kritik (Sonraki Sprint)
- [ ] Supabase OAuth provider yapılandırması (Google, GitHub, Apple dashboard ayarları)
- [ ] Email confirmation bypass (production'da OTP veya magic link)
- [ ] Flutter web build otomasyonu (her kod değişikliğinde auto-rebuild)
- [ ] Supabase Storage bucket oluşturma ve görsel yükleme

### P1 - Önemli
- [ ] Workspace ve klasör yönetimi UI
- [ ] Renkli etiket (Tag) sistemi UI
- [ ] Not versiyonlama (geçmiş görüntüleme)
- [ ] PDF/Markdown export
- [ ] WhatsApp/Instagram hızlı paylaşım
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
1. Supabase Dashboard > Auth > Providers'da Google/GitHub/Apple'ı etkinleştir
2. `flutter build web` otomasyonu için supervisor'a build hook ekle
3. Workspace UI'sını tamamla
4. Admin panel (Laravel/Filament) kurulumu
