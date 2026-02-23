<?php

namespace App\Filament\Widgets;

use App\Services\AdminBridgeService;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;

/**
 * LatestUsersWidget — Son kayıt olan 8 kullanıcıyı gösterir
 */
class LatestUsersWidget extends BaseWidget
{
    protected static ?string $heading = 'Latest Registered Users';
    protected static ?int    $sort    = 3;
    protected int|string|array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => \App\Models\User::query()->whereRaw('1=0'))
            ->columns([
                TextColumn::make('full_name')->label('Name'),
                TextColumn::make('email')->label('Email'),
                TextColumn::make('note_count')->label('Notes')->badge()->color('info'),
                TextColumn::make('created_at')->label('Joined')->since(),
            ]);
    }

    public function getTableRecords(): EloquentCollection|\Illuminate\Contracts\Pagination\Paginator|\Illuminate\Contracts\Pagination\CursorPaginator
    {
        $bridge = new AdminBridgeService();
        $users  = $bridge->getUsers(limit: 8);
        return EloquentCollection::make(
            collect($users)->map(fn ($u) => new \Illuminate\Support\Fluent((array) $u))
        );
    }
}
