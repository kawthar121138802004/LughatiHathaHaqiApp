<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\TeacherController;
use App\Http\Controllers\MedicalConsultationController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\DonationController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\HomeworkController;
use App\Http\Controllers\ParentProfileController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\MotherHealthReportController;
use App\Models\User;
use App\Http\Controllers\ChatMessageController;
/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

/*Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});*/
//صفحة تسجيل الدخول
Route::post('/login', [AuthController::class, 'login']);
Route::post('/complete-registration', [AuthController::class, 'completeRegistration']);
//تسجيل خروج
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);


//الصفحة الرئيسه وتعديل البروفايل
Route::get('/user-by-id/{national_id}', [AuthController::class, 'getUserByNationalId']);
Route::post('/update-user', [AuthController::class, 'updateByNationalId']);

//صفحة المعلمات
Route::post('/teachers', [TeacherController::class, 'store']);
Route::delete('/teachers/delete/{nationalId}', [TeacherController::class, 'deleteByNationalId']);
Route::put('/teachers/update/{national_id}', [TeacherController::class, 'update']);
Route::get('/teachers', [TeacherController::class, 'index']);


//الاستشارات الطبيه
Route::get('/consultations', [MedicalConsultationController::class, 'index']);
Route::post('/consultations', [MedicalConsultationController::class, 'store']);
//مصاريف المؤسسه
Route::get('/expenses', [ExpenseController::class, 'index']);
Route::post('/expenses', [ExpenseController::class, 'store']);
Route::put('/expenses/{id}', [ExpenseController::class, 'update']);
Route::delete('/expenses/{id}', [ExpenseController::class, 'destroy']);
//طلاب المركز
Route::post('/students/add', [StudentController::class, 'storeStudentWithParent']);
Route::get('/students', [StudentController::class, 'index']);
Route::delete('/delete-student/{national_id}', [UserController::class, 'deleteStudentByNationalId']);
Route::put('/update-student', [UserController::class, 'updateStudentByNationalId']);


//التبرعات
Route::apiResource('bank-accounts', DonationController::class)->only(['index', 'store']);
// القسط
Route::get('/student-info/{national_id}', [UserController::class, 'getStudentInfoByNationalId']);

//اولياء الامور
Route::get('/parents', [ParentProfileController::class, 'index']);
Route::post('/parents', [ParentProfileController::class, 'store']);
Route::put('/parents/{id}', [ParentProfileController::class, 'update']);
Route::get('/parents/student/{nationalId}', [ParentProfileController::class, 'getByStudentNationalId']);
Route::get('/parents/student-names', [ParentProfileController::class, 'getStudentNames']);
// تقييم صحة الام
Route::group(['prefix' => 'mother-health-reports'], function () {
    Route::get('/', [MotherHealthReportController::class, 'index']); // جميع التقارير
    Route::post('/', [MotherHealthReportController::class, 'store']); // إضافة تقرير
    Route::get('/{id}', [MotherHealthReportController::class, 'show']); // عرض تقرير مفرد
    Route::get('/students/list', [MotherHealthReportController::class, 'getStudents']); // قائمة الطلاب
});



// ارفاق واجب
Route::get('/teacher-students/{national_id}', [TeacherController::class, 'getStudentsByNationalId']);
Route::post('/homeworks/store', [HomeworkController::class, 'storeHomework']);
Route::get('/teacher-homeworks/{national_id}', [HomeworkController::class, 'getHomeworksByTeacher']);
Route::put('/teacher-homeworks/{id}/evaluate', [HomeworkController::class, 'evaluate']);
Route::delete('/teacher-homeworks/{id}', [HomeworkController::class, 'destroy']);


//تسليم الواجبات
Route::get('/student-homeworks/{national_id}', [HomeworkController::class, 'getHomeworksByStudent']);
Route::post('/homeworks/{id}/submit', [HomeworkController::class, 'submitHomework']);
Route::delete('/homeworks/{id}/submission', [HomeworkController::class, 'deleteSubmission']);

// جدول الجلسات
Route::get('/sessions', [SessionController::class, 'index']);
Route::post('/sessions', [SessionController::class, 'store']);
Route::put('/sessions/{id}', [SessionController::class, 'update']);
Route::delete('/sessions/{id}', [SessionController::class, 'destroy']);
    Route::post('/sessions/{id}/notify', [SessionController::class, 'sendNotification']);

Route::get('/students/names', function() {
    $names = User::whereHas('student')->pluck('name');
    return response()->json(['names' => $names]);
});

Route::get('/teachers/names', function() {
    $names = User::whereHas('teacher')->pluck('name');
    return response()->json(['names' => $names]);
});
Route::get('/student-sessions/{national_id}', [SessionController::class, 'getSessionsByNationalId']);

//تقييم الطالب
Route::get('/parent/student-evaluations/{national_id}', [ParentProfileController::class, 'getStudentEvaluations']);

//chat
Route::get('/users', [UserController::class, 'index']);
Route::post('/chat/send', [ChatMessageController::class, 'sendMessage']);
Route::get('/chat/messages', [ChatMessageController::class, 'getMessages']);




//notification
Route::get('/user-type/{national_id}', [AuthController::class, 'getUserType']);
Route::get('/chat/unreplied/{national_id}', [ChatMessageController::class, 'getUnreadSenders']);






