<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ChatController;

Route::post('/chat', [ChatController::class, 'handle']);
Route::get('/chats', [ChatController::class, 'index']);
Route::get('/summary', [ChatController::class, 'summary']);