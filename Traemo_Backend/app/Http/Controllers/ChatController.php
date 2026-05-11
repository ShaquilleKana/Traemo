<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Chat;
use App\Models\Transaction;

class ChatController extends Controller
{
    public function handle(Request $request)
    {
        $userId = $request->user_id;

        $message = strtolower($request->message);

        // 1. simpan chat user
        Chat::create([
            'user_id' => $userId,
            'message' => $message,
            'sender' => 'user'
        ]);

        // 2. parsing
        preg_match('/(\D+)\s(\d+)/', $message, $matches);

        if (!$matches) {
            $reply = "Format tidak valid";

            Chat::create([
                'user_id' => $userId,
                'message' => $reply,
                'sender' => 'bot'
            ]);

            return response()->json(['message' => $reply]);
        }

        $kategori = trim($matches[1]);
        $jumlah = (int)$matches[2];

        // 3. tentukan tipe
        $tipe = 'expense';

        // 4. simpan transaksi
        $transaction = Transaction::create([
            'user_id' => $userId,
            'kategori' => $kategori,
            'jumlah' => $jumlah,
            'tipe' => $tipe,
            'tanggal' => now()
        ]);

        $reply = "Transaksi berhasil dicatat";

        // 5. simpan chat bot
        Chat::create([
            'user_id' => $userId,
            'message' => $reply,
            'sender' => 'bot',
            'transaction_id' => $transaction->id
        ]);

        return response()->json([
            'message' => $reply,
            'data' => $transaction
        ]);
    }

    public function index(Request $request)
    {
        $userId = $request->user_id;

        $chats = Chat::where('user_id', $userId)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($chats);
    }

    public function summary()
    {
        $userId = 1;

        $income = Transaction::where('user_id', $userId)
            ->where('tipe', 'income')
            ->sum('jumlah');

        $expense = Transaction::where('user_id', $userId)
            ->where('tipe', 'expense')
            ->sum('jumlah');

        return response()->json([
            'income' => $income,
            'expense' => $expense,
            'saldo' => $income - $expense
        ]);
    }
}
