import 'package:hive/hive.dart';
import '../models/chat_message.dart';
// import '../models/user_profile.dart';
// import '../models/diagnosis_result.dart';

class CacheService {
  // static final chatBox = Hive.box<ChatMessage>('chats');
  // static final profileBox = Hive.box<UserProfile>('profile');
  // static final diagnosisBox = Hive.box<DiagnosisResult>('diagnosis');

  // // 🔹 Chat
  // static List<ChatMessage> getChats() => chatBox.values.toList();

  // static Future<void> saveChat(ChatMessage chat) async {
  //   await chatBox.put(chat.id, chat);
  // }

  // // 🔹 Profile
  // static UserProfile? getProfile() =>
  //     profileBox.isNotEmpty ? profileBox.getAt(0) : null;

  // static Future<void> saveProfile(UserProfile profile) async {
  //   await profileBox.clear();
  //   await profileBox.add(profile);
  // }

  // // 🔹 Diagnosis
  // static Future<void> saveDiagnosis(DiagnosisResult result) async {
  //   await diagnosisBox.add(result);
  // }
 static late Box<ChatMessage> _chatBox;

  static Future<void> init() async {
    _chatBox = Hive.box<ChatMessage>('chats');
  }

  static Future<void> saveMessage(ChatMessage msg) async {
    await _chatBox.add(msg);
  }

  static List<ChatMessage> getAllMessages() {
  final messages = _chatBox.values.toList();
  messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return messages;
}
}
