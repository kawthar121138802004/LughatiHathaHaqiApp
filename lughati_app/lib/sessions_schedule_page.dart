import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SessionsSchedulePage extends StatefulWidget {
  final String userType;
  final String nationalId;

  const SessionsSchedulePage({
    super.key,
    required this.userType,
    required this.nationalId,
  });

  @override
  State<SessionsSchedulePage> createState() => _SessionsSchedulePageState();
}

class _SessionsSchedulePageState extends State<SessionsSchedulePage> {
  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color borderColor = const Color.fromARGB(255, 17, 100, 151);
  final Color headerTextColor = const Color.fromARGB(255, 252, 247, 232);
  final Dio _dio = Dio();
  final String _baseUrl = 'http://192.168.1.12:8000/api';

  List<Map<String, dynamic>> _sessionsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      final response = await _dio.get('$_baseUrl/sessions');
      setState(() {
        _sessionsData = List<Map<String, dynamic>>.from(
          response.data['sessions'],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch sessions: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotification(int sessionId) async {
    try {
      final response = await _dio.post('$_baseUrl/sessions/$sessionId/notify');
      final data = response.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📩 تم إرسال تنبيه لـ ${data['student_name']} بموعد الجلسة: ${data['session_date']} - ${data['session_time']}',
          ),
          backgroundColor: borderColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addSession(Map<String, dynamic> sessionData) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/sessions',
        data: sessionData,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

      setState(() {
        _sessionsData.add({
          'id': response.data['id'],
          'student_name': sessionData['student_name'],
          'teacher_name': sessionData['teacher_name'],
          'session_name': sessionData['session_name'],
          'session_date': sessionData['session_date'],
          'session_time': sessionData['session_time'],
          'day': sessionData['day'],
        });
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تم إضافة الجلسة')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add session: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print(e);
    }
  }

  Future<void> _updateSession(int id, Map<String, dynamic> updatedData) async {
    try {
      await _dio.put('$_baseUrl/sessions/$id', data: updatedData);

      setState(() {
        int index = _sessionsData.indexWhere((session) => session['id'] == id);
        if (index != -1) {
          _sessionsData[index] = {..._sessionsData[index], ...updatedData};
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تم تحديث الجلسة')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update session: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSession(int id) async {
    try {
      await _dio.delete('$_baseUrl/sessions/$id');

      setState(() {
        _sessionsData.removeWhere((session) => session['id'] == id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تم حذف الجلسة')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete session: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddSessionForm() {
    String studentName = '';
    String teacherName = '';
    String sessionName = '';
    String sessionDate = '';
    String sessionTime = '';
    String day = '';

    List<String> studentNames = [];
    List<String> teacherNames = [];

    final _formKey = GlobalKey<FormState>();

    Future<void> _fetchNames() async {
      try {
        final students = await _dio.get('$_baseUrl/students/names');
        final teachers = await _dio.get('$_baseUrl/teachers/names');
        setState(() {
          studentNames = List<String>.from(students.data['names']);
          teacherNames = List<String>.from(teachers.data['names']);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في جلب الأسماء: ${e.toString()}')),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder(
              future: _fetchNames(),
              builder: (context, snapshot) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'إضافة جلسة جديدة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Student name field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Autocomplete<String>(
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                return studentNames.where((String option) {
                                  return option.contains(textEditingValue.text);
                                });
                              },
                              onSelected: (String selection) {
                                studentName = selection;
                              },
                              fieldViewBuilder: (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'اسم الطالب',
                                    labelStyle: TextStyle(color: borderColor),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'هذا الحقل مطلوب'
                                              : null,
                                );
                              },
                            ),
                          ),

                          // Teacher name field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Autocomplete<String>(
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                return teacherNames.where((String option) {
                                  return option.contains(textEditingValue.text);
                                });
                              },
                              onSelected: (String selection) {
                                teacherName = selection;
                              },
                              fieldViewBuilder: (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'اسم المعلمة',
                                    labelStyle: TextStyle(color: borderColor),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'هذا الحقل مطلوب'
                                              : null,
                                );
                              },
                            ),
                          ),

                          // Other fields
                          _buildTextField(
                            'اسم الجلسة',
                            (val) => sessionName = val,
                          ),
                          _buildTextField(
                            'تاريخ الجلسة (YYYY-MM-DD)',
                            (val) => sessionDate = val,
                          ),
                          _buildTextField(
                            'وقت الجلسة',
                            (val) => sessionTime = val,
                          ),
                          _buildTextField('اليوم', (val) => day = val),

                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: borderColor,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                _addSession({
                                  'student_name': studentName,
                                  'teacher_name': teacherName,
                                  'session_name': sessionName,
                                  'session_date': sessionDate,
                                  'session_time': sessionTime,
                                  'day': day,
                                });
                              }
                            },
                            child: const Text(
                              'حفظ الجلسة',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditSessionForm(Map<String, dynamic> session) {
    String studentName = session['student_name'] ?? '';
    String teacherName = session['teacher_name'] ?? '';
    String sessionName = session['session_name'] ?? '';
    String sessionDate = session['session_date'] ?? '';
    String sessionTime = session['session_time'] ?? '';
    String day = session['day'] ?? '';

    List<String> studentNames = [];
    List<String> teacherNames = [];

    final _formKey = GlobalKey<FormState>();

    Future<void> _fetchNames() async {
      try {
        final students = await _dio.get('$_baseUrl/students/names');
        final teachers = await _dio.get('$_baseUrl/teachers/names');
        setState(() {
          studentNames = List<String>.from(students.data['names']);
          teacherNames = List<String>.from(teachers.data['names']);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في جلب الأسماء: ${e.toString()}')),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder(
              future: _fetchNames(),
              builder: (context, snapshot) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'تعديل الجلسة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Student name field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Autocomplete<String>(
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                return studentNames.where((String option) {
                                  return option.contains(textEditingValue.text);
                                });
                              },
                              onSelected: (String selection) {
                                studentName = selection;
                              },
                              fieldViewBuilder: (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                textEditingController.text = studentName;
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'اسم الطالب',
                                    labelStyle: TextStyle(color: borderColor),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'هذا الحقل مطلوب'
                                              : null,
                                );
                              },
                            ),
                          ),

                          // Teacher name field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Autocomplete<String>(
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                return teacherNames.where((String option) {
                                  return option.contains(textEditingValue.text);
                                });
                              },
                              onSelected: (String selection) {
                                teacherName = selection;
                              },
                              fieldViewBuilder: (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                textEditingController.text = teacherName;
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'اسم المعلمة',
                                    labelStyle: TextStyle(color: borderColor),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'هذا الحقل مطلوب'
                                              : null,
                                );
                              },
                            ),
                          ),

                          // Other fields
                          _buildTextField(
                            'اسم الجلسة',
                            (val) => sessionName = val,
                            initialValue: sessionName,
                          ),
                          _buildTextField(
                            'تاريخ الجلسة (YYYY-MM-DD)',
                            (val) => sessionDate = val,
                            initialValue: sessionDate,
                          ),
                          _buildTextField(
                            'وقت الجلسة',
                            (val) => sessionTime = val,
                            initialValue: sessionTime,
                          ),
                          _buildTextField(
                            'اليوم',
                            (val) => day = val,
                            initialValue: day,
                          ),

                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: borderColor,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                _updateSession(session['id'], {
                                  'student_name': studentName,
                                  'teacher_name': teacherName,
                                  'session_name': sessionName,
                                  'session_date': sessionDate,
                                  'session_time': sessionTime,
                                  'day': day,
                                });
                              }
                            },
                            child: const Text(
                              'حفظ التعديلات',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    String? initialValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: borderColor),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: borderColor,
        elevation: 4,
        iconTheme: IconThemeData(color: backgroundColor),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 28, color: backgroundColor),
            const SizedBox(width: 8),
            Text(
              'جدول الجلسات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: backgroundColor,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.userType == 'manager' ||
                widget.userType == 'teacher') ...[
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => borderColor,
                                ),
                                headingRowHeight: 60,
                                dividerThickness: 1.5,
                                horizontalMargin: 12,
                                columnSpacing: 20,
                                border: TableBorder.all(
                                  color: borderColor,
                                  width: 1.5,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                columns: [
                                  _buildDataColumn('اسم الطالب'),
                                  _buildDataColumn('اسم الأخصائية'),
                                  _buildDataColumn('اسم الجلسة'),
                                  _buildDataColumn('تاريخ الجلسة'),
                                  _buildDataColumn('وقت الجلسة'),
                                  _buildDataColumn('اليوم'),
                                  _buildDataColumn('الإجراءات'),
                                ],
                                rows:
                                    _sessionsData.map((session) {
                                      return DataRow(
                                        cells: [
                                          _buildDataCell(
                                            session['student_name'] ?? '',
                                          ),
                                          _buildDataCell(
                                            session['teacher_name'] ?? '',
                                          ),
                                          _buildDataCell(
                                            session['session_name'] ?? '',
                                          ),
                                          _buildDataCell(
                                            session['session_date'] ?? '',
                                          ),
                                          _buildDataCell(
                                            session['session_time'] ?? '',
                                          ),
                                          _buildDataCell(session['day'] ?? ''),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          _showEditSessionForm(
                                                            session,
                                                          ),
                                                  tooltip: 'تعديل',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => _deleteSession(
                                                        session['id'],
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
                        ),
              ),
            ] else ...[
              const Center(
                child: Text(
                  'ليس لديك صلاحية لعرض الجلسات.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton:
          (widget.userType == 'teacher')
              ? FloatingActionButton(
                backgroundColor: borderColor,
                onPressed: _showAddSessionForm,
                foregroundColor: const Color.fromARGB(255, 252, 247, 232),
                tooltip: 'إضافة جلسة',
                child: const Icon(Icons.add),
              )
              : null,
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
            color: headerTextColor,
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
}
