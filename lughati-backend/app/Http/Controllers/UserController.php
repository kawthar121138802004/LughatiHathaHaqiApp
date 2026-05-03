<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
class UserController extends Controller
{

  public function index()
    {
        $users = User::select('id', 'name', 'national_id')->get();

        return response()->json([
            'status' => true,
            'users' => $users
        ]);
    }



public function deleteStudentByNationalId($national_id)
{
    // نبحث عن المستخدم حسب رقم الهوية
    $user = User::where('national_id', $national_id)
                ->where('user_type', 'student')
                ->first();

    // إذا ما لقيناه نرجع رسالة خطأ
    if (!$user) {
        return response()->json([
            'status' => false,
            'message' => 'الطالب غير موجود برقم الهوية المُدخل',
        ], 404);
    }

    // نحذف المستخدم – الحذف الكاسكيدي سيحذف الطالب تلقائياً
    $user->delete();

    return response()->json([
        'status' => true,
        'message' => 'تم حذف الطالب بنجاح ',
    ], 200);
}


public function getStudentInfoByNationalId($national_id)
{
    // نبحث عن الطالب حسب رقم الهوية ونجيب العلاقات مع جدول الطلاب وأولياء الأمور
    $user = User::with(['student.parentProfile'])
                ->where('national_id', $national_id)
                ->where('user_type', 'student')
                ->first();

    if (!$user || !$user->student) {
        return response()->json([
            'status' => false,
            'message' => 'الطالب غير موجود أو لم يتم تسجيل بياناته كطالب بعد',
        ], 404);
    }

    // التحقق مما إذا كانت حالة التبني موجودة ومساوية لـ "متبنى"
    $adoptionStatus = $user->student->parentProfile?->adoption_status;
    $isAdopted = $adoptionStatus === 'متبنى'; // أو 'adopted' حسب ما تستخدم

    // تحضير الرسالة وقيمة fees
    $note = null;
    $fees = $user->student->fees;

    if ($isAdopted) {
        $note = 'الطالب متبنى، لا يلزمه دفع القسط.';
        $fees = 0; // يمكن جعل القسط 0 افتراضياً
    }

    return response()->json([
        'status' => true,
        'data' => [
            'name' => $user->name,
            'national_id' => $user->national_id,
            'session_type' => $user->student->session_type,
            'fees' => $fees,
            'note' => $note,
        ],
    ], 200);
}


public function updateStudentByNationalId(Request $request)
{
    $request->validate([
        'national_id' => 'required|string',
        'name' => 'required|string',
        'health_issue' => 'nullable|string',
        'session_type' => 'nullable|string',
        'teacher_name' => 'required|string',
        'age' => 'nullable|integer',
        'birth_date' => 'nullable|date',
        'registration_date' => 'nullable|date',
        'fees' => 'nullable|numeric',
        'is_paid' => 'nullable|boolean',
    ]);

    // 1. البحث عن المستخدم بالرقم الوطني والنوع طالب
    $user = User::where('national_id', $request->national_id)
                ->where('user_type', 'student')
                ->first();

    if (!$user) {
        return response()->json([
            'status' => false,
            'message' => 'الطالب غير موجود',
        ], 404);
    }

    // 2. تحديث الاسم في جدول users
    $user->name = $request->name;
    $user->save();

    // 3. البحث عن المعلمة بالاسم والتأكد من أنها مسجلة كمعلمة
    $teacherUser = User::where('name', $request->teacher_name)
                        ->where('user_type', 'teacher')
                        ->first();

    if (!$teacherUser || !$teacherUser->teacher) {
        return response()->json([
            'status' => false,
            'message' => 'اسم المعلمة غير صحيح أو غير مسجل كمعلمة',
        ], 404);
    }

    $teacherId = $teacherUser->teacher->id;

    // 4. الحصول على سجل الطالب المرتبط
    $student = $user->student;

    if (!$student) {
        return response()->json([
            'status' => false,
            'message' => 'البيانات الخاصة بالطالب غير موجودة',
        ], 404);
    }

    // 5. تحديث بيانات الطالب
    $student->update(array_merge(
        $request->only([
            'health_issue',
            'session_type',
            'age',
            'birth_date',
            'registration_date',
            'fees',
            'is_paid',
        ]),
        ['teacher_id' => $teacherId]
    ));

    return response()->json([
        'status' => true,
        'message' => 'تم تحديث بيانات الطالب بنجاح',
        'student' => $student->fresh(), // استرجاع البيانات بعد التحديث
    ]);
}





}
