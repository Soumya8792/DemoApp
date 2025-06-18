import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<VideoPlayerController> createVideoController(Uint8List bytes) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/temp_video.mp4');
  await file.writeAsBytes(bytes);
  return VideoPlayerController.file(file);
}

void disposeVideoResources() {}
