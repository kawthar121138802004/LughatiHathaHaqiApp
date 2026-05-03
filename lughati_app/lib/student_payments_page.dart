import 'package:flutter/material.dart';

class StudentPaymentsPage extends StatelessWidget {
  const StudentPaymentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أقساط الطلبة')),
      body: const Center(child: Text('متابعة أقساط الطلبة')),
    );
  }
}