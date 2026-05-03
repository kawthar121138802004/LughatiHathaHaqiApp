<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
public function up()
{
    Schema::create('parent_profiles', function (Blueprint $table) {
        $table->id();

        $table->unsignedBigInteger('user_id'); // FK لجدول users
        $table->string('phone');
        $table->string('job')->nullable();
        $table->string('parent_relationship'); // صلة القرابة بين الأبوين
        $table->string('adoption_status'); // حالة التبني
        $table->string('address');
        $table->unsignedBigInteger('student_id'); // FK لجدول الطلاب

        $table->integer('siblings_count')->default(0); // عدد الإخوة المسجلين بالمركز

        $table->timestamps();

        // العلاقات
        $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        $table->foreign('student_id')->references('id')->on('students')->onDelete('cascade');

        // نضمن أن العلاقة مع كل طالب ومستخدم تكون واحد لواحد
        $table->unique('user_id');
        $table->unique('student_id');
    });
}




    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('parent_profiles');
    }
};
