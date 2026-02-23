<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Services\AdminBridgeService;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Support\Collection;

class ListUsers extends ListRecords
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }

    /**
     * Supabase kullanıcılarını Admin Bridge üzerinden getirir.
     * Filament'ın Eloquent tablosunu bypass eder.
     */
    public function getTableRecords(): Collection|\Illuminate\Contracts\Pagination\Paginator|\Illuminate\Contracts\Pagination\CursorPaginator
    {
        $bridge = new AdminBridgeService();
        $users = $bridge->getUsers(limit: 100);
        return collect($users)->map(fn ($u) => (object) $u);
    }
}
