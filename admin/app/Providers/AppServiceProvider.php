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
        // Proxy arkasında doğru URL üretimi için
        \Illuminate\Support\Facades\URL::forceScheme('https');
        \Illuminate\Support\Facades\URL::forceRootUrl(
            rtrim(env('APP_URL', 'http://localhost'), '/')
        );
    }
}
