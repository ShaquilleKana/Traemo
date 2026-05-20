<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\TransactionCategory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FinancialInsightService
{
    public function __construct(
        private readonly GeminiService $geminiService,
        private readonly FinancialInsightIntentService $intentService,
    ) {
    }

    public function answer(string $message, string $intent): string
    {
        $summary = match ($intent) {
            FinancialInsightIntentService::MONTHLY_EXPENSE_SUMMARY => $this->monthlyExpenseSummary(),
            FinancialInsightIntentService::MONTHLY_COMPARISON => $this->monthlyComparison(),
            FinancialInsightIntentService::CATEGORY_PERCENTAGE => $this->categoryPercentage($message),
            default => $this->topExpenseCategory(),
        };

        return $this->geminiService->generateFinancialInsight($summary);
    }

    private function topExpenseCategory(?Carbon $startDate = null, ?Carbon $endDate = null): array
    {
        $topCategory = $this->expenseCategoryTotals($startDate, $endDate)->first();

        return [
            'insight_type' => FinancialInsightIntentService::TOP_EXPENSE_CATEGORY,
            'period' => $this->periodLabel($startDate, $endDate),
            'top_expense_category' => $topCategory?->category_name,
            'amount' => (int) ($topCategory?->total_amount ?? 0),
            'has_data' => $topCategory !== null,
        ];
    }

    private function monthlyExpenseSummary(): array
    {
        $startDate = now()->startOfMonth();
        $endDate = now()->endOfMonth();
        $topCategory = $this->expenseCategoryTotals($startDate, $endDate)->first();
        $totalExpense = $this->expenseTransactions()
            ->whereBetween('transactions.created_at', [$startDate, $endDate])
            ->sum('transactions.amount');

        return [
            'insight_type' => FinancialInsightIntentService::MONTHLY_EXPENSE_SUMMARY,
            'period' => now()->translatedFormat('F Y'),
            'total_expense' => (int) $totalExpense,
            'top_expense_category' => $topCategory?->category_name,
            'amount' => (int) ($topCategory?->total_amount ?? 0),
            'has_data' => $topCategory !== null,
        ];
    }

    private function monthlyComparison(): array
    {
        $currentStart = now()->startOfMonth();
        $currentEnd = now()->endOfMonth();
        $previousStart = now()->subMonthNoOverflow()->startOfMonth();
        $previousEnd = now()->subMonthNoOverflow()->endOfMonth();

        $currentExpense = (int) $this->expenseTransactions()
            ->whereBetween('transactions.created_at', [$currentStart, $currentEnd])
            ->sum('transactions.amount');

        $previousExpense = (int) $this->expenseTransactions()
            ->whereBetween('transactions.created_at', [$previousStart, $previousEnd])
            ->sum('transactions.amount');

        return [
            'insight_type' => FinancialInsightIntentService::MONTHLY_COMPARISON,
            'current_month' => now()->translatedFormat('F Y'),
            'previous_month' => now()->subMonthNoOverflow()->translatedFormat('F Y'),
            'current_month_expense' => $currentExpense,
            'previous_month_expense' => $previousExpense,
            'difference' => abs($currentExpense - $previousExpense),
            'trend' => $currentExpense <=> $previousExpense,
            'has_data' => $currentExpense > 0 || $previousExpense > 0,
        ];
    }

    private function categoryPercentage(string $message): array
    {
        $startDate = now()->startOfMonth();
        $endDate = now()->endOfMonth();
        $category = $this->findExpenseCategoryFromMessage($message);
        $totalExpense = (int) $this->expenseTransactions()
            ->whereBetween('transactions.created_at', [$startDate, $endDate])
            ->sum('transactions.amount');
        $categoryExpense = 0;

        if ($category) {
            $categoryExpense = (int) $this->expenseTransactions()
                ->where('transactions.transaction_category_id', $category->id)
                ->whereBetween('transactions.created_at', [$startDate, $endDate])
                ->sum('transactions.amount');
        }

        return [
            'insight_type' => FinancialInsightIntentService::CATEGORY_PERCENTAGE,
            'period' => now()->translatedFormat('F Y'),
            'category' => $category?->name,
            'category_amount' => $categoryExpense,
            'total_expense' => $totalExpense,
            'percentage' => $totalExpense > 0 ? round(($categoryExpense / $totalExpense) * 100, 2) : 0,
            'has_data' => $category !== null && $totalExpense > 0,
        ];
    }

    private function expenseCategoryTotals(?Carbon $startDate = null, ?Carbon $endDate = null)
    {
        $query = $this->expenseTransactions()
            ->select([
                'transaction_categories.name as category_name',
                DB::raw('SUM(transactions.amount) as total_amount'),
            ])
            ->groupBy('transaction_categories.id', 'transaction_categories.name')
            ->orderByDesc('total_amount');

        if ($startDate && $endDate) {
            $query->whereBetween('transactions.created_at', [$startDate, $endDate]);
        }

        return $query->get();
    }

    private function expenseTransactions(): Builder
    {
        return Transaction::query()
            ->join('transaction_categories', 'transactions.transaction_category_id', '=', 'transaction_categories.id')
            ->where('user_id', auth()->id())
            ->where('transaction_categories.type', 'expense');
    }

    private function findExpenseCategoryFromMessage(string $message): ?TransactionCategory
    {
        $keyword = $this->intentService->extractCategoryKeyword($message);

        if (!$keyword) {
            return null;
        }

        $categories = TransactionCategory::query()
            ->where('type', 'expense')
            ->get();

        $normalizedKeyword = $this->normalizeSearchText($keyword);

        return $categories->first(function (TransactionCategory $category) use ($normalizedKeyword): bool {
            if (str_contains($this->normalizeSearchText($category->name), $normalizedKeyword)) {
                return true;
            }

            foreach ($category->semantic_hints ?? [] as $hint) {
                if (str_contains($this->normalizeSearchText((string) $hint), $normalizedKeyword)) {
                    return true;
                }
            }

            return false;
        });
    }

    private function periodLabel(?Carbon $startDate, ?Carbon $endDate): string
    {
        if (!$startDate || !$endDate) {
            return 'semua waktu';
        }

        return $startDate->toDateString() . ' sampai ' . $endDate->toDateString();
    }

    private function normalizeSearchText(string $value): string
    {
        $value = Str::lower($value);
        $value = preg_replace('/[^\pL\pN\s]+/u', ' ', $value) ?? $value;

        return preg_replace('/\s+/', ' ', trim($value)) ?? $value;
    }
}
