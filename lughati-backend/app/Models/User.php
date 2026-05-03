<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'national_id',
        'user_type',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];
    public function teacher()
{
    return $this->hasOne(Teacher::class);
}


public function student()
{
    return $this->hasOne(Student::class);
}
public function parentProfile()
{
    return $this->hasOne(ParentProfile::class);
}


public function sentMessages()
{
    return $this->hasMany(ChatMessage::class, 'sender_id');
}

public function receivedMessages()
{
    return $this->hasMany(ChatMessage::class, 'receiver_id');
}


}
