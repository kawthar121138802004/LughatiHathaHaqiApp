<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Homework extends Model
{
    use HasFactory;

    // اسم الجدول (اختياري إذا كان الاسم متطابقًا مع plural form)
    protected $table = 'homeworks';

    // الحقول القابلة للتعبئة الجماعية
    protected $fillable = [
        'student_id',
        'teacher_id',
        'homework_text',
        'homework_file',
        'submission_text',
        'submission_file',
        'evaluation',
    ];

    /**
     * علاقة الواجب بالطالب
     */
    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id');
    }

    /**
     * علاقة الواجب بالمعلم
     */
    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id');
    }

    /**
     * رابط الملف الواجب للعرض
     */
    public function getHomeworkFileUrlAttribute()
    {
        return $this->homework_file ? asset('storage/' . $this->homework_file) : null;
    }

    /**
     * رابط ملف التسليم للعرض
     */
    public function getSubmissionFileUrlAttribute()
    {
        return $this->submission_file ? asset('storage/' . $this->submission_file) : null;
    }
}
