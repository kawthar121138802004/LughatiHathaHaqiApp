<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        $user = $request->user();

        // غيّر role لـ user_type هنا
        if (! $user || ! in_array($user->user_type, $roles)) {
            return response()->json(['message' => 'غير مصرح لك بالدخول'], 403);
        }

        return $next($request);
    }
}
