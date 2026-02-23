<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Services\AdminBridgeService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Actions\Action;
use Filament\Notifications\Notification;
use Illuminate\Support\Collection;

/**
 * UserResource
 * Supabase kullanıcı yönetimi (okuma + not filtreleme)
 */
class UserResource extends Resource
{
    protected static ?string $model = \App\Models\User::class;
    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?string $navigationLabel = 'Users';
    protected static ?string $navigationGroup = 'App Management';
    protected static ?int $navigationSort = 1;

    public static function getNavigationBadge(): ?string
    {
        $bridge = new AdminBridgeService();
        $stats = $bridge->getStats();
        return (string) ($stats['total_users'] ?? '');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function table(Table $table): Table
    {
        $bridge = new AdminBridgeService();

        return $table
            ->query(fn () => \App\Models\User::query()->whereRaw('1=0'))
            ->records(fn ($table) => self::getRecords($table))
            ->columns([
                TextColumn::make('full_name')
                    ->label('Full Name')
                    ->searchable(false)
                    ->sortable(false)
                    ->weight('semibold'),

                TextColumn::make('email')
                    ->label('Email')
                    ->searchable(false)
                    ->icon('heroicon-m-envelope')
                    ->copyable(),

                TextColumn::make('username')
                    ->label('Username')
                    ->placeholder('—'),

                TextColumn::make('note_count')
                    ->label('Notes')
                    ->badge()
                    ->color(fn ($state) => $state > 0 ? 'success' : 'gray'),

                TextColumn::make('is_premium')
                    ->label('Premium')
                    ->badge()
                    ->formatStateUsing(fn ($state) => $state ? 'Premium' : 'Free')
                    ->color(fn ($state) => $state ? 'warning' : 'gray'),

                TextColumn::make('subscription_status')
                    ->label('Subscription')
                    ->badge()
                    ->placeholder('—')
                    ->color(fn ($state) => match($state) {
                        'active'       => 'success',
                        'trial'        => 'info',
                        'grace_period' => 'warning',
                        'expired'      => 'danger',
                        'cancelled'    => 'gray',
                        default        => 'gray',
                    }),

                TextColumn::make('subscription_platform')
                    ->label('IAP Platform')
                    ->placeholder('—')
                    ->badge()
                    ->color(fn ($state) => match($state) {
                        'ios'     => 'info',
                        'android' => 'success',
                        'web'     => 'primary',
                        default   => 'gray',
                    })
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('subscription_expires_at')
                    ->label('Expires')
                    ->placeholder('—')
                    ->since()
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('created_at')
                    ->label('Joined')
                    ->since()
                    ->sortable(false),
            ])
            ->defaultSort('created_at', 'desc')
            ->searchable(false)
            ->paginated(false)
            ->striped();
    }

    private static function getRecords($table): Collection
    {
        $bridge = new AdminBridgeService();
        $users = $bridge->getUsers(limit: 50);
        return collect($users)->map(fn ($u) => (object) $u);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
        ];
    }
}
