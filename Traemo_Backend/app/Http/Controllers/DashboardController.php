<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function summary(Request $request)
    {
        $userId = $request->user_id;

        $income = Transaction::where('user_id', $userId)
            ->whereHas('category', fn ($query) => $query->where('type', 'income'))
            ->sum('amount');

        $expense = Transaction::where('user_id', $userId)
            ->whereHas('category', fn ($query) => $query->where('type', 'expense'))
            ->sum('amount');

        $balance = $income - $expense;

        $weeklyIncome = [];
        $weeklyExpense = [];

        for ($i = 0; $i < 7; $i++) {
            $date = now()->startOfWeek()->addDays($i)->toDateString();

            $dailyIncome = Transaction::where('user_id', $userId)
                ->whereHas('category', fn ($query) => $query->where('type', 'income'))
                ->whereDate('created_at', $date)
                ->sum('amount');

            $dailyExpense = Transaction::where('user_id', $userId)
                ->whereHas('category', fn ($query) => $query->where('type', 'expense'))
                ->whereDate('created_at', $date)
                ->sum('amount');

            $weeklyIncome[] = $dailyIncome;
            $weeklyExpense[] = $dailyExpense;
        }

        return response()->json([
            'balance' => $balance,
            'income' => $income,
            'expense' => $expense,
            'weekly_income' => $weeklyIncome,
            'weekly_expense' => $weeklyExpense,
        ]);
    }
}
