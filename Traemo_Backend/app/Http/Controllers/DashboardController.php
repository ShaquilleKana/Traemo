<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function summary(Request $request)
    {
        $income = Transaction::where('user_id', auth()->id())
            ->whereHas('category', fn ($query) => $query->where('type', 'income'))
            ->sum('amount');

        $expense = Transaction::where('user_id', auth()->id())
            ->whereHas('category', fn ($query) => $query->where('type', 'expense'))
            ->sum('amount');

        $balance = $income - $expense;

        $weeklyIncome = [];
        $weeklyExpense = [];

        for ($i = 0; $i < 7; $i++) {
            $date = now()->startOfWeek()->addDays($i)->toDateString();

            $dailyIncome = Transaction::where('user_id', auth()->id())
                ->whereHas('category', fn ($query) => $query->where('type', 'income'))
                ->whereDate('created_at', $date)
                ->sum('amount');

            $dailyExpense = Transaction::where('user_id', auth()->id())
                ->whereHas('category', fn ($query) => $query->where('type', 'expense'))
                ->whereDate('created_at', $date)
                ->sum('amount');

            $weeklyIncome[] = $dailyIncome;
            $weeklyExpense[] = $dailyExpense;
        }

        $expenseCategoryDistribution = Transaction::query()
            ->select([
                'transaction_categories.name as category',
                DB::raw('SUM(transactions.amount) as total'),
            ])
            ->join(
                'transaction_categories',
                'transactions.transaction_category_id',
                '=',
                'transaction_categories.id'
            )
            ->where('user_id', auth()->id())
            ->where('transaction_categories.type', 'expense')
            ->groupBy('transaction_categories.id', 'transaction_categories.name')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($item) => [
                'category' => $item->category,
                'total' => (int) $item->total,
            ])
            ->values();

        return response()->json([
            'balance' => $balance,
            'income' => $income,
            'expense' => $expense,
            'weekly_income' => $weeklyIncome,
            'weekly_expense' => $weeklyExpense,
            'expense_category_distribution' => $expenseCategoryDistribution,
        ]);
    }
}
