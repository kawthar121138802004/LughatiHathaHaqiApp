import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  _EmployeesPageState createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final Color backgroundColor = Color.fromARGB(255, 252, 247, 232);
  final Color borderColor = Color.fromARGB(255, 17, 100, 151);
  final Color headerTextColor = Color.fromARGB(255, 252, 247, 232);

  List<Map<String, dynamic>> teachers = [];
  final Dio _dio = Dio(
      BaseOptions(
        baseUrl: 'http://192.168.1.12:8000/api',
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 3),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    )
    ..interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _dio.get('/teachers');
      if (response.statusCode == 200) {
        setState(() {
          teachers = List<Map<String, dynamic>>.from(response.data);
          isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load teachers: Status ${response.statusCode}',
        );
      }
    } on DioError catch (e) {
      setState(() {
        errorMessage =
            'Failed to load teachers: ${e.response?.data['message'] ?? e.message}';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load teachers: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _addTeacher(Map<String, dynamic> teacherData) async {
    try {
      final response = await _dio.post(
        '/teachers',
        data: {
          'name': teacherData['name'],
          'national_id': teacherData['id'],
          'specialization': teacherData['specialization'],
          'salary': teacherData['salary'],
          'phone': teacherData['phone'],
          'address': teacherData['address'],
          'password': 'defaultPassword123', // Required by your Laravel API
        },
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 201) {
        await _fetchTeachers();
      } else if (response.data != null && response.data['errors'] != null) {
        final errors = response.data['errors'] as Map<String, dynamic>;
        final errorMessage = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(', ')}')
            .join('\n');
        throw Exception(errorMessage);
      } else {
        throw Exception('Failed to add teacher: ${response.statusMessage}');
      }
    } on DioError catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw Exception('Failed to add teacher: ${e.toString()}');
    }
  }

  Future<void> _updateTeacher(
    String nationalId,
    Map<String, dynamic> teacherData,
  ) async {
    try {
      final response = await _dio.put(
        '/teachers/update/$nationalId',
        data: {
          'name': teacherData['name'],
          'specialization': teacherData['specialization'],
          'salary': teacherData['salary'],
          'phone': teacherData['phone'],
          'address': teacherData['address'],
        },
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200) {
        await _fetchTeachers();
      } else if (response.data != null && response.data['errors'] != null) {
        final errors = response.data['errors'] as Map<String, dynamic>;
        final errorMessage = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(', ')}')
            .join('\n');
        throw Exception(errorMessage);
      } else {
        throw Exception('Failed to update teacher: ${response.statusMessage}');
      }
    } on DioError catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw Exception('Failed to update teacher: ${e.toString()}');
    }
  }

  Future<void> _deleteTeacher(String nationalId) async {
    try {
      final response = await _dio.delete(
        '/teachers/delete/$nationalId',
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200) {
        await _fetchTeachers();
      } else {
        throw Exception('Failed to delete teacher: ${response.statusMessage}');
      }
    } on DioError catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw Exception('Failed to delete teacher: ${e.toString()}');
    }
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
                'المعلمات',
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
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: borderColor,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddTeacherPage(
                              onAddTeacher: _addTeacher,
                              backgroundColor: backgroundColor,
                              buttonColor: borderColor,
                            ),
                      ),
                    ).then((_) => _fetchTeachers());
                  },
                  icon: Icon(
                    Icons.person_add,
                    color: Color.fromARGB(255, 252, 247, 232),
                    size: 20,
                  ),
                  label: Text(
                    'اضافة معلمة',
                    style: TextStyle(
                      color: Color.fromARGB(255, 252, 247, 232),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    isLoading
                        ? Center(
                          child: CircularProgressIndicator(color: borderColor),
                        )
                        : errorMessage != null
                        ? Center(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              teachers.isEmpty
                                  ? Center(
                                    child: Text(
                                      'لا يوجد معلمات مسجلات',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: DataTable(
                                        headingRowColor:
                                            MaterialStateColor.resolveWith(
                                              (states) => borderColor,
                                            ),
                                        headingRowHeight: 60,
                                        dividerThickness: 1.5,
                                        horizontalMargin: 12,
                                        columnSpacing: 20,
                                        border: TableBorder.all(
                                          color: borderColor,
                                          width: 1.5,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        columns: [
                                          _buildDataColumn('اسم المعلمة'),
                                          _buildDataColumn('رقم الهوية'),
                                          _buildDataColumn('الاختصاص'),
                                          _buildDataColumn('الراتب'),
                                          _buildDataColumn('رقم الهاتف'),
                                          _buildDataColumn('العنوان'),
                                          _buildDataColumn('خيارات'),
                                        ],
                                        rows:
                                            teachers.map((teacher) {
                                              return DataRow(
                                                cells: [
                                                  _buildDataCell(
                                                    teacher['name'] ?? '',
                                                  ),
                                                  _buildDataCell(
                                                    teacher['national_id'] ??
                                                        '',
                                                  ),
                                                  _buildDataCell(
                                                    teacher['specialization'] ??
                                                        '',
                                                  ),
                                                  _buildDataCell(
                                                    teacher['salary']
                                                            ?.toString() ??
                                                        '',
                                                  ),
                                                  _buildDataCell(
                                                    teacher['phone'] ?? '',
                                                  ),
                                                  _buildDataCell(
                                                    teacher['address'] ?? '',
                                                  ),
                                                  _buildActionCell(
                                                    context,
                                                    teacher,
                                                  ),
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
    Map<String, dynamic> teacher,
  ) {
    return DataCell(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: const Color.fromARGB(255, 17, 100, 151),
              size: 20,
            ),
            tooltip: 'تعديل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => EditTeacherPage(
                        teacher: teacher,
                        onUpdateTeacher: _updateTeacher,
                        backgroundColor: backgroundColor,
                        buttonColor: borderColor,
                      ),
                ),
              ).then((_) => _fetchTeachers());
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red, size: 20),
            tooltip: 'حذف',
            onPressed: () async {
              final confirmed = await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('تأكيد الحذف'),
                      content: Text(
                        'هل أنت متأكد من حذف المعلمة ${teacher['name']}؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'حذف',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                try {
                  await _deleteTeacher(teacher['national_id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف المعلمة بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل في حذف المعلمة: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class AddTeacherPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddTeacher;
  final Color backgroundColor;
  final Color buttonColor;

  const AddTeacherPage({
    Key? key,
    required this.onAddTeacher,
    required this.backgroundColor,
    required this.buttonColor,
  }) : super(key: key);

  @override
  _AddTeacherPageState createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _specializationController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.buttonColor,
          iconTheme: IconThemeData(color: Color.fromARGB(255, 252, 247, 232)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, color: Color.fromARGB(255, 252, 247, 232)),
              SizedBox(width: 8),
              Text(
                'إضافة معلمة جديدة',
                style: TextStyle(
                  color: Color.fromARGB(255, 252, 247, 232),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: widget.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(
                    'اسم المعلمة',
                    _nameController,
                    isRequired: true,
                  ),
                  _buildTextField(
                    'رقم هوية المعلمة',
                    _idController,
                    isRequired: true,
                    isNumber: true,
                  ),
                  _buildTextField(
                    'الاختصاص',
                    _specializationController,
                    isRequired: true,
                  ),
                  _buildTextField(
                    'الراتب',
                    _salaryController,
                    isRequired: true,
                    isNumber: true,
                  ),
                  _buildTextField(
                    'رقم الهاتف',
                    _phoneController,
                    isRequired: true,
                    isPhone: true,
                  ),
                  _buildTextField(
                    'العنوان',
                    _addressController,
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final teacherData = {
                          'name': _nameController.text,
                          'id': _idController.text,
                          'specialization': _specializationController.text,
                          'salary': _salaryController.text,
                          'phone': _phoneController.text,
                          'address': _addressController.text,
                        };

                        try {
                          await widget.onAddTeacher(teacherData);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تمت إضافة المعلمة بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.buttonColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'حفظ',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    bool isNumber = false,
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: widget.buttonColor),
          filled: true,
          fillColor: Color.fromARGB(255, 252, 247, 232),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: widget.buttonColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: widget.buttonColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          if (isPhone && value != null && value.length < 10) {
            return 'يجب أن يكون رقم الهاتف صحيحًا';
          }
          return null;
        },
      ),
    );
  }
}

class EditTeacherPage extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final Function(String, Map<String, dynamic>) onUpdateTeacher;
  final Color backgroundColor;
  final Color buttonColor;

  const EditTeacherPage({
    Key? key,
    required this.teacher,
    required this.onUpdateTeacher,
    required this.backgroundColor,
    required this.buttonColor,
  }) : super(key: key);

  @override
  _EditTeacherPageState createState() => _EditTeacherPageState();
}

class _EditTeacherPageState extends State<EditTeacherPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _specializationController;
  late final TextEditingController _salaryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher['name']);
    _idController = TextEditingController(text: widget.teacher['national_id']);
    _specializationController = TextEditingController(
      text: widget.teacher['specialization'],
    );
    _salaryController = TextEditingController(
      text: widget.teacher['salary']?.toString() ?? '',
    );
    _phoneController = TextEditingController(text: widget.teacher['phone']);
    _addressController = TextEditingController(text: widget.teacher['address']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _specializationController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedTeacher = {
        'name': _nameController.text,
        'national_id': _idController.text,
        'specialization': _specializationController.text,
        'salary': _salaryController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      };

      try {
        await widget.onUpdateTeacher(
          widget.teacher['national_id'],
          updatedTeacher,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث بيانات المعلمة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في التحديث: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: widget.backgroundColor,
        appBar: AppBar(
          backgroundColor: widget.buttonColor,
          iconTheme: IconThemeData(color: Color.fromARGB(255, 252, 247, 232)),
          title: Row(
            children: [
              Icon(Icons.edit, color: Color.fromARGB(255, 252, 247, 232)),
              SizedBox(width: 8),
              Text(
                'تعديل بيانات المعلمة',
                style: TextStyle(color: Color.fromARGB(255, 252, 247, 232)),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(
                    'اسم المعلمة',
                    _nameController,
                    isRequired: true,
                  ),
                  _buildTextField('رقم الهوية', _idController, enabled: false),
                  _buildTextField(
                    'الاختصاص',
                    _specializationController,
                    isRequired: true,
                  ),
                  _buildTextField(
                    'الراتب',
                    _salaryController,
                    isRequired: true,
                    isNumber: true,
                  ),
                  _buildTextField(
                    'رقم الهاتف',
                    _phoneController,
                    isRequired: true,
                    isPhone: true,
                  ),
                  _buildTextField(
                    'العنوان',
                    _addressController,
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.buttonColor,
                      foregroundColor: Color.fromARGB(255, 252, 247, 232),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveChanges,
                    child: Text('حفظ التعديلات'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    bool isNumber = false,
    bool isPhone = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: widget.buttonColor),
          filled: true,
          fillColor: Color.fromARGB(255, 252, 247, 232),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: widget.buttonColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: widget.buttonColor, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          if (isPhone && value != null && value.length < 10) {
            return 'يجب أن يكون رقم الهاتف صحيحًا';
          }
          return null;
        },
      ),
    );
  }
}
