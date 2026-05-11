<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->user_id;

        $transactions = Transaction::where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($transactions);
    }
}
