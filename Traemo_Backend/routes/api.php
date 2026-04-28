<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\AuthController;

Route::post('/chat', [ChatController::class, 'handle']);
Route::get('/chats', [ChatController::class, 'index']);
Route::get('/summary', [ChatController::class, 'summary']);
Route::post('/login', [AuthController::class, 'login']);