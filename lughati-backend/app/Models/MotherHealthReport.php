<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MotherHealthReport extends Model
{
    protected $table = 'mother_health_reports';

    protected $fillable = [
        'mother_name',
        'mother_age_during_pregnancy',
        'pregnancy_weeks',
        'health_problems',
        'student_id',
    ];

    // علاقة عكسية مع الطالب (belongsTo لأن MotherHealthReport تابع لطالب)
    public function student()
{
    return $this->belongsTo(Student::class);
}

}

