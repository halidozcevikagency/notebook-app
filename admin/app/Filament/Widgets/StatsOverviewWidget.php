<?php

namespace App\Filament\Widgets;

use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use App\Services\AdminBridgeService;

/**
 * StatsOverviewWidget
 * Dashboard üstteki 4 istatistik kartı
 */
class StatsOverviewWidget extends BaseWidget
{
    protected static ?int $sort = 1;
    protected static ?string $pollingInterval = '60s';

    protected function getStats(): array
    {
        $bridge = new AdminBridgeService();
        $stats = $bridge->getStats();

        $totalUsers     = $stats['total_users'] ?? 0;
        $totalNotes     = $stats['total_notes'] ?? 0;
        $activeNotes    = $stats['active_notes'] ?? 0;
        $newUsersToday  = $stats['new_users_today'] ?? 0;
        $newNotesToday  = $stats['new_notes_today'] ?? 0;
        $workspaces     = $stats['total_workspaces'] ?? 0;
        $tags           = $stats['total_tags'] ?? 0;
        $deletedNotes   = $stats['deleted_notes'] ?? 0;

        return [
            Stat::make('Total Users', number_format($totalUsers))
                ->description("+{$newUsersToday} today")
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success')
                ->icon('heroicon-o-users'),

            Stat::make('Active Notes', number_format($activeNotes))
                ->description("+{$newNotesToday} new today")
                ->descriptionIcon('heroicon-m-document-text')
                ->color('info')
                ->icon('heroicon-o-document-text'),

            Stat::make('Workspaces', number_format($workspaces))
                ->description('Across all users')
                ->color('warning')
                ->icon('heroicon-o-folder'),

            Stat::make('Trash Items', number_format($deletedNotes))
                ->description("Tags: {$tags} total")
                ->color('danger')
                ->icon('heroicon-o-trash'),
        ];
    }
}
