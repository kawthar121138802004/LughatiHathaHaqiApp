<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Carbon;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'national_id' => 'required',
            'password' => 'required',
        ]);

        $user = User::where('national_id', $request->national_id)->first();

        if (!$user) {
            return response()->json(['message' => 'رقم الهوية غير موجود'], 404);
        }

        if (!$user->password || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'كلمة المرور غير صحيحة'], 401);
        }

        // إنشاء توكن جديد عند تسجيل الدخول
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'تم تسجيل الدخول بنجاح',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user,
        ]);
    }

    // إنشاء حساب وتعيين كلمة مرور
    public function completeRegistration(Request $request)
    {
        $request->validate([
            'national_id' => 'required',
            'password' => 'required|min:6',
        ]);

        $user = User::where('national_id', $request->national_id)->first();

        if (!$user) {
            return response()->json(['message' => 'رقم الهوية غير مسجل'], 404);
        }

        if ($user->password !== null) {
            return response()->json(['message' => 'تم إنشاء كلمة المرور مسبقًا'], 409);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        return response()->json([
            'message' => 'تم تعيين كلمة المرور بنجاح',
            'user' => $user,
        ]);
    }

    public function getUserByNationalId($national_id)
    {
        $user = User::where('national_id', $national_id)->first();

        if (!$user) {
            return response()->json([
                'message' => 'المستخدم غير موجود',
            ], 404);
        }

        return response()->json([
            'message' => 'تم العثور على المستخدم',
            'user' => [
                'name' => $user->name,
                'user_type' => $user->user_type,
            ],
        ]);
    }

    public function updateByNationalId(Request $request)
    {
        $request->validate([
            'national_id' => 'required|string',
            'name' => 'nullable|string',
            'password' => 'nullable|string|min:6',
        ]);

        $user = User::where('national_id', $request->national_id)->first();

        if (!$user) {
            return response()->json(['message' => 'المستخدم غير موجود'], 404);
        }

        if ($request->filled('name')) {
            $user->name = $request->name;
        }

        if ($request->filled('password')) {
            $user->password = Hash::make($request->password);
        }

        $user->save();

        return response()->json(['message' => 'تم تحديث المعلومات بنجاح'], 200);
    }

    public function logout(Request $request)
    {
        // حذف التوكن الحالي فقط
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'تم تسجيل الخروج بنجاح'], 200);
    }









public function getUserType($national_id)
{
    $user = User::where('national_id', $national_id)->first();

    if (!$user) {
        return response()->json(['message' => 'User not found'], 404);
    }

    if ($user->user_type === 'manager') {
        $type = 'manager';
    } elseif ($user->student) {
        $type = 'student';

        $student = $user->student;
        $now = Carbon::today();

        // الجلسة القادمة
        $upcomingSession = $student->sessions()
            ->where('session_date', '>=', $now)
            ->orderBy('session_date', 'asc')
            ->first();

        // الواجبات غير المسلمة
        $unsubmittedHomework = $student->homeworks()
            ->whereNull('submission_text')
            ->whereNull('submission_file')
            ->count();

        return response()->json([
            'user_name' => $user->name,
            'user_type' => $type,
            'has_session' => (bool) $upcomingSession,
            'session_name' => $upcomingSession?->session_name,
            'session_date' => $upcomingSession?->session_date?->toDateString(),
            'has_unsubmitted_homeworks' => $unsubmittedHomework > 0,
            'unsubmitted_homeworks_count' => $unsubmittedHomework,
        ]);

    } elseif ($user->parentProfile) {
        $type = 'parent';

        $student = $user->parentProfile->student;

        if ($student) {
            $now = Carbon::today();

            // الجلسة القادمة
            $upcomingSession = $student->sessions()
                ->where('session_date', '>=', $now)
                ->orderBy('session_date', 'asc')
                ->first();

            // الواجبات غير المسلمة
            $unsubmittedHomework = $student->homeworks()
                ->whereNull('submission_text')
                ->whereNull('submission_file')
                ->count();

            return response()->json([
                'user_name' => $user->name,
                'user_type' => $type,
                'student_name' => $student->user->name,
                'has_session' => (bool) $upcomingSession,
                'session_name' => $upcomingSession?->session_name,
                'session_date' => $upcomingSession?->session_date?->toDateString(),
                'has_unsubmitted_homeworks' => $unsubmittedHomework > 0,
                'unsubmitted_homeworks_count' => $unsubmittedHomework,
            ]);
        } else {
            return response()->json([
                'user_name' => $user->name,
                'user_type' => $type,
                'has_student' => false,
                'message' => 'لا يوجد طالب مرتبط بهذا الحساب',
            ]);
        }
    }

    return response()->json([
        'user_name' => $user->name,
        'user_type' => $user->user_type ?? 'غير معروف',
    ]);
}











}
