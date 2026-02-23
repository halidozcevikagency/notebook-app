<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
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
        // stdClass nesnelerini Fluent ile sar — data_get() bununla çalışır
        $items  = collect($users)->map(fn ($u) => new \Illuminate\Support\Fluent((array) $u));
        return EloquentCollection::make($items);
    }
}
