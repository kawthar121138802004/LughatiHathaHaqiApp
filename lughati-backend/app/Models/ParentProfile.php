<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ParentProfile extends Model
{
    use HasFactory;
  protected $fillable = [
        'user_id',
        'phone',
        'job',
        'parent_relationship',
        'adoption_status',
        'address',
        'student_id',
        'siblings_count'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function student()
    {
        return $this->belongsTo(Student::class);
    }
       public function motherHealthReport()
    {
        return $this->hasOne(MotherHealthReport::class, 'parent_id');
    }
}
