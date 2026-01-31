import 'dart:async';
import 'package:flutter/material.dart';
import './model/chat_message.dart';
import './service/chat_service.dart';
import './service/chat_cache_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatController extends ChangeNotifier {
  final ChatService chatService;
  final ChatCacheService cacheService;
  
  List<ChatMessage> _chats = [];
  bool _isSyncing = false;
  late StreamSubscription<ConnectivityResult> _connectivitySub;
  
  List<ChatMessage> get chats => _chats;
  bool get isSyncing => _isSyncing;
  
  ChatController({
    required this.chatService,
    required this.cacheService,
  });
  
  void initialize() {
    loadChats();
    _setupConnectivityListener();
  }
  
  Future<void> loadChats() async {
    _chats = await chatService.loadChats();
    notifyListeners();
  }
  
  void _setupConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingMessages();
      }
    });
  }
  
  Future<void> syncPendingMessages() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      final pendingMessages = cacheService.getPendingMessages();
      
      if (pendingMessages.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return;
      }
      
      for (final msg in pendingMessages) {
        try {
          final aiMessage = await chatService.syncWithBackend(msg);
          if (aiMessage != null) {
            _chats.add(aiMessage);
            _chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
          }
        } catch (e) {
          print('Failed to sync message: $e');
        }
      }
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) return;
    
    final timestamp = DateTime.now();
    final userMessage = await chatService.sendMessage(
      message: messageText.trim(),
      timestamp: timestamp,
    );
    
    _chats.add(userMessage);
    _chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
    
    final hasInternet = await chatService.hasInternetConnection();
    
    if (hasInternet) {
      await _sendToBackend(userMessage);
    } else {
      // Message is already saved with pending status
      // Will sync when internet comes back
    }
  }
  
  Future<void> _sendToBackend(ChatMessage userMessage) async {
    try {
      final aiMessage = await chatService.syncWithBackend(userMessage);
      if (aiMessage != null) {
        _chats.add(aiMessage);
        _chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      }
    } catch (e) {
      // Error is already handled in syncWithBackend
      notifyListeners();
    }
  }
  
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }
}