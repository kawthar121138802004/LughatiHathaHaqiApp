import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color primaryColor = const Color.fromARGB(255, 17, 100, 151);
  final Color headerTextColor = const Color.fromARGB(255, 252, 247, 232);

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.12:8000/api',
      connectTimeout: const Duration(seconds: 5),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get('/expenses');
      if (response.statusCode == 200) {
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في جلب البيانات: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addExpense(String type, String amount) async {
    try {
      final response = await _dio.post(
        '/expenses',
        data: {'expense_type': type, 'amount': amount},
      );

      if (response.statusCode == 201) {
        await _fetchExpenses();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إضافة المصروف: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateExpense(int id, String type, String amount) async {
    try {
      final response = await _dio.put(
        '/expenses/$id',
        data: {'expense_type': type, 'amount': double.parse(amount)},
      );

      if (response.statusCode == 200) {
        await _fetchExpenses();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحديث المصروف: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteExpense(int id) async {
    try {
      final response = await _dio.delete('/expenses/$id');

      if (response.statusCode == 200) {
        setState(() {
          _expenses.removeWhere((expense) => expense['id'] == id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ تم حذف المصروف')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في حذف المصروف: ${e.toString()}')),
      );
    }
  }

  void _showEditExpenseDialog(Map<String, dynamic> expense) {
    final typeController = TextEditingController(text: expense['expense_type']);
    final amountController = TextEditingController(
      text: expense['amount'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: backgroundColor,
            title: const Text('تعديل المصروف', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: typeController,
                    label: ' نوع المصروف ',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: amountController,
                    label: 'قيمة المصروف',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: TextStyle(color: primaryColor)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  if (typeController.text.isNotEmpty &&
                      amountController.text.isNotEmpty) {
                    Navigator.pop(context);
                    await _updateExpense(
                      expense['id'] as int,
                      typeController.text,
                      amountController.text,
                    );
                  }
                },
                child: const Text(
                  'حفظ التعديلات',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddExpenseDialog() {
    final typeController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: backgroundColor,
            title: const Text('إضافة مصروف جديد', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: typeController,
                    label: ' نوع المصروف ',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: amountController,
                    label: 'قيمة المصروف',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: TextStyle(color: primaryColor)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  if (typeController.text.isNotEmpty &&
                      amountController.text.isNotEmpty) {
                    Navigator.pop(context);
                    await _addExpense(
                      typeController.text,
                      amountController.text,
                    );
                  }
                },
                child: const Text(
                  'إضافة',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('مصاريف المركز'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExpenseDialog,
            tooltip: 'إضافة مصروف جديد',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExpenses,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowHeight: 60,
                            dataRowHeight: 50,
                            dividerThickness: 1.5,
                            horizontalMargin: 20,
                            columnSpacing: 0,
                            border: TableBorder.all(
                              color: primaryColor,
                              width: 1.5,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            columns: [
                              DataColumn(
                                label: Container(
                                  color: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ' نوع المصروف ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: headerTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  color: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ' القيمة ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: headerTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  color: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ' الإجراءات ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: headerTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            rows:
                                _expenses.map((expense) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Center(
                                          child: Text(
                                            expense['expense_type'].toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            expense['amount'].toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed:
                                                  () => _showEditExpenseDialog(
                                                    expense,
                                                  ),
                                              tooltip: 'تعديل',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  () => _deleteExpense(
                                                    expense['id'],
                                                  ),
                                              tooltip: 'حذف',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
