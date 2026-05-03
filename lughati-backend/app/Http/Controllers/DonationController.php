<?php

namespace App\Http\Controllers;

use App\Models\Donation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class DonationController extends Controller
{
  public function index()
    {
        $accounts = Donation::all();
        return response()->json([
            'success' => true,
            'data' => $accounts
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'bank_account_number' => 'required|string|unique:donations,bank_account_number'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $account = Donation::create([
            'bank_account_number' => $request->bank_account_number
        ]);

        return response()->json([
            'success' => true,
            'data' => $account
        ], 201);
    }
}
