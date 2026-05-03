<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'health_issue',
        'session_type',
        'teacher_id',
        'age',
        'birth_date',
        'registration_date',
        'fees',
        'is_paid',
    ];


    public function user()
    {
        return $this->belongsTo(User::class);
    }


    public function teacher()
    {
        return $this->belongsTo(Teacher::class);
    }

    public function parentProfile()
{
    return $this->hasOne(ParentProfile::class);
}

public function sessions()
{
    return $this->hasMany(Session::class);
}

 public function motherHealthReport()
    {
        return $this->hasOne(MotherHealthReport::class, 'student_id', 'id');
    }

public function homeworks()
{
    return $this->hasMany(Homework::class);
}


}
