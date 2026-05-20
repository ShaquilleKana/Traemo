<?php

namespace App\Services;

use App\Enums\AIResponseStatus;
use App\Models\TransactionCategory;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Throwable;

class GeminiService
{
    private const MODEL = 'gemini-2.5-flash-lite';

    public function generate(string $message): string
    {
        $response = Http::post(
            $this->endpointUrl(),
            [
                'contents' => [
                    [
                        'parts' => [
                            [
                                'text' => $message,
                            ],
                        ],
                    ],
                ],
            ]
        );

        $response->throw();

        return $response->json('candidates.0.content.parts.0.text');
    }

    public function parseTransaction(string $message): array
    {
        $categories = TransactionCategory::query()
            ->orderBy('type')
            ->orderBy('name')
            ->get();

        if ($categories->isEmpty()) {
            return $this->fallbackResponse();
        }

        try {
            $response = Http::post(
                $this->endpointUrl(),
                [
                    'contents' => [
                        [
                            'parts' => [
                                [
                                    'text' => $this->buildParserPrompt($message, $categories),
                                ],
                            ],
                        ],
                    ],
                    'generationConfig' => [
                        'temperature' => 0.1,
                        'responseMimeType' => 'application/json',
                    ],
                ],
            );

            $response->throw();
        } catch (Throwable) {
            return $this->fallbackResponse();
        }

        $decoded = json_decode(
            $this->cleanJsonResponse($response->json('candidates.0.content.parts.0.text', '')),
            true,
        );

        if (!is_array($decoded)) {
            return $this->fallbackResponse();
        }

        return $this->validateParsedTransaction($decoded, $categories);
    }

    public function generateFinancialInsight(array $summary): string
    {
        try {
            $response = Http::post(
                $this->endpointUrl(),
                [
                    'contents' => [
                        [
                            'parts' => [
                                [
                                    'text' => $this->buildFinancialInsightPrompt($summary),
                                ],
                            ],
                        ],
                    ],
                    'generationConfig' => [
                        'temperature' => 0.3,
                    ],
                ],
            );

            $response->throw();

            return trim((string) $response->json('candidates.0.content.parts.0.text'));
        } catch (Throwable) {
            return $this->fallbackInsightResponse($summary);
        }
    }

    private function buildParserPrompt(string $message, $categories): string
    {
        $categoryPrompt = $categories
            ->map(function (TransactionCategory $category): string {
                $hints = collect($category->semantic_hints ?? [])
                    ->filter()
                    ->implode(', ');

                return "Category:\n{$category->name}\nType:\n{$category->type}\nHints:\n{$hints}";
            })
            ->implode("\n\n");

        return <<<PROMPT
You are Traemo's financial transaction parser for Indonesian users.

Return JSON ONLY. Do not return markdown, code fences, explanations, or extra text.

Your task:
- Classify a single user message as one or more financial transactions.
- Understand Indonesian slang, abbreviations, typos, and casual phrasing.
- Detect Indonesian conversational transaction chains separated by words such as terus, lalu, habis itu, kemudian, sama, and dan.
- Convert amounts safely: rb/ribu/k = thousands, jt/juta = millions, m/miliar = billions.
- Use semantic category matching from the available categories and hints below.
- Never invent a category outside the available categories.
- Never hallucinate an amount, description, or category.
- If any detected transaction has an important field missing or ambiguous, return need_clarification for the full message.
- If the message is not a financial transaction, return invalid.
- Include confidence_score for each successful transaction, from 0 to 1.
- Use a short natural Indonesian response_message when status is success or invalid.
- ALWAYS return transactions as an array for success, even for one transaction.
- NEVER return the old single-object success structure.
- If the user provides a previous transaction list and a correction, regenerate the corrected full transaction list instead of returning only the corrected item.

Available categories:
{$categoryPrompt}

Allowed output formats:

Success:
{
  "status": "success",
  "transactions": [
    {
      "category": "one exact category name from available categories",
      "amount": 15000,
      "description": "short normalized transaction description",
      "confidence_score": 0.98
    }
  ],
  "response_message": "Saya menangkap transaksi ini. Mohon konfirmasi."
}

Need clarification:
{
  "status": "need_clarification",
  "missing_field": "category|amount|description",
  "question": "short Indonesian clarification question"
}

Invalid:
{
  "status": "invalid",
  "response_message": "Pesan tidak terdeteksi sebagai transaksi keuangan."
}

Important examples:
- "makan bakso 15rb" is an expense for the closest food/drink category.
- "tadi makan 10rb terus beli bensin 50rb terus makan malam 17rb" contains three transactions.
- "gajian 5jt" is income for the closest salary/work category.
- "bayar 50rb" needs clarification because category/description is ambiguous.
- "halo apa kabar" is invalid.
- "aku transfer ke istri 2 juta" is a financial transaction and should use the closest available outgoing transfer, family support, or giving category.

User message:
{$message}
PROMPT;
    }

    private function buildFinancialInsightPrompt(array $summary): string
    {
        $summaryJson = json_encode($summary, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        return <<<PROMPT
You are Traemo's friendly financial insight assistant for Indonesian users.

Use ONLY the summarized backend-calculated data below. Do not invent numbers, categories, periods, causes, recommendations, or extra facts.
Write in Indonesian, conversational, friendly, non-judgmental, and informative.
Maximum 2 short sentences.
Avoid financial advice.
If has_data is false, say briefly that there is not enough transaction data yet.

Backend summary:
{$summaryJson}
PROMPT;
    }

    private function cleanJsonResponse(?string $response): string
    {
        $cleaned = trim((string) $response);
        $cleaned = preg_replace('/^```(?:json)?\s*/i', '', $cleaned) ?? $cleaned;
        $cleaned = preg_replace('/\s*```$/', '', $cleaned) ?? $cleaned;
        $cleaned = trim($cleaned);

        $firstBrace = strpos($cleaned, '{');
        $lastBrace = strrpos($cleaned, '}');

        if ($firstBrace === false || $lastBrace === false || $lastBrace < $firstBrace) {
            return $cleaned;
        }

        return substr($cleaned, $firstBrace, $lastBrace - $firstBrace + 1);
    }

    private function validateParsedTransaction(array $data, $categories): array
    {
        $status = $data['status'] ?? null;

        if (!in_array($status, array_column(AIResponseStatus::cases(), 'value'), true)) {
            return $this->fallbackResponse();
        }

        if ($status === AIResponseStatus::Success->value) {
            if (empty($data['transactions']) || !is_array($data['transactions'])) {
                return $this->fallbackResponse();
            }

            $transactions = [];

            foreach ($data['transactions'] as $transaction) {
                if (
                    !is_array($transaction)
                    || !isset($transaction['amount'], $transaction['category'], $transaction['description'], $transaction['confidence_score'])
                    || !is_numeric($transaction['amount'])
                    || !is_numeric($transaction['confidence_score'])
                    || (float) $transaction['amount'] <= 0
                    || trim((string) $transaction['description']) === ''
                ) {
                    return $this->fallbackResponse();
                }

                $category = $this->findCategoryByName((string) $transaction['category'], $categories);

                if (!$category) {
                    return $this->fallbackResponse();
                }

                $transactions[] = [
                    'category' => $category->name,
                    'transaction_category_id' => $category->id,
                    'amount' => (int) round((float) $transaction['amount']),
                    'description' => trim((string) $transaction['description']),
                    'confidence_score' => max(0, min(1, (float) $transaction['confidence_score'])),
                ];
            }

            return [
                'status' => AIResponseStatus::Success->value,
                'transactions' => $transactions,
                'response_message' => trim((string) ($data['response_message'] ?? 'Saya menangkap transaksi ini. Mohon konfirmasi.')),
            ];
        }

        if ($status === AIResponseStatus::NeedClarification->value) {
            if (empty($data['missing_field']) || empty($data['question'])) {
                return $this->fallbackResponse();
            }

            return [
                'status' => AIResponseStatus::NeedClarification->value,
                'missing_field' => trim((string) $data['missing_field']),
                'question' => trim((string) $data['question']),
            ];
        }

        return [
            'status' => AIResponseStatus::Invalid->value,
            'response_message' => trim((string) ($data['response_message'] ?? 'Pesan tidak terdeteksi sebagai transaksi keuangan.')),
        ];
    }

    private function findCategoryByName(string $name, $categories): ?TransactionCategory
    {
        $normalizedName = Str::lower(trim($name));

        return $categories->first(
            fn (TransactionCategory $category): bool => Str::lower($category->name) === $normalizedName,
        );
    }

    private function fallbackResponse(): array
    {
        return [
            'status' => AIResponseStatus::Invalid->value,
            'response_message' => 'Pesan tidak terdeteksi sebagai transaksi keuangan.',
        ];
    }

    private function fallbackInsightResponse(array $summary): string
    {
        if (!($summary['has_data'] ?? false)) {
            return 'Belum ada data transaksi yang cukup untuk insight ini.';
        }

        return match ($summary['insight_type'] ?? null) {
            'monthly_comparison' => $this->fallbackMonthlyComparison($summary),
            'category_percentage' => sprintf(
                'Pengeluaran %s bulan ini sebesar %s, sekitar %s%% dari total pengeluaran.',
                $summary['category'] ?? 'kategori ini',
                $this->formatRupiah((int) ($summary['category_amount'] ?? 0)),
                number_format((float) ($summary['percentage'] ?? 0), 2, ',', '.'),
            ),
            default => sprintf(
                'Pengeluaran terbesar kamu ada di kategori %s sebesar %s.',
                $summary['top_expense_category'] ?? 'tidak diketahui',
                $this->formatRupiah((int) ($summary['amount'] ?? 0)),
            ),
        };
    }

    private function fallbackMonthlyComparison(array $summary): string
    {
        $trend = (int) ($summary['trend'] ?? 0);

        if ($trend < 0) {
            return sprintf(
                'Bulan ini kamu lebih hemat %s dibanding bulan lalu.',
                $this->formatRupiah((int) ($summary['difference'] ?? 0)),
            );
        }

        if ($trend > 0) {
            return sprintf(
                'Bulan ini pengeluaran kamu lebih besar %s dibanding bulan lalu.',
                $this->formatRupiah((int) ($summary['difference'] ?? 0)),
            );
        }

        return 'Pengeluaran bulan ini sama dengan bulan lalu.';
    }

    private function formatRupiah(int $amount): string
    {
        return 'Rp' . number_format($amount, 0, ',', '.');
    }

    private function endpointUrl(): string
    {
        return 'https://generativelanguage.googleapis.com/v1beta/models/' . self::MODEL . ':generateContent?key=' . config('services.gemini.api_key');
    }
}
