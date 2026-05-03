import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lughati_app/chat_page.dart';

class AppUser {
  final String name;
  final String nationalId;

  AppUser({required this.name, required this.nationalId});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(name: json['name'], nationalId: json['national_id']);
  }
}

class NamesList extends StatefulWidget {
  final String nationalId;

  const NamesList({super.key, required this.nationalId});

  @override
  State<NamesList> createState() => _NamesListState();
}

class _NamesListState extends State<NamesList> {
  List<AppUser> allUsers = [];
  List<AppUser> filteredUsers = [];
  final TextEditingController searchController = TextEditingController();

  final Color backgroundColor = const Color(0xFFFcf7e8);
  final Color primaryColor = const Color(0xFF116497);

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await Dio().get('http://192.168.1.12:8000/api/users');
      if (response.data['status'] == true) {
        final List usersJson = response.data['users'];
        setState(() {
          allUsers = usersJson.map((e) => AppUser.fromJson(e)).toList();
          filteredUsers = allUsers;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void filterUsers(String query) {
    final filtered =
        allUsers.where((user) => user.name.contains(query)).toList();
    setState(() {
      filteredUsers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "مركز لغتي هذا حقي",
          style: TextStyle(color: backgroundColor),
        ),
        iconTheme: IconThemeData(color: backgroundColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: filterUsers,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFFcf7e8),
                labelText: 'ابحث بالاسم',
                suffixIcon: Icon(Icons.search, color: primaryColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Color(0xFFFcf7e8),
                  child: ListTile(
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),

                    trailing: Icon(Icons.chat, color: primaryColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatPage(
                                senderNationalId: widget.nationalId,
                                receiverName: user.name,
                                receiverNationalId: user.nationalId,
                              ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
