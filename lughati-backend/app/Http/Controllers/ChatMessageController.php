<?php

namespace App\Http\Controllers;

use App\Models\ChatMessage;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ChatMessageController extends Controller
{
public function sendMessage(Request $request)
{
    $request->validate([
        'sender_national_id' => 'required|exists:users,national_id',
        'receiver_national_id' => 'required|exists:users,national_id',
        'message' => 'required|string',
    ]);

    // البحث عن المستخدمين حسب رقم الهوية
    $sender = User::where('national_id', $request->sender_national_id)->first();
    $receiver = User::where('national_id', $request->receiver_national_id)->first();

    if (!$sender || !$receiver) {
        return response()->json(['error' => true, 'message' => 'المستخدم المرسل أو المستقبل غير موجود'], 404);
    }

    // تخزين الرسالة
    ChatMessage::create([
        'sender_id' => $sender->id,
        'receiver_id' => $receiver->id,
        'message' => $request->message,
    ]);

    return response()->json(['message' => 'تم الإرسال']);
}
public function getMessages(Request $request)
{
    // التحقق من وجود أرقام الهوية
    $request->validate([
        'sender_national_id' => 'required|exists:users,national_id',
        'receiver_national_id' => 'required|exists:users,national_id',
    ]);

    // البحث عن المستخدمين
    $sender = User::where('national_id', $request->sender_national_id)->first();
    $receiver = User::where('national_id', $request->receiver_national_id)->first();

    if (!$sender || !$receiver) {
        return response()->json([
            'error' => true,
            'message' => 'المستخدم المرسل أو المستقبل غير موجود'
        ], 404);
    }

    // جلب جميع الرسائل بين الطرفين
    $messages = ChatMessage::where(function($query) use ($sender, $receiver) {
        $query->where('sender_id', $sender->id)
              ->where('receiver_id', $receiver->id);
    })->orWhere(function($query) use ($sender, $receiver) {
        $query->where('sender_id', $receiver->id)
              ->where('receiver_id', $sender->id);
    })->with(['sender:id,national_id', 'receiver:id,national_id'])
      ->orderBy('sent_at', 'asc')
      ->get();

    return response()->json([
        'success' => true,
        'messages' => $messages->map(function ($msg) {
            return [
                'id' => $msg->id,
                'message' => $msg->message,
                'from' => $msg->sender->national_id,
                'to' => $msg->receiver->national_id,
                'sent_at' => $msg->sent_at,
            ];
        })
    ]);
}

public function getUnreadSenders($national_id)
{
    $user = User::where('national_id', $national_id)->first();

    if (!$user) {
        return response()->json(['message' => 'User not found'], 404);
    }

    // الرسائل التي استلمها هذا المستخدم
    $receivedMessages = ChatMessage::where('receiver_id', $user->id)->get();

    // الرسائل التي أرسلها هذا المستخدم كردود
    $sentMessages = ChatMessage::where('sender_id', $user->id)->pluck('receiver_id')->toArray();

    // المُرسلون الذين أرسلوا له رسائل ولم يتم الرد عليهم بعد
    $unrepliedSenders = $receivedMessages->filter(function ($msg) use ($sentMessages) {
        return !in_array($msg->sender_id, $sentMessages);
    })->unique('sender_id')->values();

    $result = $unrepliedSenders->map(function ($msg) {
        return [
            'sender_id' => $msg->sender->id,
            'sender_name' => $msg->sender->name,
            'message' => $msg->message,
            'sent_at' => $msg->sent_at,
        ];
    });

    return response()->json([
        'user_name' => $user->name,
        'unreplied_senders' => $result,
    ]);
}
}

