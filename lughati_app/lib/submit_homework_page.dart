import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SubmitHomeworkPage extends StatefulWidget {
  final String nationalId;

  const SubmitHomeworkPage({Key? key, required this.nationalId})
    : super(key: key);

  @override
  State<SubmitHomeworkPage> createState() => _SubmitHomeworkPageState();
}

class _SubmitHomeworkPageState extends State<SubmitHomeworkPage> {
  List<Map<String, dynamic>> homeworks = [];
  bool isLoadingHomeworks = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchHomeworks();
  }

  Future<void> fetchHomeworks() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.1.12:8000/api/student-homeworks/${widget.nationalId}',
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
          errorMessage =
              response.data['message'] ?? 'حدث خطأ أثناء جلب الواجبات';
        });
      }
    } catch (e) {
      setState(() {
        homeworks = [];
        isLoadingHomeworks = false;
        errorMessage = 'حدث خطأ أثناء جلب الواجبات';
      });
    }
  }

  Future<void> submitHomework(
    int id,
    String? submissionText,
    File? file,
  ) async {
    final dio = Dio();
    final formData = FormData.fromMap({
      'student_national_id': widget.nationalId,
      if (submissionText != null && submissionText.isNotEmpty)
        'submission_text': submissionText,
      if (file != null)
        'submission_file': await MultipartFile.fromFile(file.path),
    });

    try {
      final response = await dio.post(
        'http://192.168.1.12:8000/api/homeworks/$id/submit',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم تسليم الواجب بنجاح")));
        fetchHomeworks(); // تحديث قائمة الواجبات بعد التسليم
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل في تسليم الواجب: ${response.data['message']}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ في الاتصال بالخادم: $e")));
    }
  }

  Future<void> deleteSubmission(int id) async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.12:8000/api/homeworks/$id/submission'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم حذف التسليم بنجاح")));
      fetchHomeworks(); // تحديث قائمة الواجبات بعد الحذف
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في حذف التسليم: ${response.body}")),
      );
    }
  }

  void _openSubmissionForm(int homeworkId) {
    String? submissionText;
    File? file;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تسليم الواجب'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'الحل (نص اختياري)',
                      ),
                      onChanged: (value) => submissionText = value,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          17,
                          100,
                          151,
                        ),
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
                await submitHomework(homeworkId, submissionText, file);
                Navigator.pop(context);
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
        title: const Text('تسليم الواجبات'),
        backgroundColor: const Color.fromARGB(255, 17, 100, 151),
        foregroundColor: const Color.fromARGB(255, 252, 247, 232),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'الواجبات المطلوبة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 17, 100, 151),
                ),
              ),
            ),
            isLoadingHomeworks
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 17, 100, 151),
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
                          'الواجب',
                          style: TextStyle(
                            color: Color.fromARGB(255, 252, 247, 232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'تسليمك',
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
                                Text(
                                  hw['evaluation']?.toString() ??
                                      'لم يتم التقييم بعد',
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    if (hw['submission_text'] == null &&
                                        hw['submission_file_url'] == null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.green,
                                        ),
                                        onPressed:
                                            () => _openSubmissionForm(hw['id']),
                                      ),
                                    if (hw['submission_text'] != null ||
                                        hw['submission_file_url'] != null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed:
                                            () => _openSubmissionForm(hw['id']),
                                      ),
                                    if (hw['submission_text'] != null ||
                                        hw['submission_file_url'] != null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'تأكيد الحذف',
                                                  ),
                                                  content: const Text(
                                                    'هل أنت متأكد من حذف التسليم؟',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'إلغاء',
                                                      ),
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
                                            await deleteSubmission(hw['id']);
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
