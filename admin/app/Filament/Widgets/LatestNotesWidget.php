<?php

namespace App\Filament\Widgets;

use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\IconColumn;
use Illuminate\Support\Collection;
use App\Services\AdminBridgeService;

/**
 * LatestNotesWidget  
 * Son oluşturulan 8 not
 */
class LatestNotesWidget extends BaseWidget
{
    protected static ?string $heading = 'Recent Notes';
    protected static ?int $sort = 4;
    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => collect([]))
            ->records(fn () => $this->getRecords())
            ->columns([
                TextColumn::make('title')
                    ->label('Title')
                    ->limit(40),
                TextColumn::make('owner_email')
                    ->label('Owner'),
                TextColumn::make('owner_name')
                    ->label('Name'),
                IconColumn::make('is_pinned')
                    ->label('Pinned')
                    ->boolean(),
                TextColumn::make('updated_at')
                    ->label('Updated')
                    ->since(),
            ]);
    }

    protected function getRecords(): Collection
    {
        $bridge = new AdminBridgeService();
        $notes = $bridge->getNotes(limit: 8);
        return collect($notes)->map(fn ($n) => (object) $n);
    }
}
