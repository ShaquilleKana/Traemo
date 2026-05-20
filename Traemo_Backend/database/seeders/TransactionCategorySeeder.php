<?php

namespace Database\Seeders;

use App\Models\TransactionCategory;
use Illuminate\Database\Seeder;

class TransactionCategorySeeder extends Seeder
{
    /**
     * Seed the transaction categories used by AI classification.
     */
    public function run(): void
    {
        $categories = [
            [
                'type' => 'income',
                'name' => 'Pendapatan Pekerjaan',
                'semantic_hints' => ['gaji', 'bonus', 'komisi', 'payroll', 'salary', 'upah', 'lembur', 'THR'],
            ],
            [
                'type' => 'income',
                'name' => 'Pendapatan Usaha',
                'semantic_hints' => ['bisnis', 'usaha', 'freelance', 'project', 'client', 'jualan', 'fee', 'profit'],
            ],
            [
                'type' => 'income',
                'name' => 'Pendapatan Properti',
                'semantic_hints' => ['dividen', 'bunga bank', 'royalti', 'sewa', 'investasi properti'],
            ],
            [
                'type' => 'income',
                'name' => 'Transfer & Hibah',
                'semantic_hints' => ['hadiah', 'bantuan', 'kiriman keluarga', 'transfer masuk', 'hibah'],
            ],
            [
                'type' => 'expense',
                'name' => 'Makanan & Minuman',
                'semantic_hints' => ['makan', 'kopi', 'jajan', 'restoran', 'cafe', 'gofood', 'makanan', 'minuman', 'snack'],
            ],
            [
                'type' => 'expense',
                'name' => 'Perumahan & Utilitas',
                'semantic_hints' => ['kos', 'kontrakan', 'listrik', 'air', 'gas', 'wifi rumah', 'iuran', 'sewa rumah'],
            ],
            [
                'type' => 'expense',
                'name' => 'Transportasi',
                'semantic_hints' => ['bensin', 'grab', 'gojek', 'tol', 'parkir', 'servis kendaraan', 'transportasi umum'],
            ],
            [
                'type' => 'expense',
                'name' => 'Informasi & Komunikasi',
                'semantic_hints' => ['pulsa', 'kuota', 'internet', 'streaming', 'netflix', 'spotify', 'software', 'data'],
            ],
            [
                'type' => 'expense',
                'name' => 'Kesehatan',
                'semantic_hints' => ['dokter', 'rumah sakit', 'obat', 'klinik', 'asuransi kesehatan'],
            ],
            [
                'type' => 'expense',
                'name' => 'Pendidikan',
                'semantic_hints' => ['kuliah', 'sekolah', 'buku', 'kursus', 'pelatihan', 'sertifikasi'],
            ],
            [
                'type' => 'expense',
                'name' => 'Rekreasi & Gaya Hidup',
                'semantic_hints' => ['nongkrong', 'hiburan', 'bioskop', 'shopping', 'pakaian', 'hobi', 'liburan'],
            ],
            [
                'type' => 'expense',
                'name' => 'Layanan Keuangan',
                'semantic_hints' => ['admin bank', 'biaya transfer', 'bunga pinjaman', 'biaya layanan'],
            ],
            [
                'type' => 'expense',
                'name' => 'Social Giving/Donasi',
                'semantic_hints' => ['donasi', 'zakat', 'bantuan sosial', 'sedekah', 'sumbangan'],
            ],
            [
                'type' => 'other',
                'name' => 'Tabungan & Investasi',
                'semantic_hints' => ['tabungan', 'deposito', 'saham', 'crypto', 'reksa dana', 'investasi'],
            ],
            [
                'type' => 'other',
                'name' => 'Hutang & Cicilan',
                'semantic_hints' => ['cicilan', 'kartu kredit', 'pinjaman', 'hutang', 'pelunasan'],
            ],
        ];

        foreach ($categories as $category) {
            TransactionCategory::updateOrCreate(
                [
                    'type' => $category['type'],
                    'name' => $category['name'],
                ],
                [
                    'semantic_hints' => $category['semantic_hints'],
                ],
            );
        }
    }
}
