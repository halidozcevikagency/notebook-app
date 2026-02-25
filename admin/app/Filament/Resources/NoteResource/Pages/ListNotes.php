<?php

namespace App\Filament\Resources\NoteResource\Pages;

use App\Filament\Resources\NoteResource;
use App\Models\ApiRecord;
use App\Services\AdminBridgeService;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;

class ListNotes extends ListRecords
{
    protected static string $resource = NoteResource::class;

    protected function getHeaderActions(): array { return []; }

    public function getTableRecords(): EloquentCollection|\Illuminate\Contracts\Pagination\Paginator|\Illuminate\Contracts\Pagination\CursorPaginator
    {
        $bridge = new AdminBridgeService();
        $notes  = $bridge->getNotes(limit: 100);
        // Fluent yerine ApiRecord — Filament getRecordAction() Eloquent Model bekler
        $items  = collect($notes)->map(fn ($n) => ApiRecord::fromArray((array) $n));
        return EloquentCollection::make($items);
    }
}
