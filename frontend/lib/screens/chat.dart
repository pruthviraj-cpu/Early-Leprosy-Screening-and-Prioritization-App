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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xffF59E0B),
          content: Row(
            children: [
              const Icon(
                Icons.wifi_off_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Message saved offline. Will send when connected.',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
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
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xffEF4444),
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to send message. Will retry when online.',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
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
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "AI Assistant",
          style: TextStyle(
            color: Color(0xff0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xff0F172A)),
        actions: [
          // Manual sync button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isSyncing 
                      ? const Color(0xffF0FDFA)
                      : const Color(0xffF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xff0EA5A4),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.sync_outlined,
                        color: Color(0xff64748B),
                        size: 20,
                      ),
              ),
              onPressed: _isSyncing ? null : syncPendingMessages,
              tooltip: 'Sync messages',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xffE2E8F0),
          ),
        ),
      ),
      body: Column(
        children: [
          // Connection status banner
          StreamBuilder<ConnectivityResult>(
            stream: Connectivity().onConnectivityChanged,
            initialData: ConnectivityResult.none,
            builder: (context, snapshot) {
              final isConnected = snapshot.data != ConnectivityResult.none;
              
              if (isConnected) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xffFEF3C7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_outlined,
                      color: Color(0xffF59E0B),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You are offline. Messages will send when connected.',
                        style: TextStyle(
                          color: Color(0xff92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xff92400E),
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Chat messages area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xffF8FAFC),
                    Color(0xffF1F5F9),
                  ],
                ),
              ),
              child: chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff0F172A).withOpacity(0.04),
                                  blurRadius: 30,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chat_outlined,
                              size: 64,
                              color: Color(0xff94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Start a conversation',
                            style: TextStyle(
                              color: Color(0xff0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Send a message to begin chatting with AI',
                            style: TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final isUser = chat.role == 'user';
                        
                        // Status indicator for user messages
                        Widget? statusIndicator;
                        if (isUser) {
                          if (chat.syncStatus == 'pending') {
                            statusIndicator = Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xffFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                size: 12,
                                color: Color(0xffD97706),
                              ),
                            );
                          } else if (chat.syncStatus == 'sending') {
                            statusIndicator = Container(
                              width: 16,
                              height: 16,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xffF0FDFA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xff0EA5A4),
                                ),
                              ),
                            );
                          } else if (chat.syncStatus == 'failed') {
                            statusIndicator = Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xffFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                size: 12,
                                color: Color(0xffDC2626),
                              ),
                            );
                          } else if (chat.syncStatus == 'synced') {
                            statusIndicator = Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xffD1FAE5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                size: 12,
                                color: Color(0xff059669),
                              ),
                            );
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              // AI Avatar
                              if (!isUser)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff0EA5A4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              
                              // Message bubble
                              Flexible(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? const Color(0xff0EA5A4)
                                        : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(isUser ? 16 : 4),
                                      topRight: Radius.circular(isUser ? 4 : 16),
                                      bottomLeft: const Radius.circular(16),
                                      bottomRight: const Radius.circular(16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff0F172A)
                                            .withOpacity(0.04),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chat.message,
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : const Color(0xff0F172A),
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${chat.createdAt.hour}:${chat.createdAt.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: isUser
                                                  ? Colors.white.withOpacity(0.8)
                                                  : const Color(0xff64748B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (statusIndicator != null) ...[
                                            const SizedBox(width: 8),
                                            statusIndicator,
                                          ]
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // User avatar
                              if (isUser)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xff64748B),
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          
          // Input section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0F172A).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attach button
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.attach_file_outlined,
                      size: 20,
                      color: Color(0xff64748B),
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
                
                // Message input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xffE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Type your message...",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Color(0xff94A3B8),
                                fontSize: 15,
                              ),
                            ),
                            maxLines: null,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xff0F172A),
                              fontWeight: FontWeight.w500,
                            ),
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                
                // Send button
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xff0EA5A4),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff0EA5A4).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: sendMessage,
                    padding: EdgeInsets.zero,
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