<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:6',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = Str::random(80);
        $user->forceFill(['remember_token' => $token])->save();

        return response()->json([
            'message' => 'Register berhasil',
            'user_id' => $user->id,
            'name' => $user->name,
            'token' => $token,
        ]);
    }

    public function login(Request $request)
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email atau password salah'
            ], 401);
        }

        $token = Str::random(80);
        $user->forceFill(['remember_token' => $token])->save();

        return response()->json([
            'message' => 'Login berhasil',
            'user_id' => $user->id,
            'name' => $user->name,
            'token' => $token,
        ]);
    }
}
