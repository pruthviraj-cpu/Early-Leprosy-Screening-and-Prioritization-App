import 'package:hive/hive.dart';
import '../model/chat_message.dart';

class ChatCacheService {
  static Box<ChatMessage>? _chatBox;

  /// 🔹 Call this AFTER login
  Future<void> openUserChatBox(String userId) async {
    final boxName = 'chats_$userId';

    if (Hive.isBoxOpen(boxName)) {
      _chatBox = Hive.box<ChatMessage>(boxName);
    } else {
      _chatBox = await Hive.openBox<ChatMessage>(boxName);
    }
  }

  Future<void> saveMessage(ChatMessage msg) async {
    if (_chatBox == null) return;
    await _chatBox!.add(msg);
  }

  List<ChatMessage> getAllMessages() {
    if (_chatBox == null) return [];
    final messages = _chatBox!.values.toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  List<ChatMessage> getPendingMessages() {
    if (_chatBox == null) return [];
    final messages = _chatBox!.values.toList();
    return messages.where(
      (m) => m.role == 'user' && m.syncStatus == 'pending',
    ).toList();
  }

  Future<void> updateMessageStatus(
    ChatMessage message,
    String status,
  ) async {
    message.syncStatus = status;
    await message.save();
  }


}