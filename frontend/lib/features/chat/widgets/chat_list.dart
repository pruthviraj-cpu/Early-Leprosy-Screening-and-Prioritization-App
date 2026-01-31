import 'package:flutter/material.dart';
import '../model/chat_message.dart';
import 'chat_bubble.dart';

class ChatList extends StatelessWidget {
  final List<ChatMessage> chats;
  final ScrollController scrollController;

  const ChatList({
    super.key,
    required this.chats,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatBubble(
          chat: chat,
          isUser: chat.role == 'user',
        );
      },
    );
  }
}