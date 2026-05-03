import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({Key? key}) : super(key: key);

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> allStudents = [];
  final TextEditingController searchController = TextEditingController();
  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color borderColor = const Color.fromARGB(255, 17, 100, 151);
  final Color headerTextColor = const Color.fromARGB(255, 252, 247, 232);

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final response = await Dio().get('http://192.168.1.12:8000/api/students');
      final data = response.data as List;

      setState(() {
        allStudents = data.map((student) {
          return {
            'name': student['student_name'],
            'id': student['student_national_id'],
            'sessionType': student['session_type'],
            'age': student['age'].toString(),
            'healthIssues': student['health_issue'] ?? 'لا توجد',
            'birthDate': student['birth_date'],
            'isPaid': student['is_paid'] == 1 ? 'نعم' : 'لا',
            'teacher': student['teacher_name'] ?? 'غير محدد',
          };
        }).toList();

        students = allStudents;
      });
    } catch (e) {
      print('خطأ في جلب الطلاب: $e');
    }
  }

  void filterStudents(String query) {
    final filtered = allStudents.where((student) {
      final name = student['name'].toString();
      final id = student['id'].toString();
      return name.contains(query) || id.contains(query);
    }).toList();

    setState(() {
      students = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: borderColor,
          elevation: 4,
          centerTitle: true,
          iconTheme: IconThemeData(color: backgroundColor),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group, size: 28, color: backgroundColor),
              SizedBox(width: 8),
              Text(
                'طلاب المركز',
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
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الطالب أو رقم الهوية',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: filterStudents,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: borderColor),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddStudentPage()),
                    );

                    if (result == true) {
                      await fetchStudents();
                    }
                  },
                  icon: Icon(Icons.person_add, color: headerTextColor),
                  label: Text(
                    'إضافة طالب جديد',
                    style: TextStyle(color: headerTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
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
                          _buildDataColumn('الاسم'),
                          _buildDataColumn('رقم الهوية'),
                          _buildDataColumn('نوع الجلسات'),
                          _buildDataColumn('العمر'),
                          _buildDataColumn('المشاكل الصحية'),
                          _buildDataColumn('تاريخ الميلاد'),
                          _buildDataColumn('تم الدفع'),
                          _buildDataColumn('المعلم'),
                          _buildDataColumn('خيارات'),
                        ],
                        rows: students.map((student) {
                          return DataRow(
                            cells: [
                              _buildDataCell(student['name']),
                              _buildDataCell(student['id']),
                              _buildDataCell(student['sessionType']),
                              _buildDataCell(student['age']),
                              _buildDataCell(student['healthIssues']),
                              _buildDataCell(student['birthDate']),
                              _buildDataCell(student['isPaid']),
                              _buildDataCell(student['teacher']),
                              _buildActionCell(context, student),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
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

  DataCell _buildActionCell(
    BuildContext context,
    Map<String, dynamic> student,
  ) {
    return DataCell(
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final updatedStudent = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditStudentPage(student: student),
                ),
              );

              if (updatedStudent == true) {
                await fetchStudents();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            tooltip: 'حذف',
            onPressed: () async {
              final nationalId = student['id'];
              try {
                final response = await Dio().delete(
                  'http://192.168.1.12:8000/api/delete-student/$nationalId',
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف الطالب: ${student['name']}'),
                    ),
                  );
                  await fetchStudents();
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('فشل حذف الطالب')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}


// ------------------- EditStudentPage -----------------------

class EditStudentPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const EditStudentPage({Key? key, required this.student}) : super(key: key);

  @override
  _EditStudentPageState createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  late TextEditingController nameController;
  late TextEditingController nationalIdController;
  late TextEditingController sessionTypeController;
  late TextEditingController ageController;
  late TextEditingController healthIssuesController;
  late TextEditingController birthDateController;
  late TextEditingController teacherController;
  late bool isPaid;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student['name']);
    // الرقم الوطني يؤخذ من الطالب الذي تم تمريره للصفحة
    nationalIdController = TextEditingController(text: widget.student['id']);
    sessionTypeController = TextEditingController(
      text: widget.student['sessionType'],
    );
    ageController = TextEditingController(
      text: widget.student['age'].toString(),
    );
    healthIssuesController = TextEditingController(
      text: widget.student['healthIssues'],
    );
    birthDateController = TextEditingController(
      text: widget.student['birthDate'],
    );
    teacherController = TextEditingController(text: widget.student['teacher']);
    isPaid = widget.student['isPaid'] == 'نعم';
  }

  @override
  void dispose() {
    nameController.dispose();
    nationalIdController.dispose();
    sessionTypeController.dispose();
    ageController.dispose();
    healthIssuesController.dispose();
    birthDateController.dispose();
    teacherController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      final response = await Dio().put(
        'http://192.168.1.12:8000/api/update-student',
        data: {
          'national_id': nationalIdController.text,
          'name': nameController.text,
          'session_type': sessionTypeController.text,
          'age': int.tryParse(ageController.text) ?? 0,
          'health_issue': healthIssuesController.text,
          'birth_date': birthDateController.text,
          'is_paid': isPaid ? 1 : 0,
          'teacher_name': teacherController.text,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بيانات الطالب بنجاح')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'فشل في تحديث البيانات'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ أثناء التحديث: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromARGB(255, 252, 247, 232);
    const primaryColor = Color.fromARGB(255, 17, 100, 151);
    const textColor = Color.fromARGB(255, 252, 247, 232);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: textColor),
        title: const Row(
          children: [
            Icon(Icons.edit, color: textColor),
            SizedBox(width: 8),
            Text('تعديل بيانات الطالب', style: TextStyle(color: textColor)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            TextFormField(
              controller: nationalIdController,
              decoration: const InputDecoration(labelText: 'الرقم الوطني'),
              readOnly: true, // لا يمكن تعديل الرقم الوطني
            ),
            TextFormField(
              controller: sessionTypeController,
              decoration: const InputDecoration(labelText: 'نوع الجلسة'),
            ),
            TextFormField(
              controller: ageController,
              decoration: const InputDecoration(labelText: 'العمر'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: healthIssuesController,
              decoration: const InputDecoration(labelText: 'المشاكل الصحية'),
            ),
            TextFormField(
              controller: birthDateController,
              decoration: const InputDecoration(labelText: 'تاريخ الميلاد'),
            ),
            TextFormField(
              controller: teacherController,
              decoration: const InputDecoration(labelText: 'اسم المعلم'),
            ),
            SwitchListTile(
              title: const Text('تم الدفع'),
              value: isPaid,
              onChanged: (value) => setState(() => isPaid = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, color: textColor),
              label: const Text(
                'حفظ التعديلات',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({Key? key}) : super(key: key);

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color buttonColor = const Color.fromARGB(255, 17, 100, 151);

  final Map<String, TextEditingController> controllers = {
    'student_name': TextEditingController(),
    'student_national_id': TextEditingController(),
    'parent_name': TextEditingController(),
    'parent_national_id': TextEditingController(),
    'phone': TextEditingController(),
    'job': TextEditingController(),
    'health_issue': TextEditingController(),
    'session_type': TextEditingController(),
    'birth_date': TextEditingController(),
    'registration_date': TextEditingController(),
    'fees': TextEditingController(),
    'age': TextEditingController(),
    'parent_relationship': TextEditingController(),
    'siblings_count': TextEditingController(),
    'adoption_status': TextEditingController(),
    'address': TextEditingController(),
    'teacher_name': TextEditingController(),
  };

  final Dio dio = Dio();

  Future<void> submitForm() async {
    final data = {
      'student_name': controllers['student_name']!.text.trim(),
      'student_national_id': controllers['student_national_id']!.text.trim(),
      'health_issue': controllers['health_issue']!.text.trim(),
      'session_type': controllers['session_type']!.text.trim(),
      'age': int.tryParse(controllers['age']!.text.trim()) ?? 0,
      'birth_date': controllers['birth_date']!.text.trim(),
      'registration_date': controllers['registration_date']!.text.trim(),
      'fees': double.tryParse(controllers['fees']!.text.trim()) ?? 0.0,

      'teacher_name': controllers['teacher_name']!.text.trim(),

      'parent_name': controllers['parent_name']!.text.trim(),
      'parent_national_id': controllers['parent_national_id']!.text.trim(),
      'phone': controllers['phone']!.text.trim(),
      'job': controllers['job']!.text.trim(),
      'parent_relationship': controllers['parent_relationship']!.text.trim(),
      'adoption_status':
          controllers['adoption_status']!.text
              .trim(), // تأكد أنها "بيولوجي" أو "متبنى"
      'address': controllers['address']!.text.trim(),
      'siblings_count':
          int.tryParse(controllers['siblings_count']!.text.trim()) ?? 0,
    };

    try {
      final response = await dio.post(
        'http://192.168.1.12:8000/api/students/add',
        data: data,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الطالب وولي الأمر بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في الإضافة: ${response.data}')),
        );
      }
    } on DioException catch (e) {
      print('Error: ${e.response?.data}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data['message'] ??
                'حدث خطأ أثناء الإضافة، تحقق من الحقول.',
          ),
        ),
      );
    }
  }

  Widget _buildTextField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controllers[key],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: buttonColor),
          filled: true,
          fillColor: backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: buttonColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: buttonColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: buttonColor,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 252, 247, 232),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_add, color: Color.fromARGB(255, 252, 247, 232)),
            SizedBox(width: 8),
            Text(
              'إضافة طالب جديد',
              style: TextStyle(
                color: Color.fromARGB(255, 252, 247, 232),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField('اسم الطالب', 'student_name'),
              _buildTextField('رقم هوية الطالب', 'student_national_id'),
              _buildTextField('اسم ولي الامر', 'parent_name'),
              _buildTextField('رقم هوية ولي الامر', 'parent_national_id'),
              _buildTextField('هاتف ولي الامر', 'phone'),
              _buildTextField('مهنة ولي الامر', 'job'),
              _buildTextField('المشكلة الصحية', 'health_issue'),
              _buildTextField('نوع الجلسات', 'session_type'),
              _buildTextField('تاريخ الميلاد', 'birth_date'),
              _buildTextField('تاريخ التسجيل', 'registration_date'),
              _buildTextField('القسط', 'fees'),
              _buildTextField('العمر', 'age'),
              _buildTextField('صله القرابة بين الابوين', 'parent_relationship'),
              _buildTextField(
                'عدد الأخوة المسجلين في المركز',
                'siblings_count',
              ),
              _buildTextField(
                'حالة التبني (بيولوجي / متبنى)',
                'adoption_status',
              ),
              _buildTextField('العنوان', 'address'),
              _buildTextField('اسم المعلمه', 'teacher_name'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'حفظ',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
