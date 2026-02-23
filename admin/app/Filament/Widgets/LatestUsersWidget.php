<?php

namespace App\Filament\Widgets;

use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\BadgeColumn;
use Illuminate\Support\Collection;
use App\Services\AdminBridgeService;

/**
 * LatestUsersWidget
 * Son kayıt olan 8 kullanıcı
 */
class LatestUsersWidget extends BaseWidget
{
    protected static ?string $heading = 'Latest Registered Users';
    protected static ?int $sort = 3;
    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => collect([]))
            ->records(fn () => $this->getRecords())
            ->columns([
                TextColumn::make('full_name')
                    ->label('Name')
                    ->searchable(false)
                    ->sortable(false),
                TextColumn::make('email')
                    ->label('Email')
                    ->searchable(false),
                TextColumn::make('note_count')
                    ->label('Notes')
                    ->badge()
                    ->color('info'),
                TextColumn::make('created_at')
                    ->label('Joined')
                    ->since()
                    ->sortable(false),
            ]);
    }

    protected function getRecords(): Collection
    {
        $bridge = new AdminBridgeService();
        $users = $bridge->getUsers(limit: 8);
        return collect($users)->map(fn ($u) => (object) $u);
    }
}
