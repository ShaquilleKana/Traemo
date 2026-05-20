<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasColumn('transactions', 'amount')) {
            Schema::table('transactions', function (Blueprint $table) {
                $table->unsignedBigInteger('amount')
                    ->nullable()
                    ->after('transaction_category_id');
            });
        }

        if (Schema::hasColumn('transactions', 'jumlah')) {
            DB::table('transactions')->update([
                'amount' => DB::raw('jumlah'),
            ]);
        }

        Schema::table('transactions', function (Blueprint $table) {
            if (Schema::hasColumn('transactions', 'kategori')) {
                $table->dropColumn('kategori');
            }

            if (Schema::hasColumn('transactions', 'jumlah')) {
                $table->dropColumn('jumlah');
            }

            if (Schema::hasColumn('transactions', 'tipe')) {
                $table->dropColumn('tipe');
            }

            if (Schema::hasColumn('transactions', 'tanggal')) {
                $table->dropColumn('tanggal');
            }

            if (Schema::hasColumn('transactions', 'updated_at')) {
                $table->dropColumn('updated_at');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (!Schema::hasColumn('transactions', 'kategori')) {
                $table->string('kategori')->nullable()->after('transaction_category_id');
            }

            if (!Schema::hasColumn('transactions', 'jumlah')) {
                $table->integer('jumlah')->nullable()->after('kategori');
            }

            if (!Schema::hasColumn('transactions', 'tipe')) {
                $table->enum('tipe', ['income', 'expense'])->nullable()->after('jumlah');
            }

            if (!Schema::hasColumn('transactions', 'tanggal')) {
                $table->date('tanggal')->nullable()->after('tipe');
            }

            if (!Schema::hasColumn('transactions', 'updated_at')) {
                $table->timestamp('updated_at')->nullable()->after('created_at');
            }
        });

        if (Schema::hasColumn('transactions', 'type')) {
            DB::table('transactions')->update([
                'tipe' => DB::raw('type'),
            ]);
        }

        if (Schema::hasColumn('transactions', 'amount')) {
            DB::table('transactions')->update([
                'jumlah' => DB::raw('amount'),
            ]);
        }
    }
};
