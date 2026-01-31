import 'package:hive/hive.dart';

part '../../../models/chat_message.g.dart';

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String role; // user | ai

  @HiveField(2)
  String message;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String syncStatus; // pending | synced | failed | sending

  ChatMessage({
    required this.id,
    required this.role,
    required this.message,
    required this.createdAt,
    required this.syncStatus,
  });
}