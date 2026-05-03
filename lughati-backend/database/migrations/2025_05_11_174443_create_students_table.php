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
    public function up(): void
    {
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade'); // علاقة 1-1 مع users
            $table->string('health_issue');
            $table->string('session_type');
            $table->foreignId('teacher_id')->constrained('teachers')->onDelete('cascade'); // علاقة 1-∞ مع teachers
            $table->integer('age');
            $table->date('birth_date');
            $table->date('registration_date');
            $table->decimal('fees', 8, 2);
            $table->boolean('is_paid')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('students');
    }
};
