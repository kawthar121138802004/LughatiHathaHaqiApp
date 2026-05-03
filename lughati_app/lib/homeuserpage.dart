import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lughati_app/session_dates.dart';
import 'package:lughati_app/student_evaluation_page.dart';
import 'userprofile.dart';
import 'donations_page.dart';
import 'students_page.dart';
import 'parents_page.dart';
import 'mother_health_evaluation_page.dart';
import 'employees_page.dart';
import 'institution_expenses_page.dart';
import 'sessions_schedule_page.dart';
import 'attach_homework_page.dart';
import 'submit_homework_page.dart';
import 'payment_page.dart';
import 'medical_consultations_page.dart';
import 'package:lughati_app/nameslist.dart';

class HomePageMain extends StatefulWidget {
  final String nationalId;

  const HomePageMain({super.key, required this.nationalId});

  @override
  State<HomePageMain> createState() => _HomePageMainState();
}

class _HomePageMainState extends State<HomePageMain> {
  int _currentIndex = 0;
  int unsubmittedCount = 0;
  int unreadSendersCount = 0;
  List<Map<String, dynamic>> unreadSenders = [];
bool hasSession = false;
String? sessionDate;
String? studentName;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? userName;
  String? userType;





  @override
  void initState() {
    super.initState();
    fetchUserData(widget.nationalId);
  }

 Future<void> fetchUserData(String nationalId) async {
  try {
    final dio = Dio();
    final resp1 = await dio.get(
      'http://192.168.1.12:8000/api/user-type/$nationalId',
    );
    if (resp1.statusCode == 200) {
      final data = resp1.data;
      setState(() {
        userName = data['user_name'];
        userType = data['user_type'];
        unsubmittedCount = data['unsubmitted_homeworks_count'] ?? 0;
        hasSession = data['has_session'] ?? false;
        sessionDate = data['session_date'];
        studentName = data['student_name']; 
      });
    }
    final resp2 = await dio.get(
      'http://192.168.1.12:8000/api/chat/unreplied/$nationalId',
    );
    if (resp2.statusCode == 200) {
      final list = resp2.data['unreplied_senders'] as List;
      setState(() {
        unreadSenders = List<Map<String, dynamic>>.from(list);
        unreadSendersCount = unreadSenders.length;
      });
    }
  } catch (e) {
    showError("حدث خطأ أثناء الاتصال بالخادم");
  }
}


  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NamesList(nationalId: widget.nationalId),
        ),
      );
    } else if (index == 2) {
      _scaffoldKey.currentState?.openDrawer();
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(nationalId: widget.nationalId),
        ),
      ).then((_) => fetchUserData(widget.nationalId));
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  bool hasPermission(List<String> roles) {
    return roles.contains(userType);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(255, 252, 247, 232),
        drawer: Drawer(
          backgroundColor: const Color.fromARGB(255, 252, 247, 232),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 100,
                color: const Color.fromARGB(255, 252, 247, 232),
                child: Center(
                  child: Image.asset('images/lughati_icon.png', height: 60),
                ),
              ),
              if (hasPermission(['manager']))
                _buildDrawerItem(
                  Icons.group,
                  'طلاب المركز',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudentsPage()),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['manager', 'teacher']))
                _buildDrawerItem(
                  Icons.family_restroom,
                  'أولياء الأمور',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParentsPage()),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['manager']))
                _buildDrawerItem(
                  Icons.medical_services,
                  'تقرير صحة الأم',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MotherHealthEvaluationPage(),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['manager']))
                _buildDrawerItem(
                  Icons.people,
                  'الموظفين',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EmployeesPage()),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['manager']))
                _buildDrawerItem(
                  Icons.attach_money,
                  'مصاريف المركز',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpensesPage()),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['manager', 'teacher']))
                _buildDrawerItem(
                  Icons.calendar_today,
                  'جدول الجلسات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SessionsSchedulePage(
                              userType: userType ?? '',
                              nationalId: widget.nationalId,
                            ),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['student']))
                _buildDrawerItem(
                  Icons.calendar_today,
                  'مواعيد الجلسات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                SessionDatesPage(nationalId: widget.nationalId),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['manager', 'teacher', 'student', 'parent']))
                _buildDrawerItem(
                  Icons.volunteer_activism,
                  'التبرعات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DonationsPage(userType: userType ?? ''),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['teacher']))
                _buildDrawerItem(
                  Icons.assignment,
                  'ارفاق واجب',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AttachHomeworkPage(
                              nationalId: widget.nationalId,
                            ),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['student']))
                _buildDrawerItem(
                  Icons.assignment_turned_in,
                  'تسليم الواجبات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SubmitHomeworkPage(
                              nationalId: widget.nationalId,
                            ),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['student']))
                _buildDrawerItem(
                  Icons.payment,
                  'دفع القسط',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PaymentPage(nationalId: widget.nationalId),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['manager', 'teacher', 'student', 'parent']))
                _buildDrawerItem(
                  Icons.medical_information,
                  'استشارات طبية',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MedicalConsultationsPage(
                              userType: userType ?? '',
                            ),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
              if (hasPermission(['parent']))
                _buildDrawerItem(
                  Icons.assessment,
                  'تقييم الطالب',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => StudentEvaluationPage(
                              nationalId: widget.nationalId,
                            ),
                      ),
                    ).then((_) => fetchUserData(widget.nationalId));
                  },
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('images/lughati_icon.png', height: 190),
              const SizedBox(height: 10),
              const Text(
                'مركز لصعوبات النطق والسمع',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'اسم المستخدم: ${userName ?? 'جارٍ التحميل...'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 6, 84, 172),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color.fromARGB(255, 252, 247, 232),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Color.fromARGB(255, 221, 250, 0),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'الإشعارات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 252, 247, 232),
    borderRadius: BorderRadius.circular(10),
  ),
  child: (unreadSendersCount > 0 || unsubmittedCount > 0 || hasSession)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSession)
              Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userType == 'student'
                          ? '📅 لديك جلسة في $sessionDate'
                          : '📅 لدى ابنك جلسة في $sessionDate',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            if (hasSession) const SizedBox(height: 10),
            if (unsubmittedCount > 0)
              Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '📚 لديك $unsubmittedCount واجب غير مسلّم',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            if (unreadSendersCount > 0) const SizedBox(height: 10),
            if (unreadSenders.isNotEmpty) ...[
             
              const SizedBox(height: 5),
              ...unreadSenders.map((sender) => Padding(
                    padding: const EdgeInsets.only(left: 10.0, top: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            'رسالة من ${sender['sender_name']}: ${sender['message']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ]
          ],
        )
      : const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'لا توجد إشعارات حالياً.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
),


                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 17, 100, 151),
              borderRadius: BorderRadius.circular(12),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color.fromARGB(255, 196, 212, 235),
              unselectedItemColor: const Color.fromARGB(255, 228, 239, 227),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.menu), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
              ],
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 17, 100, 151)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
        }
      },
    );
  }
}
