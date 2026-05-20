<?php

namespace App\Http\Controllers;

use App\Enums\AIResponseStatus;
use App\Enums\TransactionFlowStatus;
use App\Models\Chat;
use App\Models\Transaction;
use App\Services\ClarificationContextService;
use App\Services\FinancialInsightIntentService;
use App\Services\FinancialInsightService;
use App\Services\GeminiService;
use App\Services\PendingTransactionService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function handle(
        Request $request,
        GeminiService $geminiService,
        ClarificationContextService $clarificationContextService,
        PendingTransactionService $pendingTransactionService,
        FinancialInsightIntentService $financialInsightIntentService,
        FinancialInsightService $financialInsightService,
    ) {
        $this->authenticateCurrentRequest($request);

        $userId = auth()->id() ?? $request->user_id;

        $message = strtolower(trim($request->message));

        // 1. simpan chat user
        Chat::create([
            'user_id' => $userId,
            'message' => $message,
            'sender' => 'user'
        ]);

        $pending = $pendingTransactionService->retrieve($userId);

        if ($pending) {
            if ($this->isPositiveConfirmation($message)) {
                if (!$pendingTransactionService->isValidForSave($pending)) {
                    $pendingTransactionService->clear($userId);

                    return $this->botReply($userId, 'Transaksi tidak dapat disimpan karena data tidak valid. Silakan kirim ulang transaksi yang benar.');
                }

                $transactions = DB::transaction(function () use ($pending, $userId) {
                    return collect($pending['transactions'])
                        ->map(fn (array $transaction): Transaction => Transaction::create([
                            'user_id' => $userId,
                            'description' => $transaction['description'],
                            'amount' => $transaction['amount'],
                            'transaction_category_id' => $transaction['transaction_category_id'],
                        ]))
                        ->values();
                });

                $pendingTransactionService->clear($userId);
                $clarificationContextService->clear($userId);

                $transactionCount = $transactions->count();
                $reply = $transactionCount === 1
                    ? 'Transaksi berhasil dicatat.'
                    : "{$transactionCount} transaksi berhasil dicatat.";

                Chat::create([
                    'user_id' => $userId,
                    'message' => $reply,
                    'sender' => 'bot',
                    'transaction_id' => $transactions->first()?->id
                ]);

                return response()->json([
                    'message' => $reply,
                    'data' => $transactionCount === 1 ? $transactions->first() : $transactions,
                ]);
            }

            if ($this->looksLikeCorrection($message)) {
                $pendingTransactionService->clear($userId);

                return $this->handleParsedTransaction(
                    $userId,
                    $geminiService->parseTransaction($this->buildCorrectionMessage($pending, $message)),
                    $clarificationContextService,
                    $pendingTransactionService,
                    $message,
                    0,
                );
            }

            if ($this->isNegativeConfirmation($message)) {
                $pendingTransactionService->clear($userId);
                $clarificationContextService->clear($userId);

                $reply = "Baik, transaksi dibatalkan. Silakan kirim ulang transaksi yang benar.";

                Chat::create([
                    'user_id' => $userId,
                    'message' => $reply,
                    'sender' => 'bot'
                ]);

                return response()->json(['message' => $reply]);
            }

            return $this->botReply($userId, 'Masih ada transaksi yang menunggu konfirmasi. Ketik ya untuk simpan semua, batal untuk membatalkan, atau kirim koreksi.');
        }

        $clarificationContext = $clarificationContextService->retrieve($userId);
        $messageToParse = $clarificationContext
            ? $this->mergeClarificationMessage($clarificationContext, $message)
            : $message;

        $financialInsightIntent = $financialInsightIntentService->detect($messageToParse);

        if ($financialInsightIntent !== null) {
            return $this->botReply(
                $userId,
                $financialInsightService->answer($messageToParse, $financialInsightIntent),
            );
        }

        return $this->handleParsedTransaction(
            $userId,
            $geminiService->parseTransaction($messageToParse),
            $clarificationContextService,
            $pendingTransactionService,
            $messageToParse,
            (int) ($clarificationContext['attempts'] ?? 0),
        );
    }

    private function handleParsedTransaction(
        int|string $userId,
        array $parsedData,
        ClarificationContextService $clarificationContextService,
        PendingTransactionService $pendingTransactionService,
        string $messageToParse,
        int $clarificationAttempts,
    ) {
        if ($parsedData['status'] === AIResponseStatus::NeedClarification->value) {
            if ($clarificationAttempts >= 1) {
                $clarificationContextService->clear($userId);

                return $this->botReply($userId, 'Pesan tidak terdeteksi sebagai transaksi keuangan.');
            }

            $clarificationContextService->save($userId, [
                'status' => TransactionFlowStatus::PendingClarification->value,
                'original_message' => $messageToParse,
                'missing_field' => $parsedData['missing_field'],
                'question' => $parsedData['question'],
                'attempts' => $clarificationAttempts + 1,
            ]);

            return $this->botReply($userId, $parsedData['question']);
        }

        if ($parsedData['status'] === AIResponseStatus::Invalid->value) {
            $clarificationContextService->clear($userId);

            return $this->botReply($userId, $parsedData['response_message']);
        }

        $clarificationContextService->clear($userId);

        $pendingData = $pendingTransactionService->saveConfirmation($userId, $parsedData);

        return $this->botReply($userId, $this->buildConfirmationMessage($pendingData), $pendingData);
    }

    public function index(Request $request)
    {
        $userId = $request->user_id;

        $chats = Chat::where('user_id', $userId)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($chats);
    }

    public function clear(Request $request)
    {
        $userId = $request->user_id;

        Chat::where('user_id', $userId)->delete();

        return response()->json([
            'message' => 'Chat history cleared'
        ]);
    }

    public function summary()
    {
        $userId = 1;

        $income = Transaction::where('user_id', $userId)
            ->whereHas('category', fn ($query) => $query->where('type', 'income'))
            ->sum('amount');

        $expense = Transaction::where('user_id', $userId)
            ->whereHas('category', fn ($query) => $query->where('type', 'expense'))
            ->sum('amount');

        return response()->json([
            'income' => $income,
            'expense' => $expense,
            'saldo' => $income - $expense
        ]);
    }

    public function geminiTest(GeminiService $geminiService)
    {
        $reply = $geminiService->generate('Reply with: Gemini connection success');

        return response()->json([
            'reply' => trim($reply)
        ]);
    }

    private function isPositiveConfirmation(string $message): bool
    {
        return $this->containsAnyConfirmationToken($message, [
            'ya',
            'iya',
            'betul',
            'benar',
            'oke',
            'ok',
            'lanjut',
            'confirm',
        ]);
    }

    private function isNegativeConfirmation(string $message): bool
    {
        return $this->containsAnyConfirmationToken($message, [
            'tidak',
            'salah',
            'batal',
            'cancel',
            'jangan',
            'engga',
            'ngga',
            'nggak',
            'gak',
        ]);
    }

    private function containsAnyConfirmationToken(string $message, array $tokens): bool
    {
        $words = preg_split('/[^a-z0-9]+/', $message, -1, PREG_SPLIT_NO_EMPTY);

        return count(array_intersect($words ?: [], $tokens)) > 0;
    }

    private function looksLikeCorrection(string $message): bool
    {
        foreach (['harusnya', 'seharusnya', 'koreksi', 'ubah', 'ganti', 'edit'] as $keyword) {
            if (str_contains($message, $keyword)) {
                return true;
            }
        }

        return preg_match('/\d/', $message) === 1;
    }

    private function buildCorrectionMessage(array $pending, string $message): string
    {
        $previousTransactions = json_encode(
            $pending['transactions'] ?? [],
            JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES,
        );

        return <<<MESSAGE
Previous detected transactions:
{$previousTransactions}

User correction:
"{$message}"

Regenerate the corrected full transaction list.
Return ONLY valid JSON.
MESSAGE;
    }

    private function mergeClarificationMessage(array $context, string $message): string
    {
        $originalMessage = trim((string) ($context['original_message'] ?? ''));

        return trim($originalMessage . ' ' . $message);
    }

    private function buildConfirmationMessage(array $pendingData): string
    {
        $transactions = $pendingData['transactions'] ?? [];
        $count = count($transactions);

        if ($count === 1) {
            $transaction = $transactions[0];

            return "Apakah transaksi berikut benar?\n\n"
                . "Deskripsi: {$transaction['description']}\n"
                . "Kategori: {$transaction['category']}\n"
                . "Nominal: Rp" . number_format($transaction['amount'], 0, ',', '.') . "\n\n"
                . "Ketik:\n"
                . "- ya -> simpan\n"
                . "- batal -> batalkan";
        }

        $lines = ["Mendeteksi {$count} transaksi:"];

        foreach ($transactions as $index => $transaction) {
            $number = $index + 1;
            $lines[] = "";
            $lines[] = "{$number}.";
            $lines[] = "Deskripsi: {$transaction['description']}";
            $lines[] = "Kategori: {$transaction['category']}";
            $lines[] = "Nominal: Rp" . number_format($transaction['amount'], 0, ',', '.');
        }

        $lines[] = "";
        $lines[] = "Apakah semua transaksi sudah benar?";
        $lines[] = "Ketik:";
        $lines[] = "- ya -> simpan semua";
        $lines[] = "- batal -> batalkan";

        return implode("\n", $lines);
    }

    private function authenticateCurrentRequest(Request $request): void
    {
        if (auth()->check() || !$request->filled('user_id')) {
            return;
        }

        Auth::onceUsingId($request->user_id);
    }

    private function botReply(int|string $userId, string $reply, ?array $data = null)
    {
        Chat::create([
            'user_id' => $userId,
            'message' => $reply,
            'sender' => 'bot'
        ]);

        $response = ['message' => $reply];

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response);
    }
}
