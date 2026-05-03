import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class MotherHealthEvaluationPage extends StatefulWidget {
  @override
  _MotherHealthEvaluationPageState createState() =>
      _MotherHealthEvaluationPageState();
}

class _MotherHealthEvaluationPageState
    extends State<MotherHealthEvaluationPage> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.12:8000/api/mother-health-reports',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  List<dynamic> reports = [];
  List<dynamic> students = [];
  bool isLoading = true;
  String errorMessage = '';

  // Colors
  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color primaryColor = const Color.fromARGB(255, 17, 100, 151);
  final Color textColor = const Color.fromARGB(255, 252, 247, 232);

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _motherNameController = TextEditingController();
  final _motherAgeController = TextEditingController();
  final _pregnancyWeeksController = TextEditingController();
  final _healthProblemsController = TextEditingController();
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentNationalId;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchStudents();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await _dio.get('/');
      setState(() {
        reports = response.data['data'];
        isLoading = false;
      });
    } on DioError catch (e) {
      setState(() {
        errorMessage = 'فشل في تحميل البيانات. الرجاء المحاولة مرة أخرى.';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await _dio.get('/students/list');
      setState(() {
        students = response.data['data'];
      });
    } on DioError catch (e) {
      setState(() {
        errorMessage = 'فشل في تحميل قائمة الطلاب';
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await _dio.post(
        '/',
        data: {
          'mother_name': _motherNameController.text,
          'mother_age_during_pregnancy': int.parse(_motherAgeController.text),
          'pregnancy_weeks': int.parse(_pregnancyWeeksController.text),
          'health_problems': _healthProblemsController.text,
          'student_id': _selectedStudentId,
        },
      );

      // Clear form and refresh data
      _formKey.currentState!.reset();
      _motherNameController.clear();
      _motherAgeController.clear();
      _pregnancyWeeksController.clear();
      _healthProblemsController.clear();
      _selectedStudentId = null;
      _selectedStudentName = null;
      _selectedStudentNationalId = null;

      _fetchData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم إضافة التقرير بنجاح')));
    } on DioError catch (e) {
      setState(() {
        errorMessage =
            'فشل في إضافة التقرير: ${e.response?.data['message'] ?? 'خطأ غير معروف'}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 4,
          centerTitle: true,
          iconTheme: IconThemeData(color: textColor),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.health_and_safety, size: 28, color: textColor),
              SizedBox(width: 8),
              Text(
                'تقرير صحة الأم',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorMessage.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      SizedBox(height: 20),

                      // Reports Table
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                'التقارير المسجلة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 10),
                            if (reports.isEmpty)
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'لا توجد تقارير مسجلة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor:
                                      MaterialStateColor.resolveWith(
                                        (states) => primaryColor,
                                      ),
                                  headingRowHeight: 50,
                                  dividerThickness: 1.5,
                                  horizontalMargin: 12,
                                  columnSpacing: 20,
                                  border: TableBorder.all(
                                    color: primaryColor,
                                    width: 1.5,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  columns: [
                                    _buildDataColumn('اسم الطالب'),
                                    _buildDataColumn('رقم الهوية'),
                                    _buildDataColumn('اسم الأم'),
                                    _buildDataColumn('المشاكل الصحية'),
                                    _buildDataColumn('أسابيع الحمل'),
                                    _buildDataColumn('عمر الأم أثناء الحمل'),
                                  ],
                                  rows:
                                      reports.map((report) {
                                        final student =
                                            report['student'] as Map?;
                                        final user = student?['user'] as Map?;
                                        return DataRow(
                                          cells: [
                                            _buildDataCell(
                                              user?['name']?.toString() ??
                                                  'غير معروف',
                                            ),
                                            _buildDataCell(
                                              user?['national_id']
                                                      ?.toString() ??
                                                  'غير معروف',
                                            ),
                                            _buildDataCell(
                                              report['mother_name']
                                                      ?.toString() ??
                                                  '—',
                                            ),
                                            _buildDataCell(
                                              report['health_problems']
                                                      ?.toString() ??
                                                  'لا يوجد',
                                            ),
                                            _buildDataCell(
                                              report['pregnancy_weeks']
                                                      ?.toString() ??
                                                  '—',
                                            ),
                                            _buildDataCell(
                                              report['mother_age_during_pregnancy']
                                                      ?.toString() ??
                                                  '—',
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Add New Report Form
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 252, 247, 232),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                'إضافة تقرير جديد',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedStudentId,
                                      decoration: InputDecoration(
                                        labelText: 'الطالب',
                                        labelStyle: TextStyle(
                                          color: primaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      items:
                                          students.map((student) {
                                            return DropdownMenuItem<String>(
                                              value: student['id'].toString(),
                                              child: Text(
                                                '${student['name']} - ${student['national_id']}',
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        final selected = students.firstWhere(
                                          (s) => s['id'].toString() == value,
                                          orElse: () => {},
                                        );
                                        setState(() {
                                          _selectedStudentId = value;
                                          _selectedStudentName =
                                              selected['name'];
                                          _selectedStudentNationalId =
                                              selected['national_id'];
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null)
                                          return 'الرجاء اختيار الطالب';
                                        return null;
                                      },
                                    ),
                                    if (_selectedStudentName != null) ...[
                                      SizedBox(height: 10),
                                      Text(
                                        'الطالب المحدد: $_selectedStudentName',
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.right,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'رقم الهوية: $_selectedStudentNationalId',
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: _motherNameController,
                                      decoration: InputDecoration(
                                        labelText: 'اسم الأم',
                                        labelStyle: TextStyle(
                                          color: primaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال اسم الأم';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: _motherAgeController,
                                      decoration: InputDecoration(
                                        labelText: 'عمر الأم أثناء الحمل',
                                        labelStyle: TextStyle(
                                          color: primaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال عمر الأم';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'الرجاء إدخال رقم صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: _pregnancyWeeksController,
                                      decoration: InputDecoration(
                                        labelText: 'عدد أسابيع الحمل',
                                        labelStyle: TextStyle(
                                          color: primaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال عدد أسابيع الحمل';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'الرجاء إدخال رقم صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: _healthProblemsController,
                                      decoration: InputDecoration(
                                        labelText: 'المشاكل الصحية (إن وجدت)',
                                        labelStyle: TextStyle(
                                          color: primaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      maxLines: 2,
                                    ),
                                    SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: isLoading ? null : _submitForm,
                                      child: Text(
                                        'حفظ التقرير',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 15,
                                          horizontal: 30,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  DataCell _buildDataCell(String value) {
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          value,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _motherNameController.dispose();
    _motherAgeController.dispose();
    _pregnancyWeeksController.dispose();
    _healthProblemsController.dispose();
    super.dispose();
  }
}
