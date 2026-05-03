import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PaymentPage extends StatefulWidget {
  final String nationalId;

  const PaymentPage({Key? key, required this.nationalId}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? errorMessage;

  final Color mainColor = const Color.fromARGB(255, 17, 100, 151);
  final Color lightBackground = const Color.fromARGB(255, 252, 247, 232);

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.1.12:8000/api/student-info/${widget.nationalId}',
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        setState(() {
          studentData = response.data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.data['message'] ?? 'حدث خطأ غير معروف';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'فشل في الاتصال بالخادم';
        isLoading = false;
      });
    }
  }

  void _printInvoice(BuildContext context) async {
    if (studentData == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'لغتي هذا حقي',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'مركز لصعوبات النطق والسمع',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
              pw.Text('اسم الطالب: ${studentData!['name']}'),
              pw.SizedBox(height: 10),
              pw.Text('رقم الهوية: ${studentData!['national_id']}'),
              pw.SizedBox(height: 10),
              pw.Text('نوع الجلسات: ${studentData!['session_type']}'),
              pw.SizedBox(height: 10),
              pw.Text(
                'المبلغ: ${NumberFormat('#,##0.00').format(studentData!['fees'])} ريال',
              ),
              if (studentData!['note'] != null) ...[
                pw.SizedBox(height: 10),
                pw.Text('ملاحظة: ${studentData!['note']}'),
              ],
            ],
          );
        },
      ),
    );

    // معاينة و/أو طباعة
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.payment),
            SizedBox(width: 8),
            Text('دفع القسط'),
          ],
        ),
        backgroundColor: mainColor,
        foregroundColor: lightBackground,
      ),
      backgroundColor: mainColor,
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : errorMessage != null
              ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 4,
                  color: lightBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'لغتي هذا حقي',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'مركز لصعوبات النطق والسمع',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                        Text('اسم الطالب: ${studentData!['name']}'),
                        const SizedBox(height: 10),
                        Text('رقم الهوية: ${studentData!['national_id']}'),
                        const SizedBox(height: 10),
                        Text('نوع الجلسات: ${studentData!['session_type']}'),
                        const SizedBox(height: 10),
                        Text(
                          'المبلغ: ${NumberFormat('#,##0.00').format(studentData!['fees'])} ريال',
                        ),
                        if (studentData!['note'] != null) ...[
                          const SizedBox(height: 10),
                          Text('ملاحظة: ${studentData!['note']}'),
                        ],
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: lightBackground,
                            ),
                            icon: const Icon(Icons.print, color: Colors.white),
                            label: const Text('طباعة الفاتورة'),
                            onPressed: () => _printInvoice(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
