import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationsPage extends StatefulWidget {
  final String userType;

  const DonationsPage({Key? key, required this.userType}) : super(key: key);

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  final TextEditingController _accountController = TextEditingController();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.12:8000/api',
      connectTimeout: const Duration(seconds: 5),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final Color backgroundColor = const Color.fromARGB(255, 252, 247, 232);
  final Color primaryColor = const Color.fromARGB(255, 17, 100, 151);

  List<String> _accountNumbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountsFromDatabase();
  }

  Future<void> _loadAccountsFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get('/bank-accounts');
      if (response.statusCode == 200) {
        setState(() {
          _accountNumbers = List<String>.from(
            response.data['data'].map(
              (account) => account['bank_account_number'],
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في جلب الحسابات: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAccountToDatabase(String accountNumber) async {
    try {
      final response = await _dio.post(
        '/bank-accounts',
        data: {'bank_account_number': accountNumber},
      );

      if (response.statusCode == 201) {
        await _loadAccountsFromDatabase();
        _accountController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في حفظ الحساب: ${e.toString()}')),
      );
    }
  }

  Future<void> _openPhoneDialer() async {
    const phoneNumber = 'tel:0123456789';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
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
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.volunteer_activism, size: 26, color: Colors.white),
            SizedBox(width: 8),
            Text('التبرعات', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'لغتي هذا حقي',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'مركز لصعوبات النطق والسمع',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Text(
                  'أرقام الحسابات البنكية:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _accountNumbers.isEmpty
                          ? Center(
                            child: Text(
                              'لا توجد حسابات بعد',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                          : ListView.separated(
                            itemCount: _accountNumbers.length,
                            separatorBuilder: (context, _) => const Divider(),
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: Icon(
                                  Icons.account_balance,
                                  color: primaryColor,
                                ),
                                title: Text(
                                  _accountNumbers[index],
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                const Divider(),
                if (widget.userType == 'manager') ...[
                  TextField(
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'رقم حساب بنكي جديد',
                      labelStyle: TextStyle(color: primaryColor),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ الحساب'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final newAccount = _accountController.text.trim();
                            if (newAccount.isNotEmpty) {
                              _saveAccountToDatabase(newAccount);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
