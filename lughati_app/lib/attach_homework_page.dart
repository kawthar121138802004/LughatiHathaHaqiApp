import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AttachHomeworkPage extends StatefulWidget {
  final String nationalId;

  const AttachHomeworkPage({Key? key, required this.nationalId})
    : super(key: key);

  @override
  State<AttachHomeworkPage> createState() => _AttachHomeworkPageState();
}

class _AttachHomeworkPageState extends State<AttachHomeworkPage> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> homeworks = [];
  bool isLoadingStudents = true;
  bool isLoadingHomeworks = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchHomeworks();
  }

  Future<void> evaluateHomework(int id, String evaluation) async {
    final response = await http.put(
      Uri.parse('http://192.168.1.12:8000/api/teacher-homeworks/$id/evaluate'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'evaluation': evaluation}),
    );

    if (response.statusCode == 200) {
      print('Evaluation saved successfully');
      fetchHomeworks(); 
    } else {
      print('Failed to save evaluation: ${response.body}');
    }
  }

  Future<void> fetchStudents() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.1.12:8000/api/teacher-students/${widget.nationalId}',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final dataList =
            response.data is List ? response.data : response.data['data'];
        setState(() {
          students = List<Map<String, dynamic>>.from(dataList);
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = response.data['message'] ?? 'حدث خطأ';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء جلب الطلاب';
      });
    }
    setState(() => isLoadingStudents = false);
  }

  Future<void> deleteHomework(int id) async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.12:8000/api/teacher-homeworks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('Homework deleted successfully');
    
      fetchHomeworks();
    } else {
      print('Failed to delete homework: ${response.body}');
    }
  }

  Future<void> fetchHomeworks() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.1.12:8000/api/teacher-homeworks/${widget.nationalId}',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          homeworks = List<Map<String, dynamic>>.from(response.data);
          isLoadingHomeworks = false;
        });
      } else {
        setState(() {
          homeworks = [];
          isLoadingHomeworks = false;
        });
      }
    } catch (e) {
      setState(() {
        homeworks = [];
        isLoadingHomeworks = false;
      });
    }
  }

  void _openHomeworkForm(String studentName, String studentNationalId) {
    String? homeworkText;
    File? file;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إرفاق واجب'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الطالب: $studentName'),
                    Text('رقم الهوية: $studentNationalId'),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'الواجب (نص اختياري)',
                      ),
                      onChanged: (value) => homeworkText = value,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB( 255, 17, 100,151,),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'png', 'mp4', 'mov'],
                        );
                        if (result != null) {
                          setState(() {
                            file = File(result.files.single.path!);
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text("إرفاق صورة أو فيديو"),
                    ),
                    if (file != null)
                      Text('تم اختيار الملف: ${file!.path.split('/').last}'),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final dio = Dio();
                final formData = FormData.fromMap({
                  'teacher_national_id': widget.nationalId,
                  'student_national_id': studentNationalId,
                  if (homeworkText != null && homeworkText!.isNotEmpty)
                    'homework_text': homeworkText,
                  if (file != null)
                    'homework_file': await MultipartFile.fromFile(file!.path),
                });

                try {
                  final response = await dio.post(
                    'http://192.168.1.12:8000/api/homeworks/store',
                    data: formData,
                    options: Options(
                      headers: {
                        'Accept': 'application/json',
                        'Content-Type': 'multipart/form-data',
                      },
                    ),
                  );

                  if (response.statusCode == 201) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم إرسال الواجب بنجاح")),
                    );
                    fetchHomeworks(); 
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "فشل في إرسال الواجب: ${response.data['message']}",
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("خطأ في الاتصال بالخادم: $e")),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeworkCell(String? text, String? fileUrl) {
    List<Widget> widgets = [];
    if (text != null && text.isNotEmpty) {
      widgets.add(Text(text));
    }
    if (fileUrl != null) {
      final isImage = fileUrl.endsWith('.jpg') || fileUrl.endsWith('.png');
      final isVideo = fileUrl.endsWith('.mp4') || fileUrl.endsWith('.mov');

      widgets.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FileViewerPage(fileUrl: fileUrl),
              ),
            );
          },
          child:
              isImage
                  ? Image.network(fileUrl, height: 50, width: 50)
                  : const Text(
                    'عرض الملف',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 247, 232),
      appBar: AppBar(
        title: const Text('إرفاق الواجبات'),
        backgroundColor: const Color.fromARGB(255, 17, 100, 151),
        foregroundColor: Color.fromARGB(255, 252, 247, 232),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      title: Text(student['student_name'] ?? ''),
                      subtitle: Text(
                        'رقم الهوية: ${student['student_national_id'] ?? ''}',
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            17,
                            100,
                            151,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            () => _openHomeworkForm(
                              student['student_name'] ?? '',
                              student['student_national_id'] ?? '',
                            ),
                        child: const Text('إرفاق واجب'),
                      ),
                    );
                  },
                ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'الواجبات المرسلة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 17, 100, 151),
                ),
              ),
            ),

            isLoadingHomeworks
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color.fromARGB(
                        255,
                        17,
                        100,
                        151,
                      ), 
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'الرقم',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'اسم الطالب',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'الهوية',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'الواجب',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'التسليم',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'التقييم',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'إجراءات',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    rows:
                        homeworks.map((hw) {
                          return DataRow(
                            cells: [
                              DataCell(Text(hw['id'].toString())),
                              DataCell(Text(hw['student_name'] ?? '')),
                              DataCell(Text(hw['student_national_id'] ?? '')),
                              DataCell(
                                _buildHomeworkCell(
                                  hw['homework_text'],
                                  hw['homework_file_url'],
                                ),
                              ),
                              DataCell(
                                _buildHomeworkCell(
                                  hw['submission_text'],
                                  hw['submission_file_url'],
                                ),
                              ),
                              DataCell(
                                Text(hw['evaluation']?.toString() ?? ''),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () async {
                                        final TextEditingController
                                        _evalController =
                                            TextEditingController();
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'إدخال التقييم',
                                                ),
                                                content: TextField(
                                                  controller: _evalController,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText:
                                                            'أدخل التقييم هنا',
                                                      ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ), // إلغاء
                                                    child: const Text('إلغاء'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          _evalController.text,
                                                        ), // حفظ
                                                    child: const Text('حفظ'),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (result != null &&
                                            result.isNotEmpty) {
                                          await evaluateHomework(
                                            hw['id'],
                                            result,
                                          );
                                        }
                                      },
                                    ),

                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'تأكيد الحذف',
                                                ),
                                                content: const Text(
                                                  'هل أنت متأكد من حذف هذا الواجب؟',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('إلغاء'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text('حذف'),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirm == true) {
                                          await deleteHomework(hw['id']);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class FileViewerPage extends StatelessWidget {
  final String fileUrl;

  const FileViewerPage({Key? key, required this.fileUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isImage = fileUrl.endsWith('.jpg') || fileUrl.endsWith('.png');
    final isVideo = fileUrl.endsWith('.mp4') || fileUrl.endsWith('.mov');

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 247, 232),
      appBar: AppBar(
        title: const Text(
          "عرض الملف",
          style: TextStyle(color: Color.fromARGB(255, 17, 100, 151)),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 17, 100, 151),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child:
            isImage
                ? InteractiveViewer(child: Image.network(fileUrl))
                : isVideo
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "لفتح الفيديو اضغط على الزر أدناه",
                      style: TextStyle(
                        color: Color.fromARGB(255, 17, 100, 151),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        launchUrl(
                          Uri.parse(fileUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Color.fromARGB(255, 252, 247, 232),
                      ),
                      label: const Text(
                        "تشغيل الفيديو",
                        style: TextStyle(
                          color: Color.fromARGB(255, 252, 247, 232),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          17,
                          100,
                          151,
                        ),
                      ),
                    ),
                  ],
                )
                : const Text(
                  "نوع الملف غير مدعوم للعرض",
                  style: TextStyle(color: Color.fromARGB(255, 17, 100, 151)),
                ),
      ),
    );
  }
}
