import 'package:flutter/material.dart';
import 'homeuserpage.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لغتي',
      home: const LoginPage(),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Dio _dio = Dio();

  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    final nationalId = _nationalIdController.text.trim();
    final password = _passwordController.text;

    if (nationalId.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'يرجى إدخال رقم الهوية وكلمة المرور';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _dio.post(
        'http://192.168.1.12:8000/api/login',
        data: {'national_id': nationalId, 'password': password},
      );

      if (response.statusCode == 200) {
        // تسجيل الدخول ناجح
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePageMain(nationalId: nationalId),
          ),
        );
      }
    } on DioError catch (e) {
      setState(() {
        if (e.response != null && e.response?.data != null) {
          _error = e.response?.data['message'] ?? 'حدث خطأ أثناء تسجيل الدخول';
        } else {
          _error = 'تعذر الاتصال بالخادم';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 247, 232),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Image(
                  image: AssetImage('images/lughati_icon.png'),
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  controller: _nationalIdController,
                  label: 'رقم الهوية',
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  obscure: true,
                ),
                const SizedBox(height: 15),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 17, 100, 151),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'تسجيل دخول',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 222, 225, 230),
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A3557),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.12:8000/api', // <-- تأكد من تعديل الـ IP
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<void> completeRegistration() async {
    final nationalId = nationalIdController.text.trim();
    final password = passwordController.text.trim();

    if (nationalId.isEmpty || password.isEmpty) {
      _showMessage("الرجاء تعبئة جميع الحقول");
      return;
    }

    try {
      final response = await dio.post(
        '/complete-registration',
        data: {'national_id': nationalId, 'password': password},
      );

      if (response.statusCode == 200) {
        _showMessage(response.data['message']);

        // الانتقال للصفحة الجديدة مع رقم الهوية
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePageMain(nationalId: nationalId),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        _showMessage(e.response?.data['message'] ?? 'حدث خطأ');
      } else {
        _showMessage('فشل الاتصال بالخادم');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 247, 232),
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: const Color.fromARGB(255, 252, 247, 232),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Image(
                  image: AssetImage('images/lughati_icon.png'),
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: nationalIdController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'رقم الهوية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 17, 100, 151),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'تسجيل',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 222, 225, 230),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
