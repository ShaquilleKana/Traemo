<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (!Schema::hasColumn('transactions', 'transaction_category_id')) {
                $table->foreignId('transaction_category_id')
                    ->nullable()
                    ->after('user_id')
                    ->constrained('transaction_categories')
                    ->nullOnDelete();
            }

            if (!Schema::hasColumn('transactions', 'description')) {
                $table->text('description')->nullable()->after('transaction_category_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (Schema::hasColumn('transactions', 'transaction_category_id')) {
                $table->dropForeign(['transaction_category_id']);
                $table->dropColumn('transaction_category_id');
            }

            if (Schema::hasColumn('transactions', 'description')) {
                $table->dropColumn('description');
            }
        });
    }
};
