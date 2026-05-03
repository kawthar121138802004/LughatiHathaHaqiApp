<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Teacher extends Model
{
    use HasFactory;


    protected $fillable = [
        'user_id',
        'specialization',
        'salary',
        'phone',
        'address',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
    // app/Models/Teacher.php

public function students()
{
    return $this->hasMany(Student::class);
}

public function sessions()
{
    return $this->hasMany(Session::class);
}

public function homeworks()
{
    return $this->hasMany(Homework::class);
}


}
