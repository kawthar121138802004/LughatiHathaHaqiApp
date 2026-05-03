import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ParentsPage extends StatefulWidget {
  const ParentsPage({Key? key}) : super(key: key);

  @override
  _ParentsPageState createState() => _ParentsPageState();
}

class _ParentsPageState extends State<ParentsPage> {
  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color borderColor = const Color.fromARGB(255, 17, 100, 151);
  final Color headerTextColor = const Color.fromARGB(255, 252, 247, 232);
  final Dio _dio = Dio();
  final String _baseUrl = 'http://192.168.1.12:8000/api';

  List<Map<String, dynamic>> _parentsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParentsData();
  }

  Future<void> _fetchParentsData() async {
    try {
      final response = await _dio.get('$_baseUrl/parents');
      setState(() {
        _parentsData = List<Map<String, dynamic>>.from(
          response.data['parents'],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في جلب بيانات أولياء الأمور: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditParentForm(Map<String, dynamic> parentData) {
    final _formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> controllers = {
      'phone': TextEditingController(
        text: parentData['phone']?.toString() ?? '',
      ),
      'job': TextEditingController(text: parentData['job']?.toString() ?? ''),
      'relationship': TextEditingController(
        text: parentData['relationship']?.toString() ?? '',
      ),
      'adoption_status': TextEditingController(
        text: parentData['adoption_status']?.toString() ?? '',
      ),
      'address': TextEditingController(
        text: parentData['address']?.toString() ?? '',
      ),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعديل بيانات ولي الأمر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  'اسم الطالب',
                  parentData['student_name']?.toString() ?? '',
                ),
                _buildReadOnlyField(
                  'رقم هوية الطالب',
                  parentData['student_national_id']?.toString() ?? '',
                ),
                _buildReadOnlyField(
                  'اسم ولي الأمر',
                  parentData['parent_name']?.toString() ?? '',
                ),
                _buildReadOnlyField(
                  'رقم هوية ولي الأمر',
                  parentData['parent_national_id']?.toString() ?? '',
                ),
                _buildTextField('هاتف ولي الأمر', controllers['phone']!),
                _buildTextField('المهنة', controllers['job']!),
                _buildTextField('صلة القرابة', controllers['relationship']!),
                _buildTextField('حالة التبني', controllers['adoption_status']!),
                _buildTextField('العنوان', controllers['address']!),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: borderColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await _dio.put(
                          '$_baseUrl/parents/${parentData['id']}',
                          data: {
                            'phone': controllers['phone']!.text,
                            'job': controllers['job']!.text,
                            'relationship': controllers['relationship']!.text,
                            'adoption_status':
                                controllers['adoption_status']!.text,
                            'address': controllers['address']!.text,
                          },
                        );
                        Navigator.pop(context);
                        _fetchParentsData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث البيانات بنجاح'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'فشل في تحديث البيانات: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'حفظ التعديلات',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: borderColor),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
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
            Icon(Icons.family_restroom, size: 28, color: backgroundColor),
            const SizedBox(width: 8),
            Text(
              'أولياء الأمور',
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
                                _buildDataColumn('رقم هوية الطالب'),
                                _buildDataColumn('اسم ولي الأمر'),
                                _buildDataColumn('رقم هوية ولي الأمر'),
                                _buildDataColumn('هاتف ولي الأمر'),
                                _buildDataColumn('المهنة'),
                                _buildDataColumn('صلة القرابة'),
                                _buildDataColumn('حالة التبني'),
                                _buildDataColumn('العنوان'),
                                _buildDataColumn('تعديل'),
                              ],
                              rows:
                                  _parentsData.map((parent) {
                                    return DataRow(
                                      cells: [
                                        _buildDataCell(
                                          parent['student_name']?.toString() ??
                                              '',
                                        ),
                                        _buildDataCell(
                                          parent['student_national_id']
                                                  ?.toString() ??
                                              '',
                                        ),
                                        _buildDataCell(
                                          parent['parent_name']?.toString() ??
                                              '',
                                        ),
                                        _buildDataCell(
                                          parent['parent_national_id']
                                                  ?.toString() ??
                                              '',
                                        ),
                                        _buildDataCell(
                                          parent['phone']?.toString() ?? '',
                                        ),
                                        _buildDataCell(
                                          parent['job']?.toString() ?? '',
                                        ),
                                        _buildDataCell(
                                          parent['relationship']?.toString() ??
                                              '',
                                        ),
                                        _buildDataCell(
                                          parent['adoption_status']
                                                  ?.toString() ??
                                              '',
                                        ),
                                        _buildDataCell(
                                          parent['address']?.toString() ?? '',
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: borderColor,
                                            ),
                                            onPressed: () {
                                              _showEditParentForm(parent);
                                            },
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
          ],
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
}
