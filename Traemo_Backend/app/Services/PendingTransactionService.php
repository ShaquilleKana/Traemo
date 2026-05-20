<?php

namespace App\Services;

use App\Enums\AIResponseStatus;
use App\Enums\TransactionFlowStatus;
use App\Models\TransactionCategory;
use Illuminate\Support\Facades\Cache;

class PendingTransactionService
{
    private const CACHE_PREFIX = 'pending_transaction';
    private const DEFAULT_TTL_MINUTES = 10;

    public function saveConfirmation(int|string $userId, array $parsedData, ?int $ttlMinutes = null): array
    {
        $payload = [
            'status' => TransactionFlowStatus::PendingConfirmation->value,
            'ai_status' => AIResponseStatus::Success->value,
            'transactions' => collect($parsedData['transactions'] ?? [])
                ->map(fn (array $transaction): array => [
                    'description' => trim((string) ($transaction['description'] ?? '')),
                    'amount' => (int) ($transaction['amount'] ?? 0),
                    'transaction_category_id' => $transaction['transaction_category_id'] ?? null,
                    'category' => $transaction['category'] ?? null,
                    'confidence_score' => (float) ($transaction['confidence_score'] ?? 0),
                ])
                ->values()
                ->all(),
        ];

        Cache::put(
            $this->cacheKey($userId),
            $payload,
            now()->addMinutes($ttlMinutes ?? self::DEFAULT_TTL_MINUTES),
        );

        return $payload;
    }

    public function retrieve(int|string $userId): ?array
    {
        $pending = Cache::get($this->cacheKey($userId));

        return is_array($pending) ? $pending : null;
    }

    public function clear(int|string $userId): void
    {
        Cache::forget($this->cacheKey($userId));
    }

    public function isValidForSave(?array $pending): bool
    {
        if (!is_array($pending)) {
            return false;
        }

        if (
            ($pending['status'] ?? null) !== TransactionFlowStatus::PendingConfirmation->value
            || ($pending['ai_status'] ?? null) !== AIResponseStatus::Success->value
            || empty($pending['transactions'])
            || !is_array($pending['transactions'])
        ) {
            return false;
        }

        foreach ($pending['transactions'] as $transaction) {
            $categoryId = $transaction['transaction_category_id'] ?? null;

            if (
                !is_array($transaction)
                || !is_numeric($transaction['amount'] ?? null)
                || (int) $transaction['amount'] <= 0
                || trim((string) ($transaction['description'] ?? '')) === ''
                || $categoryId === null
                || !TransactionCategory::query()->whereKey($categoryId)->exists()
            ) {
                return false;
            }
        }

        return true;
    }

    public function cacheKey(int|string $userId): string
    {
        return self::CACHE_PREFIX . '_' . $userId;
    }
}
