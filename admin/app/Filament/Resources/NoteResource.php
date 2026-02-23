<?php

namespace App\Filament\Resources;

use App\Filament\Resources\NoteResource\Pages;
use App\Services\AdminBridgeService;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Actions\Action;
use Filament\Tables\Filters\SelectFilter;
use Filament\Notifications\Notification;
use Illuminate\Support\Collection;

/**
 * NoteResource
 * Tüm notları listele + moderasyon (arşivle/geri yükle)
 */
class NoteResource extends Resource
{
    protected static ?string $model = \App\Models\User::class;
    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    protected static ?string $navigationLabel = 'Notes';
    protected static ?string $navigationGroup = 'App Management';
    protected static ?string $modelLabel = 'Note';
    protected static ?string $pluralModelLabel = 'Notes';
    protected static ?int $navigationSort = 2;

    public static function getNavigationBadge(): ?string
    {
        $bridge = new AdminBridgeService();
        $stats = $bridge->getStats();
        return (string) ($stats['total_notes'] ?? '');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->query(fn () => \App\Models\User::query()->whereRaw('1=0'))
            ->records(fn ($table) => self::getRecords())
            ->columns([
                TextColumn::make('title')
                    ->label('Title')
                    ->limit(45)
                    ->weight('semibold')
                    ->searchable(false),

                TextColumn::make('owner_name')
                    ->label('Owner')
                    ->searchable(false),

                TextColumn::make('owner_email')
                    ->label('Email')
                    ->icon('heroicon-m-envelope')
                    ->searchable(false)
                    ->toggleable(isToggledHiddenByDefault: true),

                IconColumn::make('is_pinned')
                    ->label('Pinned')
                    ->boolean()
                    ->trueIcon('heroicon-s-map-pin')
                    ->falseIcon('heroicon-o-map-pin'),

                IconColumn::make('is_archived')
                    ->label('Archived')
                    ->boolean()
                    ->trueColor('danger')
                    ->falseColor('success'),

                TextColumn::make('deleted_at')
                    ->label('Deleted')
                    ->placeholder('Active')
                    ->since()
                    ->color('danger'),

                TextColumn::make('updated_at')
                    ->label('Updated')
                    ->since()
                    ->sortable(false),
            ])
            ->actions([
                Action::make('archive')
                    ->label('Archive')
                    ->icon('heroicon-o-archive-box')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->visible(fn ($record) => !$record->is_archived)
                    ->action(function ($record) {
                        $bridge = new AdminBridgeService();
                        if ($bridge->archiveNote($record->id)) {
                            Notification::make()
                                ->title('Note archived')
                                ->success()
                                ->send();
                        }
                    }),

                Action::make('restore')
                    ->label('Restore')
                    ->icon('heroicon-o-arrow-path')
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn ($record) => $record->is_archived || $record->deleted_at !== null)
                    ->action(function ($record) {
                        $bridge = new AdminBridgeService();
                        if ($bridge->restoreNote($record->id)) {
                            Notification::make()
                                ->title('Note restored')
                                ->success()
                                ->send();
                        }
                    }),
            ])
            ->defaultSort('updated_at', 'desc')
            ->searchable(false)
            ->paginated(false)
            ->striped();
    }

    private static function getRecords(): Collection
    {
        $bridge = new AdminBridgeService();
        $notes = $bridge->getNotes(limit: 50);
        return collect($notes)->map(fn ($n) => (object) $n);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListNotes::route('/'),
        ];
    }
}
