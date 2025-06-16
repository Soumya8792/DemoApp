import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool isUser;

  @HiveField(2)
  final Uint8List? image;

  @HiveField(3)
  final Uint8List? videoUrl;



  ChatMessage({
    required this.text,
    required this.isUser,
    this.image,
    this.videoUrl,
  });
}
