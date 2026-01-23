import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/cache_service.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  void loadChats() {
    final cachedChats = CacheService.getAllMessages();
    setState(() {
      chats = cachedChats;
    });
  }


  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      message: _controller.text,
      createdAt: DateTime.now(),
    );

    // 1️⃣ Save user message locally
    await CacheService.saveMessage(userMessage);

    setState(() {
      chats.add(userMessage);
    });

    _controller.clear();

    // 2️⃣ Call backend
    String aiReply;
    try {
      aiReply = await ApiService.sendChat(userMessage.message);
    } catch (e) {
      aiReply = "⚠️ Failed to get response. Please try again.";
    }


    final aiMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'ai',
      message: aiReply,
      createdAt: DateTime.now(),
    );

    // 3️⃣ Save AI message locally
    await CacheService.saveMessage(aiMessage);

    setState(() {
      chats.add(aiMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat"),
        backgroundColor: const Color(0xff4c505b),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final isUser = chat.role == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chat.message,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
