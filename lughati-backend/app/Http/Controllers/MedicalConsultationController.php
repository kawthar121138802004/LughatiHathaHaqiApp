<?php

namespace App\Http\Controllers;

use App\Models\MedicalConsultation;
use Illuminate\Http\Request;

class MedicalConsultationController extends Controller
{
     public function index()
    {
        $doctors = MedicalConsultation::all();
        return response()->json($doctors);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'doctor_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'clinic_location' => 'required|string|max:255',
            'specialization' => 'required|string|max:255',
        ]);

        $doctor = MedicalConsultation::create($validated);

        return response()->json([
            'message' => 'تمت إضافة الطبيب بنجاح!',
            'data' => $doctor
        ], 201);
    }
}
