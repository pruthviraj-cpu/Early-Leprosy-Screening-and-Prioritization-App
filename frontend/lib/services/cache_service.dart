import 'package:hive/hive.dart';
import '../features/chat/model/chat_message.dart';

class CacheService {
  static Box<ChatMessage>? _chatBox;

  static Future<void> openUserChatBox(String userId) async {
    final boxName = 'chats_$userId';

    if (Hive.isBoxOpen(boxName)) {
      _chatBox = Hive.box<ChatMessage>(boxName);
    } else {
      _chatBox = await Hive.openBox<ChatMessage>(boxName);
    }
  }

  static Future<void> saveMessage(ChatMessage msg) async {
    if (_chatBox == null) return;
    await _chatBox!.add(msg);
  }

  static List<ChatMessage> getAllMessages() {
    if (_chatBox == null) return [];
    final messages = _chatBox!.values.toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  /// (Optional) On logout
  static Future<void> closeChatBox() async {
    await _chatBox?.close();
    _chatBox = null;
  }
}
