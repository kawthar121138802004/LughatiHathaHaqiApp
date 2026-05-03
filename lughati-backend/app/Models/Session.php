<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Session extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'teacher_id',
        'session_name',
        'session_date',
        'session_time',
        'day'
    ];

    protected $dates = ['session_date'];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function teacher()
    {
        return $this->belongsTo(Teacher::class);
    }
    public function scopeWithNames($query) {
    return $query->join('students', 'sessions.student_id', '=', 'students.id')
                ->join('teachers', 'sessions.teacher_id', '=', 'teachers.id')
                ->join('users as student_users', 'students.user_id', '=', 'student_users.id')
                ->join('users as teacher_users', 'teachers.user_id', '=', 'teacher_users.id')
                ->select(
                    'sessions.*',
                    'student_users.name as student_name',
                    'teacher_users.name as teacher_name'
                );
}
}
