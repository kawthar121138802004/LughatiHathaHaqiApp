<?php

namespace App\Http\Controllers;

use App\Models\Homework;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class HomeworkController extends Controller
{
    public function storeHomework(Request $request)
{
    $request->validate([
        'teacher_national_id' => 'required|exists:users,national_id',
        'student_national_id' => 'required|exists:users,national_id',
        'homework_text' => 'nullable|string',
        'homework_file' => 'nullable|file|mimes:jpg,jpeg,png,mp4,mov,avi|max:10240',
    ]);

    $teacherUser = User::where('national_id', $request->teacher_national_id)->first();
    $studentUser = User::where('national_id', $request->student_national_id)->first();

    $teacher = $teacherUser->teacher;
    $student = $studentUser->student;

    if (!$teacher || !$student) {
        return response()->json(['message' => 'Teacher or Student not found'], 404);
    }

    $homeworkFilePath = null;

    if ($request->hasFile('homework_file')) {
        $extension = $request->file('homework_file')->getClientOriginalExtension();
        $filename = uniqid('hw_') . '.' . $extension;
        // سيتم تخزين الملف داخل storage/app/public/homeworks
        $homeworkFilePath = $request->file('homework_file')->storeAs('homeworks', $filename, 'public');
    }

    $homework = Homework::create([
        'teacher_id' => $teacher->id,
        'student_id' => $student->id,
        'homework_text' => $request->homework_text,
        'homework_file' => $homeworkFilePath, // هذا يجب أن يكون 'homeworks/filename.jpg'
    ]);

    return response()->json([
        'message' => 'Homework created successfully',
        'homework' => $homework,
    ], 201);
}


 public function getHomeworksByTeacher($teacher_national_id)
{
    try {
        // Step 1: البحث عن المستخدم بالرقم الوطني
        $teacher = User::where('national_id', $teacher_national_id)
                       ->where('user_type', 'teacher')
                       ->first();

        if (!$teacher) {
            return response()->json([
                'message' => 'User not found or not a teacher',
                'code' => 1
            ], 404);
        }

        // Step 2: التأكد من أن لديه سجل في جدول المعلمين
        if (!$teacher->teacher) {
            return response()->json([
                'message' => 'User exists but not linked as teacher (no teacher record)',
                'code' => 2
            ], 404);
        }

        // Step 3: جلب الواجبات
        $homeworks = Homework::where('teacher_id', $teacher->teacher->id)
                             ->with(['student.user'])
                             ->orderBy('created_at', 'asc')
                             ->get();

        if ($homeworks->isEmpty()) {
            return response()->json([
                'message' => 'No homeworks found for this teacher',
                'code' => 3
            ], 200);
        }

        // Step 4: تجهيز البيانات
        $data = $homeworks->map(function ($hw) {
    return [
        'id' => $hw->id,
        'student_name' => $hw->student->user->name ?? 'N/A',
        'student_national_id' => $hw->student->user->national_id ?? 'N/A',
        'homework_text' => $hw->homework_text,
        'homework_file_url' => $hw->homework_file
            ? asset('storage/homeworks/' . basename($hw->homework_file))
            : null,
        'submission_text' => $hw->submission_text,
        'submission_file_url' => $hw->submission_file
            ? asset('storage/submissions/' . basename($hw->submission_file))
            : null,
        'evaluation' => $hw->evaluation,
    ];
});


        return response()->json($data);

    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Unexpected error occurred',
            'error' => $e->getMessage(),
            'line' => $e->getLine(),
            'file' => $e->getFile()
        ], 500);
    }
}





public function evaluate(Request $request, $id)
{
    $request->validate([
        'evaluation' => 'nullable|string',
    ]);

    $homework = Homework::find($id);
    if (!$homework) {
        return response()->json(['message' => 'Homework not found'], 404);
    }

    $evaluation = trim($request->input('evaluation'));

    if ($evaluation) {
        // نضيف التقييم على نفس السطر بعد المحتوى الحالي
        $homework->evaluation.= " " . $evaluation;
    }

    $homework->save();

    return response()->json(['message' => 'Evaluation saved successfully']);
}



   public function destroy($id)
{
    $homework = Homework::find($id);
    if (!$homework) {
        return response()->json(['message' => 'Homework not found'], 404);
    }
    if ($homework->homework_file) {
    Storage::disk('public')->delete($homework->homework_file);
}
if ($homework->submission_file) {
    Storage::disk('public')->delete($homework->submission_file);
}


    $homework->delete();
    return response()->json(['message' => 'Homework deleted successfully']);
}








//التسليم
public function getHomeworksByStudent($student_national_id)
{
    $student = User::where('national_id', $student_national_id)
                   ->where('user_type', 'student')
                   ->first();

    if (!$student || !$student->student) {
        return response()->json(['message' => 'Student not found.'], 404);
    }

    $homeworks = Homework::where('student_id', $student->student->id)
                         ->with(['teacher.user'])
                         ->orderBy('created_at', 'desc')
                         ->get();

    $data = $homeworks->map(function ($hw) {
        return [
            'id' => $hw->id,
            'teacher_name' => $hw->teacher->user->name ?? 'N/A',
            'homework_text' => $hw->homework_text,
            'homework_file_url' => $hw->homework_file
                    ? url('storage/' . $hw->homework_file)
                    : null,
            'submission_text' => $hw->submission_text,
            'submission_file_url' => $hw->submission_file ? asset('storage/' . $hw->submission_file) : null,
            'evaluation' => $hw->evaluation,
        ];
    });

    return response()->json($data);
}

public function submitHomework(Request $request, $id)
{
    $request->validate([
        'student_national_id' => 'required|exists:users,national_id',
        'submission_text' => 'nullable|string',
        'submission_file' => 'nullable|file|mimes:jpg,jpeg,png,mp4,mov,avi|max:10240',
    ]);

    $homework = Homework::find($id);
    if (!$homework) {
        return response()->json(['message' => 'Homework not found'], 404);
    }

    $studentUser = User::where('national_id', $request->student_national_id)->first();
    if (!$studentUser || $homework->student_id != $studentUser->student->id) {
        return response()->json(['message' => 'Unauthorized submission'], 403);
    }

    // حذف الملف القديم إذا موجود
    if ($homework->submission_file) {
        Storage::disk('public')->delete($homework->submission_file);
    }

    $submissionFilePath = null;

    if ($request->hasFile('submission_file')) {
        $extension = $request->file('submission_file')->getClientOriginalExtension();
        $filename = uniqid('submission_') . '.' . $extension;
        $submissionFilePath = $request->file('submission_file')->storeAs('submissions', $filename, 'public');
    }

    $homework->update([
        'submission_text' => $request->submission_text,
        'submission_file' => $submissionFilePath,
    ]);

    return response()->json(['message' => 'Homework submitted successfully']);
}


public function deleteSubmission($id)
{
    $homework = Homework::find($id);
    if (!$homework) {
        return response()->json(['message' => 'Homework not found'], 404);
    }

    if ($homework->submission_file) {
        Storage::disk('public')->delete($homework->submission_file);
    }

    $homework->update([
        'submission_text' => null,
        'submission_file' => null,
    ]);

    return response()->json(['message' => 'Submission deleted successfully']);
}


}
