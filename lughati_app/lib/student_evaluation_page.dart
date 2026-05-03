import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class StudentEvaluationPage extends StatefulWidget {
  final String nationalId;

  const StudentEvaluationPage({super.key, required this.nationalId});

  @override
  State<StudentEvaluationPage> createState() => _StudentEvaluationPageState();
}

class _StudentEvaluationPageState extends State<StudentEvaluationPage> {
  final Dio dio = Dio();
  final String baseUrl =
      'http://192.168.1.12:8000/api'; // غيّر هذا الرابط إذا لزم

  String studentName = '';
  List<dynamic> evaluations = [];
  List<dynamic> sessions = [];
  bool loading = true;
  String? error;

  Future<void> fetchData() async {
    try {
      final response = await dio.get(
        '$baseUrl/parent/student-evaluations/${widget.nationalId}',
      );

      final data = response.data;

      setState(() {
        studentName = data['student_name'];
        evaluations = data['evaluations'];
        sessions = data['sessions'];
        loading = false;
      });
    } on DioError catch (e) {
      setState(() {
        loading = false;
        error = e.response?.data['message'] ?? 'حدث خطأ أثناء جلب البيانات';
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'حدث خطأ غير متوقع';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color.fromARGB(255, 252, 247, 232);
    const Color primaryColor = Color.fromARGB(255, 17, 100, 151);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        title: const Text('تقييم الطالب'),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
              : RefreshIndicator(
                onRefresh: fetchData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'اسم الطالب: $studentName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      '📌 التقييمات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ...evaluations.map(
                      (e) => Card(
                        color: backgroundColor,
                        child: ListTile(
                          title: Text(e['evaluation'] ?? 'لا يوجد تقييم'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      '🗓️ الجلسات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ...sessions.map(
                      (s) => Card(
                        color: backgroundColor,
                        child: ListTile(
                          title: Text(s['session_name']),
                          subtitle: Text(
                            'اليوم: ${s['day']} - ${s['session_time']}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
