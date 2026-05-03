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
    Schema::create('mother_health_reports', function (Blueprint $table) {
        $table->id();
        $table->string('mother_name');
        $table->integer('mother_age_during_pregnancy');
        $table->integer('pregnancy_weeks');
        $table->text('health_problems')->nullable();
        $table->unsignedBigInteger('student_id')->unique();
        $table->timestamps();

        // ربط المفتاح الأجنبي بجدول الطلاب
        $table->foreign('student_id')->references('id')->on('students')->onDelete('cascade');
    });
}


    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('mother_health_reports');
    }
};
