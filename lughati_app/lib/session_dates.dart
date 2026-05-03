import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SessionDatesPage extends StatefulWidget {
  final String nationalId;

  const SessionDatesPage({super.key, required this.nationalId});

  @override
  State<SessionDatesPage> createState() => _SessionDatesPageState();
}

class _SessionDatesPageState extends State<SessionDatesPage> {
  bool loading = true;
  String? error;
  String? studentName;
  List<dynamic> sessions = [];

  final Dio dio = Dio();
  final String baseUrl =
      'http://192.168.1.12:8000/api'; // غيّر الرابط حسب Laravel API

  @override
  void initState() {
    super.initState();
    fetchSessionsByNationalId(widget.nationalId);
  }

  Future<void> fetchSessionsByNationalId(String nationalId) async {
    try {
      final response = await dio.get('$baseUrl/student-sessions/$nationalId');

      setState(() {
        loading = false;
        studentName = response.data['student_name'];
        sessions = response.data['sessions'];
      });
    } on DioError catch (e) {
      setState(() {
        loading = false;
        error = e.response?.data['message'] ?? 'حدث خطأ أثناء جلب البيانات';
      });
    }
  }

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }

  String formatTime(String timeStr) {
    final parts = timeStr.split(':');
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;

    final isAm = hour < 12;
    final formattedHour =
        hour > 12
            ? hour - 12
            : hour == 0
            ? 12
            : hour;
    final amPm = isAm ? 'صباحاً' : 'مساءً';

    return '${_twoDigits(formattedHour)}:${_twoDigits(minute)} $amPm';
  }

  String _twoDigits(int n) => n < 10 ? '0$n' : '$n';

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromARGB(255, 252, 247, 232);
    const primaryColor = Color.fromARGB(255, 17, 100, 151);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 252, 247, 232),
        ), // لون السهم
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 252, 247, 232), // لون عنوان AppBar
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        title: const Text('مواعيد الجلسات'),
      ),

      body: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(16),
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (studentName != null)
                      Text(
                        'الطالب: $studentName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          sessions.isEmpty
                              ? const Center(
                                child: Text('لا توجد جلسات لهذا الطالب'),
                              )
                              : ListView.builder(
                                itemCount: sessions.length,
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  return Card(
                                    color: backgroundColor,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.event_note,
                                        color: primaryColor,
                                      ),

                                      title: Text(
                                        session['session_name'] ?? '',
                                      ),
                                      subtitle: Text(
                                        '${formatDate(session['session_date'])} - ${formatTime(session['session_time'])}',
                                      ),
                                      trailing: Text(
                                        'المعلمة: ${session['teacher_name'] ?? ''}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}
