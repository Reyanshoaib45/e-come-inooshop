<?php

namespace App\Providers;

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Schema::defaultStringLength(191);

        // FORCE HTTPS ALWAYS (fix mixed content)
        if (app()->environment('production')) {
            URL::forceScheme('https');
        }

        // AI providers (your logic is fine, leave it)
        if (class_exists(\Laravel\Ai\AiManager::class)) {
            \Laravel\Ai\Ai::extend('glm', function ($app, array $config) {
                $config['driver'] = 'deepseek';
                return new \Laravel\Ai\Providers\DeepSeekProvider(
                    new \Laravel\Ai\Gateway\Prism\PrismGateway($app['events']),
                    $config,
                    $app->make(\Illuminate\Contracts\Events\Dispatcher::class)
                );
            });

            \Laravel\Ai\Ai::extend('minimax', function ($app, array $config) {
                $config['driver'] = 'deepseek';
                return new \Laravel\Ai\Providers\DeepSeekProvider(
                    new \Laravel\Ai\Gateway\Prism\PrismGateway($app['events']),
                    $config,
                    $app->make(\Illuminate\Contracts\Events\Dispatcher::class)
                );
            });
        }
    }
}