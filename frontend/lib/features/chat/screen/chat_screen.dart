import 'package:flutter/material.dart';
import '../chat_contoller.dart';
import '../widgets/chat_list.dart';
import '../widgets/message_input.dart';
import '../service/chat_service.dart';
import '../service/chat_cache_service.dart';
import '../../../services/api_service.dart';
import '../../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Initialize services and controller
    final cacheService = ChatCacheService();
    final chatService = ChatService(cacheService);
    _controller = ChatController(
      chatService: chatService,
      cacheService: cacheService,
    );
    
    _controller.initialize();
    _controller.addListener(_onChatsUpdated);
    
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onChatsUpdated() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final messageText = _textController.text.trim();
    _textController.clear();
    
    await _controller.sendMessage(messageText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChatsUpdated);
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat"),
        backgroundColor: const Color(0xff4c505b),
        actions: [
          if (_controller.isSyncing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _controller.isSyncing ? null : _controller.syncPendingMessages,
            tooltip: 'Sync messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatList(
              chats: _controller.chats,
              scrollController: _scrollController,
            ),
          ),
          MessageInput(
            controller: _textController,
            onSend: _sendMessage,
            isSyncing: _controller.isSyncing,
          ),
        ],
      ),
    );
  }
}