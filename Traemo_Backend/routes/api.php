<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\DashboardController;

Route::post('/chat', [ChatController::class, 'handle']);
Route::get('/chats', [ChatController::class, 'index']);
Route::get('/summary', [ChatController::class, 'summary']);
Route::get('/transactions', [TransactionController::class, 'index']);
Route::get('/dashboard-summary', [DashboardController::class, 'summary']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
