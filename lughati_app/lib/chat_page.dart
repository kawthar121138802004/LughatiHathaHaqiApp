import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final String senderNationalId;
  final String receiverName;
  final String receiverNationalId;

  const ChatPage({
    super.key,
    required this.senderNationalId,
    required this.receiverName,
    required this.receiverNationalId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final Color backgroundColor = const Color(0xFFFcf7e8);
  final Color primaryColor = const Color(0xFF116497);
  List<dynamic> messages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchMessages();

    // تحديث الرسائل كل 3 ثوانٍ
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchMessages();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // إيقاف التايمر عند مغادرة الصفحة
    super.dispose();
  }

  Future<void> fetchMessages() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.1.12:8000/api/chat/messages',
        queryParameters: {
          'sender_national_id': widget.senderNationalId,
          'receiver_national_id': widget.receiverNationalId,
        },
      );

      if (response.data['success'] == true) {
        setState(() {
          messages = response.data['messages'];
        });
      } else {
        print('⚠️ Failed to load messages');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      try {
        final dio = Dio();
        final response = await dio.post(
          'http://192.168.1.12:8000/api/chat/send',
          data: {
            'sender_national_id': widget.senderNationalId,
            'receiver_national_id': widget.receiverNationalId,
            'message': text,
          },
        );

        print('✅ Response: ${response.data}');
        _messageController.clear();
        await fetchMessages(); // تحديث الرسائل بعد الإرسال
      } catch (e) {
        print('❌ Error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل في إرسال الرسالة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          widget.receiverName,
          style: TextStyle(color: backgroundColor),
        ),
        iconTheme: IconThemeData(color: backgroundColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSender = message['from'] == widget.senderNationalId;

                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: ChatBubble(
                    text: message['message'],
                    color: isSender ? primaryColor : backgroundColor,
                    textColor: isSender ? backgroundColor : primaryColor,
                    isSender: isSender,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 45),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '  ...',
                        filled: true,
                        fillColor: const Color(0xFFFcf7e8),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: primaryColor),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final bool isSender;

  const ChatBubble({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: isSender ? color : const Color(0xFF116497),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
    );
  }
}
