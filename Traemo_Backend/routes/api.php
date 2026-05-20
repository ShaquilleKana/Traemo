<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\TransactionExportController;

Route::post('/chat', [ChatController::class, 'handle']);
Route::get('/chats', [ChatController::class, 'index']);
Route::delete('/chats/clear', [ChatController::class, 'clear']);
Route::get('/summary', [ChatController::class, 'summary']);
Route::get('/gemini-test', [ChatController::class, 'geminiTest']);
Route::get('/transactions', [TransactionController::class, 'index']);
Route::get('/transactions/export/excel', [TransactionExportController::class, 'excel'])
    ->middleware('api.token');
Route::get('/dashboard-summary', [DashboardController::class, 'summary'])
    ->middleware('api.token');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
