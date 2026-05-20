<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

class ClarificationContextService
{
    private const CACHE_PREFIX = 'ai_clarification_context';
    private const DEFAULT_TTL_MINUTES = 10;

    public function save(int|string $userId, array $context, ?int $ttlMinutes = null): void
    {
        $ttl = $ttlMinutes ?? self::DEFAULT_TTL_MINUTES;

        Cache::put(
            $this->cacheKey($userId),
            array_merge($context, [
                'expires_at' => now()->addMinutes($ttl)->toISOString(),
            ]),
            now()->addMinutes($ttl),
        );
    }

    public function retrieve(int|string $userId): ?array
    {
        $context = Cache::get($this->cacheKey($userId));

        return is_array($context) ? $context : null;
    }

    public function clear(int|string $userId): void
    {
        Cache::forget($this->cacheKey($userId));
    }

    private function cacheKey(int|string $userId): string
    {
        return self::CACHE_PREFIX . ':' . $userId;
    }
}
