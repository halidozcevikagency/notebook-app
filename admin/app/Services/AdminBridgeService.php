<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

/**
 * AdminBridgeService
 * FastAPI admin bridge üzerinden Supabase verilerine erişir
 */
class AdminBridgeService
{
    private string $baseUrl;
    private string $apiKey;

    public function __construct()
    {
        // env() yerine config() kullanılıyor — config cache aktifken env() null döner
        $this->baseUrl = config('services.admin_bridge.url', 'http://localhost:8001');
        $this->apiKey  = config('services.admin_bridge.key', '');
    }

    private function headers(): array
    {
        return [
            'X-Admin-Key' => $this->apiKey,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        ];
    }

    /** Dashboard istatistikleri (1 dakika cache) */
    public function getStats(): array
    {
        return Cache::remember('admin_stats', 60, function () {
            $response = Http::withHeaders($this->headers())
                ->get("{$this->baseUrl}/api/admin/stats");
            return $response->successful() ? $response->json() : [];
        });
    }

    /** Kullanıcı listesi */
    public function getUsers(int $limit = 50, int $offset = 0, ?string $search = null): array
    {
        $params = ['limit' => $limit, 'offset' => $offset];
        if ($search) $params['search'] = $search;

        $response = Http::withHeaders($this->headers())
            ->get("{$this->baseUrl}/api/admin/users", $params);
        return $response->successful() ? $response->json() : [];
    }

    /** Not listesi */
    public function getNotes(int $limit = 50, int $offset = 0, ?string $search = null, ?string $userId = null): array
    {
        $params = ['limit' => $limit, 'offset' => $offset];
        if ($search) $params['search'] = $search;
        if ($userId) $params['user_id'] = $userId;

        $response = Http::withHeaders($this->headers())
            ->get("{$this->baseUrl}/api/admin/notes", $params);
        return $response->successful() ? $response->json() : [];
    }

    /** Büyüme istatistikleri */
    public function getGrowth(int $days = 14): array
    {
        return Cache::remember("admin_growth_{$days}", 300, function () use ($days) {
            $response = Http::withHeaders($this->headers())
                ->get("{$this->baseUrl}/api/admin/growth", ['days' => $days]);
            return $response->successful() ? $response->json() : [];
        });
    }

    /** Notu arşivle */
    public function archiveNote(string $noteId): bool
    {
        $response = Http::withHeaders($this->headers())
            ->post("{$this->baseUrl}/api/admin/notes/{$noteId}/archive");
        return $response->successful();
    }

    /** Notu geri yükle */
    public function restoreNote(string $noteId): bool
    {
        $response = Http::withHeaders($this->headers())
            ->post("{$this->baseUrl}/api/admin/notes/{$noteId}/restore");
        return $response->successful();
    }
}
