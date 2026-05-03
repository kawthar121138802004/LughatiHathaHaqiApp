<?php

namespace App\Http\Controllers;

use App\Models\MotherHealthReport;
use Illuminate\Http\Request;
use App\Models\Student;
class MotherHealthReportController extends Controller
{
    public function index(Request $request)
{
    $query = MotherHealthReport::with(['student.user']);

    if ($request->has('mother_name')) {
        $query->where('mother_name', 'like', '%' . $request->mother_name . '%');
    }

    if ($request->has('pregnancy_weeks')) {
        $query->where('pregnancy_weeks', $request->pregnancy_weeks);
    }

    if ($request->has('mother_age_during_pregnancy')) {
        $query->where('mother_age_during_pregnancy', $request->mother_age_during_pregnancy);
    }

    if ($request->has('student_id')) {
        $query->where('student_id', $request->student_id);
    }

    $reports = $query->get();

    return response()->json([
        'success' => true,
        'data' => $reports
    ]);
}


   public function store(Request $request)
{


  $validated = $request->validate([
    'mother_name' => 'required|string|max:255',
    'mother_age_during_pregnancy' => 'required|integer|min:15|max:60',
    'pregnancy_weeks' => 'required|integer|min:20|max:45',
    'health_problems' => 'nullable|string',
    'student_id' => 'required|exists:students,id'
]);


    $report = MotherHealthReport::create($validated);
    $report->load('student.user');

    return response()->json([
        'success' => true,
        'message' => 'تم إضافة تقرير صحة الأم بنجاح',
        'data' => $report
    ], 201);
}


    public function getStudents()
    {
        $students = Student::with('user')
            ->select('id', 'user_id')
            ->get()
            ->map(function ($student) {
                return [
                    'id' => $student->id,
                    'name' => $student->user->name,
                    'national_id' => $student->user->national_id
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $students
        ]);
    }


    public function show($id)
{
    $report = MotherHealthReport::with('student.user')->find($id);

    if (!$report) {
        return response()->json([
            'success' => false,
            'message' => 'التقرير غير موجود'
        ], 404);
    }

    return response()->json([
        'success' => true,
        'data' => $report
    ]);
}

}
