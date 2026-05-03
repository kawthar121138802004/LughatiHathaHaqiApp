<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\ParentProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentController extends Controller
{


public function storeStudentWithParent(Request $request)
{
    $request->validate([
        'student_name' => 'required|string',
        'student_national_id' => 'required|string|unique:users,national_id',
        'health_issue' => 'required|string',
        'session_type' => 'required|string',
        'age' => 'nullable|integer',
        'birth_date' => 'required|date',
        'registration_date' => 'required|date',
        'fees' => 'required|numeric',

        'teacher_name' => 'required|string',

        'parent_name' => 'required|string',
        'parent_national_id' => 'required|string|unique:users,national_id',
        'phone' => 'required|string',
        'job' => 'nullable|string',
        'parent_relationship' => 'required|string',
        'adoption_status' => 'required|string',
        'address' => 'required|string',
        'siblings_count' => 'required|integer',
    ]);

    try {
        DB::beginTransaction();

        // تحقق من وجود المعلمة
        $teacherUser = User::where('name', $request->teacher_name)->first();
        if (!$teacherUser || !$teacherUser->teacher) {
            return response()->json(['error' => 'المعلمة غير موجودة أو ليس لها سجل كـ Teacher'], 404);
        }

        // إنشاء مستخدم الطالب
        $studentUser = User::create([
            'name' => $request->student_name,
            'national_id' => $request->student_national_id,
            'user_type' => 'student',
            'password' => null,
        ]);

        // إنشاء سجل الطالب
        $student = Student::create([
            'user_id' => $studentUser->id,
            'health_issue' => $request->health_issue,
            'session_type' => $request->session_type,
            'age' => $request->age ?? null,
            'birth_date' => $request->birth_date,
            'registration_date' => $request->registration_date,
            'fees' => $request->fees,
            'is_paid' => 0,
            'teacher_id' => $teacherUser->teacher->id,
        ]);

        // إنشاء مستخدم ولي الأمر
        $parentUser = User::create([
            'name' => $request->parent_name,
            'national_id' => $request->parent_national_id,
            'user_type' => 'parent',
            'password' => null,
        ]);

        // إنشاء سجل ولي الأمر
        $parentProfile = ParentProfile::create([
            'user_id' => $parentUser->id,
            'student_id' => $student->id,
            'phone' => $request->phone,
            'job' => $request->job,
            'parent_relationship' => $request->parent_relationship,
            'adoption_status' => $request->adoption_status,
            'address' => $request->address,
            'siblings_count' => $request->siblings_count,
        ]);

        DB::commit();

        return response()->json(['message' => 'تمت إضافة الطالب وولي الأمر بنجاح'], 201);

    } catch (\Exception $e) {
        DB::rollBack();
        return response()->json([
            'error' => 'حدث خطأ أثناء الإضافة',
            'details' => $e->getMessage()
        ], 500);
    }
}





public function index()
{
    $students = Student::with(['user', 'teacher.user'])->get()->map(function ($student) {
        return [
            'student_name' => $student->user->name,
            'student_national_id' => $student->user->national_id,
            'health_issue' => $student->health_issue,
            'session_type' => $student->session_type,
            'age' => $student->age,
            'birth_date' => $student->birth_date,
            'registration_date' => $student->registration_date,
            'fees' => $student->fees,
            'is_paid' => $student->is_paid,
            'teacher_name' => optional($student->teacher->user)->name, // إذا كان المعلم موجود
        ];
    });

    return response()->json($students);
}




}
