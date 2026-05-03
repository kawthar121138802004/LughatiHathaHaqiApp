<?php
namespace App\Http\Controllers;

use App\Models\Session;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User; 
use Illuminate\Http\Request;

class SessionController extends Controller
{
    public function index() {
    $sessions = Session::withNames()
        ->orderBy('session_date', 'desc')
        ->get();

    return response()->json([
        'sessions' => $sessions->map(function($session) {
            return [
                'id' => $session->id,
                'student_name' => $session->student_name,
                'teacher_name' => $session->teacher_name,
                'session_name' => $session->session_name,
                'session_date' => $session->session_date->format('Y-m-d'),
                'session_time' => $session->session_time,
                'day' => $session->day,
            ];
        })
    ]);
}


    public function store(Request $request) {
    $validated = $request->validate([
        'student_name' => 'required|string',
        'teacher_name' => 'required|string',
        'session_name' => 'required|string',
        'session_date' => 'required|date',
        'session_time' => 'required',
        'day' => 'required|string',
    ]);

    // البحث عن الطالب
    $student = Student::whereHas('user', function($q) use ($request) {
                    $q->where('name', $request->student_name);
                })->firstOrFail();

    // البحث عن المعلمة
    $teacher = Teacher::whereHas('user', function($q) use ($request) {
                    $q->where('name', $request->teacher_name);
                })->firstOrFail();

    $session = Session::create([
        'student_id' => $student->id,
        'teacher_id' => $teacher->id,
        'session_name' => $request->session_name,
        'session_date' => $request->session_date,
        'session_time' => $request->session_time,
        'day' => $request->day,
    ]);

    return response()->json([
        'message' => 'تم إضافة الجلسة بنجاح',
        'session' => [
            'student_name' => $request->student_name,
            'teacher_name' => $request->teacher_name,
            'session_name' => $session->session_name,
            'session_date' => $session->session_date->format('Y-m-d'),
            'session_time' => $session->session_time,
            'day' => $session->day,
        ]
    ], 201);
}

 public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'student_name' => 'required|string',
            'teacher_name' => 'required|string',
            'session_name' => 'required|string',
            'session_date' => 'required|date',
            'session_time' => 'required',
            'day' => 'required|string',
        ]);

        // Find student
        $student = Student::whereHas('user', function($q) use ($request) {
                        $q->where('name', $request->student_name);
                    })->firstOrFail();

        // Find teacher
        $teacher = Teacher::whereHas('user', function($q) use ($request) {
                        $q->where('name', $request->teacher_name);
                    })->firstOrFail();

        $session = Session::findOrFail($id);
        $session->update([
            'student_id' => $student->id,
            'teacher_id' => $teacher->id,
            'session_name' => $request->session_name,
            'session_date' => $request->session_date,
            'session_time' => $request->session_time,
            'day' => $request->day,
        ]);

        return response()->json([
            'id' => $session->id,
            'student_name' => $request->student_name,
            'teacher_name' => $request->teacher_name,
            'session_name' => $session->session_name,
            'session_date' => $session->session_date->format('Y-m-d'),
            'session_time' => $session->session_time,
            'day' => $session->day,
        ]);
    }

    public function destroy($id)
    {
        $session = Session::findOrFail($id);
        $session->delete();

        return response()->json([
            'message' => 'تم حذف الجلسة بنجاح'
        ]);
    }
public function getSessionsByNationalId($national_id)
    {
        // جلب المستخدم بناءً على رقم الهوية
        $user = User::where('national_id', $national_id)->first();

        // تحقق من وجود المستخدم وأنه طالب
        if (!$user || !$user->student) {
            return response()->json([
                'message' => 'Student not found',
            ], 404);
        }

        $student = $user->student;

        // جلب الجلسات الخاصة بالطالب باستخدام scopeWithNames
        $sessions = Session::withNames()
            ->where('sessions.student_id', $student->id)
            ->orderBy('session_date', 'desc')
            ->get();

        return response()->json([
            'student_name' => $user->name,
            'sessions' => $sessions,
        ]);
    }


}
