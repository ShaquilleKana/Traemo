<?php

namespace App\Http\Controllers;

use App\Exports\TransactionsExport;
use App\Models\Transaction;
use Maatwebsite\Excel\Facades\Excel;

class TransactionExportController extends Controller
{
    public function excel()
    {
        $hasTransactions = Transaction::query()
            ->where('user_id', auth()->id())
            ->exists();

        if (! $hasTransactions) {
            return response()->json([
                'message' => 'Tidak ada transaksi untuk diexport.',
            ], 404);
        }

        $fileName = 'traemo_transactions_' . now()->format('Y_m_d') . '.xlsx';

        return Excel::download(new TransactionsExport(), $fileName);
    }
}
