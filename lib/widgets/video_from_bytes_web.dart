import 'dart:typed_data';
import 'dart:html' as html;
import 'package:video_player/video_player.dart';

String? _blobUrl;

Future<VideoPlayerController> createVideoController(Uint8List bytes) async {
  final blob = html.Blob([bytes]);
  _blobUrl = html.Url.createObjectUrlFromBlob(blob);
  return VideoPlayerController.network(_blobUrl!);
}

void disposeVideoResources() {
  if (_blobUrl != null) {
    html.Url.revokeObjectUrl(_blobUrl!);
    _blobUrl = null;
  }
}
