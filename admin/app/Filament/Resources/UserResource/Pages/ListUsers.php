<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Models\ApiRecord;
use App\Services\AdminBridgeService;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;

class ListUsers extends ListRecords
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array { return []; }

    public function getTableRecords(): EloquentCollection|\Illuminate\Contracts\Pagination\Paginator|\Illuminate\Contracts\Pagination\CursorPaginator
    {
        $bridge = new AdminBridgeService();
        $users  = $bridge->getUsers(limit: 100);
        // Fluent yerine ApiRecord — Filament getRecordAction() Eloquent Model bekler
        $items  = collect($users)->map(fn ($u) => ApiRecord::fromArray((array) $u));
        return EloquentCollection::make($items);
    }
}
