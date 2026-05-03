<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('homeworks', function (Blueprint $table) {
            $table->id();

            // مفاتيح خارجية
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->foreignId('teacher_id')->constrained('teachers')->onDelete('cascade');

            // تفاصيل الواجب
            $table->text('homework_text')->nullable(); // نص الواجب (اختياري)
            $table->string('homework_file')->nullable(); // مسار ملف الواجب

            // تسليم الطالب
            $table->text('submission_text')->nullable(); // نص التسليم
            $table->string('submission_file')->nullable(); // مسار ملف التسليم

            // التقييم
            $table->string('evaluation')->nullable(); // مثل: ممتاز، جيد جداً...

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('homeworks');
    }
};
