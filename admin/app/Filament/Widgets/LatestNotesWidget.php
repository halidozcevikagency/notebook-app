<?php

namespace App\Filament\Widgets;

use App\Models\ApiRecord;
use App\Services\AdminBridgeService;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\IconColumn;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;

/**
 * LatestNotesWidget — Son oluşturulan 8 notu gösterir
 */
class LatestNotesWidget extends BaseWidget
{
    protected static ?string $heading = 'Recent Notes';
    protected static ?int    $sort    = 4;
    protected int|string|array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => \App\Models\User::query()->whereRaw('1=0'))
            ->columns([
                TextColumn::make('title')->label('Title')->limit(40),
                TextColumn::make('owner_email')->label('Owner'),
                TextColumn::make('owner_name')->label('Name'),
                IconColumn::make('is_pinned')->label('Pinned')->boolean(),
                TextColumn::make('updated_at')->label('Updated')->since(),
            ]);
    }

    public function getTableRecords(): EloquentCollection|\Illuminate\Contracts\Pagination\Paginator|\Illuminate\Contracts\Pagination\CursorPaginator
    {
        $bridge = new AdminBridgeService();
        $notes  = $bridge->getNotes(limit: 8);
        return EloquentCollection::make(
            collect($notes)->map(fn ($n) => ApiRecord::fromArray((array) $n))
        );
    }
}
