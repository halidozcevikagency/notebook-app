<?php

namespace App\Filament\Resources\NoteResource\Pages;

use App\Filament\Resources\NoteResource;
use App\Services\AdminBridgeService;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Support\Collection;

class ListNotes extends ListRecords
{
    protected static string $resource = NoteResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }

    /**
     * Supabase notlarını Admin Bridge üzerinden getirir.
     */
    public function getTableRecords(): Collection|\Illuminate\Contracts\Pagination\Paginator|\Illuminate\Contracts\Pagination\CursorPaginator
    {
        $bridge = new AdminBridgeService();
        $notes = $bridge->getNotes(limit: 100);
        return collect($notes)->map(fn ($n) => (object) $n);
    }
}
