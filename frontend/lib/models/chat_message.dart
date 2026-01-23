import 'package:hive/hive.dart';

part 'chat_message.g.dart';

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

  ChatMessage({
    required this.id,
    required this.role,
    required this.message,
    required this.createdAt,
  });
}
