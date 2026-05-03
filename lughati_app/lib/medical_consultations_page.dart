import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalConsultationsPage extends StatefulWidget {
  final String userType;

  const MedicalConsultationsPage({Key? key, required this.userType})
    : super(key: key);
  @override
  State<MedicalConsultationsPage> createState() =>
      _MedicalConsultationsPageState();
}

class _MedicalConsultationsPageState extends State<MedicalConsultationsPage> {
  List<DoctorInfo> doctors = [];
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.12:8000/api'));

  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color primaryColor = const Color.fromARGB(255, 17, 100, 151);

  @override
  void initState() {
    super.initState();
    fetchDoctors(); // تحميل القائمة عند بدء الصفحة
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await dio.get('/consultations');
      final List data = response.data;
      setState(() {
        doctors = data.map((item) => DoctorInfo.fromJson(item)).toList();
      });
    } catch (e) {
      print('خطأ في تحميل الأطباء: $e');
    }
  }

  Future<void> addDoctor(DoctorInfo doctor) async {
    try {
      final response = await dio.post(
        '/consultations',
        data: {
          'doctor_name': doctor.name,
          'phone': doctor.phoneNumber,
          'clinic_location': doctor.location,
          'specialization': doctor.specialty,
        },
      );

      if (response.statusCode == 201) {
        fetchDoctors(); // تحديث القائمة بعد الإضافة
      }
    } catch (e) {
      print('خطأ في الإضافة: $e');
    }
  }

  void _showAddDoctorDialog() {
    final nameController = TextEditingController();
    final specialtyController = TextEditingController();
    final locationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: backgroundColor,
            title: const Text('إضافة طبيب جديد'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'اسم الطبيب',
                  ),
                  _buildTextField(
                    controller: specialtyController,
                    label: 'التخصص',
                  ),
                  _buildTextField(
                    controller: locationController,
                    label: 'موقع العيادة',
                  ),
                  _buildTextField(
                    controller: phoneController,
                    label: 'رقم الهاتف',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: TextStyle(color: primaryColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  final newDoctor = DoctorInfo(
                    name: nameController.text,
                    specialty: specialtyController.text,
                    location: locationController.text,
                    phoneNumber: phoneController.text,
                  );
                  addDoctor(newDoctor);
                  Navigator.pop(context);
                },
                child: Text('إضافة', style: TextStyle(color: backgroundColor)),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _launchDialer(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الهاتف')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: backgroundColor),
        title: Row(
          children: [
            Icon(Icons.medical_information, color: backgroundColor),
            const SizedBox(width: 8),
            Text('الاستشارات الطبية', style: TextStyle(color: backgroundColor)),
          ],
        ),
        actions: [
          if (widget.userType == 'teacher' ||
              widget.userType == 'manager') // أو 'مديرة' إذا كان هذا هو القيم
            IconButton(
              icon: Icon(Icons.add, color: backgroundColor),
              tooltip: 'إضافة طبيب جديد',
              onPressed: _showAddDoctorDialog,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchDoctors,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              color: backgroundColor,
              child: ListTile(
                title: Text(
                  doctor.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.specialty,
                      style: TextStyle(color: primaryColor),
                    ),
                    Text(
                      'الموقع: ${doctor.location}',
                      style: TextStyle(color: primaryColor),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.phone, color: primaryColor),
                  onPressed: () => _launchDialer(context, doctor.phoneNumber),
                  tooltip: 'اتصال بالطبيب',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DoctorInfo {
  final String name;
  final String specialty;
  final String location;
  final String phoneNumber;

  DoctorInfo({
    required this.name,
    required this.specialty,
    required this.location,
    required this.phoneNumber,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      name: json['doctor_name'],
      specialty: json['specialization'],
      location: json['clinic_location'],
      phoneNumber: json['phone'],
    );
  }
}
