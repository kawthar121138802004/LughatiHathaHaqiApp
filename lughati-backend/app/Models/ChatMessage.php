<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatMessage extends Model
{
    protected $table = 'chat_messages';
    protected $fillable = ['sender_id', 'receiver_id', 'message', 'sent_at'];
    public $timestamps = false; // لأننا نستخدم sent_at كوقت الإرسال

   public function sender()
{
    return $this->belongsTo(User::class, 'sender_id');
}


    public function receiver()
{
    return $this->belongsTo(User::class, 'receiver_id');
}

}
