import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'main.dart';

class UserProfilePage extends StatefulWidget {
  final String nationalId;

  const UserProfilePage({super.key, required this.nationalId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Dio _dio = Dio();

  Future<void> _saveInfo() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await _dio.post(
        'http://192.168.1.12:8000/api/update-user',
        data: {
          'national_id': widget.nationalId,
          'name': name.isNotEmpty ? name : null,
          'password': password.isNotEmpty ? password : null,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ المعلومات بنجاح')));
      }
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ أثناء الحفظ';
      if (e.response != null && e.response!.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _logout() async {
    try {
      final response = await _dio.post('http://192.168.1.12:8000/api/logout');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تسجيل الخروج بنجاح')));

        // الرجوع إلى صفحة تسجيل الدخول (تأكد أن route '/login' موجود)
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
      }
    } on DioException catch (e) {
      String errorMessage = 'فشل في تسجيل الخروج';
      if (e.response != null && e.response!.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 243, 223),
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        backgroundColor: const Color.fromARGB(255, 17, 100, 151),
        foregroundColor: const Color.fromARGB(255, 250, 243, 223),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة السر',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 17, 100, 151),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'حفظ المعلومات',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 250, 243, 223),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 250, 243, 223),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 17, 100, 151),
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
