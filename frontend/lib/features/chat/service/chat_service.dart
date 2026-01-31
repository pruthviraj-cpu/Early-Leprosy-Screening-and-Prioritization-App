import '../model/chat_message.dart';
import '../service/chat_cache_service.dart';
import '../../../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatService {
  final ChatCacheService cacheService;

  ChatService(this.cacheService);

  Future<List<ChatMessage>> loadChats() async {
    final cachedChats = cacheService.getAllMessages();
    cachedChats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return cachedChats;
  }

  Future<ChatMessage> sendMessage({
    required String message,
    required DateTime timestamp,
  }) async {
    final userMessage = ChatMessage(
      id: '${timestamp.millisecondsSinceEpoch}_user',
      role: 'user',
      message: message,
      createdAt: timestamp,
      syncStatus: 'pending',
    );

    await cacheService.saveMessage(userMessage);
    return userMessage;
  }

  Future<ChatMessage?> syncWithBackend(ChatMessage userMessage) async {
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

      await cacheService.saveMessage(aiMessage);
      return aiMessage;
    } catch (e) {
      print('Backend send error: $e');
      // Mark as failed
      userMessage.syncStatus = 'failed';
      await userMessage.save();
      return null;
    }
  }

  Future<bool> hasInternetConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }
}