<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Proxy arkasında doğru URL üretimi
        // Not: env() yerine config() kullanılıyor — config cache aktifken env() çalışmaz
        $appUrl = rtrim(config('app.url', 'http://localhost'), '/');
        \Illuminate\Support\Facades\URL::forceScheme('https');
        \Illuminate\Support\Facades\URL::forceRootUrl($appUrl);
    }
}
