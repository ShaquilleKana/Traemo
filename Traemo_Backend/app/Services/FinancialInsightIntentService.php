<?php

namespace App\Services;

class FinancialInsightIntentService
{
    public const TOP_EXPENSE_CATEGORY = 'top_expense_category';
    public const MONTHLY_EXPENSE_SUMMARY = 'monthly_expense_summary';
    public const MONTHLY_COMPARISON = 'monthly_comparison';
    public const CATEGORY_PERCENTAGE = 'category_percentage';

    public function detect(string $message): ?string
    {
        $message = $this->normalize($message);

        if ($message === '') {
            return null;
        }

        if ($this->looksLikeCategoryPercentage($message)) {
            return self::CATEGORY_PERCENTAGE;
        }

        if ($this->containsAny($message, ['banding', 'dibanding', 'lebih hemat', 'lebih boros', 'bulan lalu'])) {
            return self::MONTHLY_COMPARISON;
        }

        if (
            $this->containsAny($message, ['bulan ini'])
            && $this->containsAny($message, ['pengeluaran', 'expense', 'belanja', 'jajan', 'terbesar', 'tertinggi'])
        ) {
            return self::MONTHLY_EXPENSE_SUMMARY;
        }

        if (
            $this->containsAny($message, ['paling boros', 'boros dimana', 'boros di mana', 'kategori pengeluaran tertinggi', 'kategori tertinggi'])
            || (
                $this->containsAny($message, ['pengeluaran', 'expense', 'belanja', 'jajan'])
                && $this->containsAny($message, ['terbesar', 'tertinggi', 'paling besar', 'paling banyak'])
            )
        ) {
            return self::TOP_EXPENSE_CATEGORY;
        }

        return null;
    }

    public function extractCategoryKeyword(string $message): ?string
    {
        $message = $this->normalize($message);

        $cleaned = preg_replace(
            '/\b(pengeluaran|expense|biaya|ku|aku|saya|berapa|persen|percentage|bulan|ini|itu|di|kategori)\b/u',
            ' ',
            $message,
        ) ?? $message;

        $cleaned = preg_replace('/\s+/', ' ', trim($cleaned)) ?? $cleaned;

        return $cleaned === '' ? null : $cleaned;
    }

    private function looksLikeCategoryPercentage(string $message): bool
    {
        return $this->containsAny($message, ['persen', 'percentage', '%'])
            && $this->containsAny($message, ['pengeluaran', 'expense', 'biaya']);
    }

    private function containsAny(string $message, array $needles): bool
    {
        foreach ($needles as $needle) {
            if (str_contains($message, $needle)) {
                return true;
            }
        }

        return false;
    }

    private function normalize(string $message): string
    {
        $message = strtolower(trim($message));
        $message = preg_replace('/[^\pL\pN%\s]+/u', ' ', $message) ?? $message;

        return preg_replace('/\s+/', ' ', trim($message)) ?? $message;
    }
}
