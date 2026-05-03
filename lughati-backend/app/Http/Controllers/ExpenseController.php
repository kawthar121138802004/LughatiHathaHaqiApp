<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{   public function index()
{
    try {
        return Expense::all();
    } catch (\Exception $e) {
        return response()->json([
            'error' => 'Database error',
            'details' => $e->getMessage() // Enable only if APP_DEBUG=true
        ], 500);
    }
}
public function store(Request $request)
{
    try {
        $request->validate([
            'expense_type' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0'
        ]);

        $expense = Expense::create([
            'expense_type' => $request->expense_type,
            'amount' => $request->amount
        ]);

        return response()->json([
            'message' => 'تمت إضافة المصروف بنجاح',
            'data' => $expense
        ], 201);
    } catch (\Exception $e) {
        return response()->json([
            'error' => 'فشل في إضافة المصروف',
            'details' => $e->getMessage()
        ], 500);
    }
}
 public function update(Request $request, $id)
{
    try {
        $validated = $request->validate([
            'expense_type' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0'
        ]);

        $expense = Expense::findOrFail($id);
        $expense->update($validated);

        return response()->json($expense);
    } catch (\Illuminate\Validation\ValidationException $e) {
        return response()->json([
            'error' => 'Validation error',
            'messages' => $e->errors()
        ], 422);
    } catch (\Exception $e) {
        return response()->json([
            'error' => 'فشل في تحديث المصروف',
            'details' => $e->getMessage()
        ], 500);
    }
}
    public function destroy($id)
    {
        try {
            $expense = Expense::findOrFail($id);
            $expense->delete();

            return response()->json([
                'message' => 'تم حذف المصروف بنجاح'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'فشل في حذف المصروف',
                'details' => $e->getMessage()
            ], 500);
        }
    }
}
