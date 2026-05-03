<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class TeacherController extends Controller
{
   public function store(Request $request)
{
    // التحقق من صحة البيانات
    $validator = Validator::make($request->all(), [
        'name' => 'required|string',
        'national_id' => 'required|string|unique:users,national_id',
        // اجعل الحقل اختياريًا
        'specialization' => 'required|string',
        'salary' => 'required|numeric',
        'phone' => 'required|string',
        'address' => 'required|string',
    ]);

    if ($validator->fails()) {
        return response()->json(['errors' => $validator->errors()], 422);
    }

    // 1. إضافة المستخدم إلى جدول users
    $userData = [
        'name' => $request->name,
        'national_id' => $request->national_id,
        'user_type' => 'teacher',
    ];


    $userData['password'] = null; // تعيين الباسوورد إلى null إذا لم يتم توفيره

    $user = User::create($userData);

    // 2. إضافة بيانات المعلمة إلى جدول teachers
    $teacher = Teacher::create([
        'user_id' => $user->id,
        'specialization' => $request->specialization,
        'salary' => $request->salary,
        'phone' => $request->phone,
        'address' => $request->address,
    ]);

    return response()->json([
        'message' => 'تم إضافة المعلمة بنجاح',
        'user' => $user,
        'teacher' => $teacher
    ], 201);
}


public function deleteByNationalId($nationalId)
{
    // ابحث عن المستخدم برقم الهوية
    $user = User::where('national_id', $nationalId)->first();

    if (!$user) {
        return response()->json(['message' => 'المستخدم غير موجود'], 404);
    }

    // تحقق من أن المستخدم هو معلمة
    if ($user->user_type !== 'teacher') {
        return response()->json(['message' => 'هذا المستخدم ليس معلمة'], 400);
    }

    // احذف سجل المعلمة المرتبط بالمستخدم
    $user->teacher()?->delete();

    // احذف المستخدم
    $user->delete();

    return response()->json(['message' => 'تم حذف المعلمة بنجاح']);
}


public function update(Request $request, $national_id)
{
    $request->validate([
        'name' => 'required|string|max:255',
        'specialization' => 'required|string',
        'salary' => 'required|numeric',
        'phone' => 'required|string',
        'address' => 'required|string',
    ]);

    // البحث عن المستخدم حسب رقم الهوية
    $user = User::where('national_id', $national_id)->first();

    if (!$user) {
        return response()->json(['message' => 'المستخدم غير موجود'], 404);
    }

    if ($user->user_type !== 'teacher') {
        return response()->json(['message' => 'هذا المستخدم ليس معلمة'], 400);
    }

    // تحديث بيانات جدول users
    $user->update([
        'name' => $request->name,
    ]);

    // تحديث بيانات جدول teachers
    $teacher = Teacher::where('user_id', $user->id)->first();

    if (!$teacher) {
        return response()->json(['message' => 'سجل المعلمة غير موجود'], 404);
    }

    $teacher->update([
        'specialization' => $request->specialization,
        'salary' => $request->salary,
        'phone' => $request->phone,
        'address' => $request->address,
    ]);

    return response()->json(['message' => 'تم تحديث بيانات المعلمة بنجاح']);
}
public function index()
{
    $teachers = Teacher::with('user')->get();

    $data = $teachers->map(function ($teacher) {
        return [
            'name' => $teacher->user->name,
            'national_id' => $teacher->user->national_id,
            'specialization' => $teacher->specialization,
            'salary' => $teacher->salary,
            'phone' => $teacher->phone,
            'address' => $teacher->address,
        ];
    });

    return response()->json($data);
}


public function getStudentsByNationalId($national_id)
{
    // نحصل على المستخدم الذي يملك هذا الرقم وهو معلمة
    $user = User::where('national_id', $national_id)->where('user_type', 'teacher')->first();

    if (!$user || !$user->teacher) {
        return response()->json(['message' => 'Teacher not found'], 404);
    }

    $teacher = $user->teacher;

    // نجلب الطلاب المرتبطين بالمعلمة
    $students = $teacher->students()->with('user')->get();

    if ($students->isEmpty()) {
        return response()->json(['message' => 'No students found for this teacher.'], 200);
    }

    $data = $students->map(function ($student) {
        return [
            'student_name' => $student->user->name,
            'student_national_id' => $student->user->national_id,
        ];
    });

    return response()->json($data);
}

}
