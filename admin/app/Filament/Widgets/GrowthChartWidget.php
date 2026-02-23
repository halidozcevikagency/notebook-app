<?php

namespace App\Filament\Widgets;

use Filament\Widgets\ChartWidget;
use App\Services\AdminBridgeService;

/**
 * GrowthChartWidget
 * 14 günlük kullanıcı ve not büyüme grafiği
 */
class GrowthChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Growth (14 days)';
    protected static ?int $sort = 2;
    protected int | string | array $columnSpan = 'full';

    protected function getData(): array
    {
        $bridge = new AdminBridgeService();
        $growth = $bridge->getGrowth(14);

        $labels   = [];
        $users    = [];
        $notes    = [];

        foreach ($growth as $row) {
            $labels[] = date('d M', strtotime($row['stat_date']));
            $users[]  = (int) ($row['new_users'] ?? 0);
            $notes[]  = (int) ($row['new_notes'] ?? 0);
        }

        return [
            'datasets' => [
                [
                    'label'                => 'New Users',
                    'data'                 => $users,
                    'backgroundColor'      => 'rgba(99, 102, 241, 0.2)',
                    'borderColor'          => 'rgba(99, 102, 241, 1)',
                    'borderWidth'          => 2,
                    'tension'              => 0.4,
                    'fill'                 => true,
                ],
                [
                    'label'                => 'New Notes',
                    'data'                 => $notes,
                    'backgroundColor'      => 'rgba(16, 185, 129, 0.2)',
                    'borderColor'          => 'rgba(16, 185, 129, 1)',
                    'borderWidth'          => 2,
                    'tension'              => 0.4,
                    'fill'                 => true,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
