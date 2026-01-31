import 'package:flutter/material.dart';
import '../features/chat/model/chat_message.dart';
import '../services/cache_service.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> chats = [];
  late final StreamSubscription<ConnectivityResult> _connectivitySub;
  bool _isSyncing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadChats();
    listenToInternet();
    
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void listenToInternet() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      // FIXED: Check for ANY internet connection
      if (result != ConnectivityResult.none) {
        syncPendingMessages();
      }
    });
  }

  void loadChats() {
    final cachedChats = CacheService.getAllMessages();
    // Sort by creation time for proper display
    cachedChats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() {
      chats = cachedChats;
    });
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

  Future<void> syncPendingMessages() async {
    // Prevent multiple concurrent syncs
    if (_isSyncing) return;
    
    _isSyncing = true;
    setState(() {}); // Update sync indicator
    
    try {
      final messages = CacheService.getAllMessages();
      
      // Get only pending user messages (not those already being sent)
      final pendingMessages = messages.where(
        (m) => m.role == 'user' && m.syncStatus == 'pending',
      ).toList();
      
      if (pendingMessages.isEmpty) {
        _isSyncing = false;
        setState(() {});
        return;
      }
      
      for (final msg in pendingMessages) {
        try {
          // Mark as sending to prevent duplicate sends
          msg.syncStatus = 'sending';
          await msg.save();
          
          final reply = await ApiService.sendChat(msg.message);
          
          // Update original message status
          msg.syncStatus = 'synced';
          await msg.save();
          
          // Create AI reply
          final aiMessage = ChatMessage(
            id: '${msg.id}_reply_${DateTime.now().millisecondsSinceEpoch}',
            role: 'ai',
            message: reply,
            createdAt: DateTime.now(),
            syncStatus: 'synced',
          );
          
          await CacheService.saveMessage(aiMessage);
          
          // Update UI
          if (mounted) {
            setState(() {
              chats.add(aiMessage);
              // Sort again
              chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            });
            _scrollToBottom();
          }
        } catch (e) {
          print('Failed to sync message: $e');
          // If send failed, mark as pending to retry later
          msg.syncStatus = 'pending';
          await msg.save();
        }
      }
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      role: 'user',
      message: _controller.text.trim(),
      createdAt: DateTime.now(),
      syncStatus: 'pending',
    );

    // Clear input first
    final messageText = _controller.text.trim();
    _controller.clear();

    // 1️⃣ Save user message locally
    await CacheService.saveMessage(userMessage);

    setState(() {
      chats.add(userMessage);
      chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
    
    _scrollToBottom();

    // 2️⃣ Check connectivity and send if available
    final connectivity = await Connectivity().checkConnectivity();
    // FIXED: Check for ANY internet connection
    final hasInternet = connectivity != ConnectivityResult.none;

    if (hasInternet) {
      await _sendToBackend(userMessage);
    } else {
      // If offline, just save locally with pending status
      // It will sync when internet comes back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message saved offline. Will send when connected.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendToBackend(ChatMessage userMessage) async {
    try {
      // Mark as sending
      userMessage.syncStatus = 'sending';
      await userMessage.save();
      
      final aiReply = await ApiService.sendChat(userMessage.message);

      // Mark user message as synced
      userMessage.syncStatus = 'synced';
      await userMessage.save();

      // Create AI response
      final aiMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        role: 'ai',
        message: aiReply,
        createdAt: DateTime.now(),
        syncStatus: 'synced',
      );

      await CacheService.saveMessage(aiMessage);

      if (mounted) {
        setState(() {
          chats.add(aiMessage);
          chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Backend send error: $e');
      // Mark as failed
      userMessage.syncStatus = 'failed';
      await userMessage.save();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Will retry when online.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectivitySub.cancel();
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
          // Sync status indicator
          if (_isSyncing)
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
          // Manual sync button in app bar (better placement)
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _isSyncing ? null : syncPendingMessages,
            tooltip: 'Sync messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final isUser = chat.role == 'user';
                
                // Status indicator for user messages
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
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? const Color(0xff4c505b) 
                          : Colors.grey.shade200,
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
                                color: isUser 
                                    ? Colors.white70 
                                    : Colors.black54,
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
              },
            ),
          ),
          // Input section
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Type your message...",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            maxLines: null,
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}