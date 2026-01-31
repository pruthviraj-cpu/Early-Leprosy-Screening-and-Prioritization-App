import 'package:flutter/material.dart';
import '../model/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage chat;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.chat,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    Widget? statusIndicator;
    if (isUser) {
      if (chat.syncStatus == 'pending') {
        statusIndicator = const Icon(
          Icons.schedule,
          size: 14,
          color: Colors.orange,
        );
      } else if (chat.syncStatus == 'sending') {
        statusIndicator = SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue.shade300,
            ),
          ),
        );
      } else if (chat.syncStatus == 'failed') {
        statusIndicator = const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red,
        );
      }
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xff4c505b) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chat.message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${chat.createdAt.hour}:${chat.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
                if (statusIndicator != null) ...[
                  const SizedBox(width: 6),
                  statusIndicator,
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}