<?php

namespace App\Http\Controllers;

use App\Models\TransactionCategory;
use Illuminate\Http\JsonResponse;

class TransactionCategoryController extends Controller
{
    public function index(): JsonResponse
    {
        $categories = TransactionCategory::query()
            ->select(['id', 'name', 'type'])
            ->orderBy('type')
            ->orderBy('name')
            ->get();

        return response()->json($categories);
    }
}
