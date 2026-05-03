<?php

namespace App\Http\Controllers;

use App\Models\ParentProfile;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Student;
use Illuminate\Support\Facades\DB;

class ParentProfileController extends Controller
{
   public function index()
    {
        $parents = ParentProfile::with(['user', 'student.user'])
            ->get()
            ->map(function ($parent) {
                return [
                    'id' => $parent->id,
                    'parent_name' => $parent->user->name,
                    'parent_national_id' => $parent->user->national_id,
                    'phone' => $parent->phone,
                    'job' => $parent->job,
                    'relationship' => $parent->parent_relationship,
                    'adoption_status' => $parent->adoption_status,
                    'address' => $parent->address,
                    'student_name' => $parent->student->user->name,
                    'student_national_id' => $parent->student->user->national_id,
                ];
            });

        return response()->json(['parents' => $parents]);
    }

    /**
     * Store a newly created parent profile
     */
    public function store(Request $request)
    {
        DB::beginTransaction();

        try {
            $validated = $request->validate([
                'parent_name' => 'required|string',
                'parent_national_id' => 'required|unique:users,national_id',
                'phone' => 'required',
                'job' => 'required',
                'relationship' => 'required',
                'adoption_status' => 'required',
                'address' => 'required',
                'student_national_id' => 'required|exists:users,national_id',
            ]);

            // Create user for parent
            $user = User::create([
                'name' => $validated['parent_name'],
                'national_id' => $validated['parent_national_id'],
                'role' => 'parent',
                'password' => bcrypt('password') // Default password, should be changed
            ]);

            // Find student by national ID
            $student = Student::whereHas('user', function($q) use ($validated) {
                $q->where('national_id', $validated['student_national_id']);
            })->firstOrFail();

            // Create parent profile
            $parent = ParentProfile::create([
                'user_id' => $user->id,
                'student_id' => $student->id,
                'phone' => $validated['phone'],
                'job' => $validated['job'],
                'parent_relationship' => $validated['relationship'],
                'adoption_status' => $validated['adoption_status'],
                'address' => $validated['address'],
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Parent profile created successfully',
                'parent' => [
                    'id' => $parent->id,
                    'parent_name' => $user->name,
                    'parent_national_id' => $user->national_id,
                    'student_name' => $student->user->name,
                    'student_national_id' => $student->user->national_id,
                    // Include other fields...
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Failed to create parent profile',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update the specified parent profile
     */
    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'phone' => 'required',
            'job' => 'required',
            'relationship' => 'required',
            'adoption_status' => 'required',
            'address' => 'required',
        ]);

        $parent = ParentProfile::findOrFail($id);
        $parent->update([
            'phone' => $validated['phone'],
            'job' => $validated['job'],
            'parent_relationship' => $validated['relationship'],
            'adoption_status' => $validated['adoption_status'],
            'address' => $validated['address'],
        ]);

        return response()->json([
            'message' => 'Parent profile updated successfully',
            'parent' => $parent
        ]);
    }

    /**
     * Get parent by student national ID
     */
    public function getByStudentNationalId($nationalId)
    {
        $parent = ParentProfile::whereHas('student.user', function($q) use ($nationalId) {
                $q->where('national_id', $nationalId);
            })
            ->with(['user', 'student.user'])
            ->firstOrFail();

        return response()->json([
            'parent' => [
                'id' => $parent->id,
                'parent_name' => $parent->user->name,
                'parent_national_id' => $parent->user->national_id,
                'phone' => $parent->phone,
                'job' => $parent->job,
                'relationship' => $parent->parent_relationship,
                'adoption_status' => $parent->adoption_status,
                'address' => $parent->address,
                'student_name' => $parent->student->user->name,
                'student_national_id' => $parent->student->user->national_id,
            ]
        ]);
    }

    /**
     * Get all student names and national IDs for dropdown
     */
    public function getStudentNames()
    {
        $students = User::whereHas('student')
            ->select('name', 'national_id')
            ->get();

        return response()->json(['students' => $students]);
    }



public function getStudentEvaluations($national_id)
{
    // ابحث عن المستخدم باستخدام national_id بدلاً من find()
    $user = User::where('national_id', $national_id)->first();

    if (!$user || $user->user_type !== 'parent') {
        return response()->json(['error' => 'المستخدم غير مصرح'], 403);
    }

    $parentProfile = $user->parentProfile;
    if (!$parentProfile || !$parentProfile->student_id) {
        return response()->json(['error' => 'لا يوجد طالب مرتبط بهذا المستخدم'], 404);
    }

    $student = Student::with('user')->find($parentProfile->student_id);
    if (!$student) {
        return response()->json(['error' => 'الطالب غير موجود'], 404);
    }

    $evaluations = $student->homeworks()->select('evaluation', 'homework_text')->get();
    $sessions = $student->sessions()->select('session_name', 'session_date', 'session_time', 'day')->get();

    return response()->json([
        'student_name' => $student->user->name,
        'evaluations' => $evaluations,
        'sessions' => $sessions
    ]);
}



}
