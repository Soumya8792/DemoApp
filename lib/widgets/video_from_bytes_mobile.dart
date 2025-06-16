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

void disposeVideoResources() {
}

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_player/video_player.dart';

// class VideoFromBytesWidget extends StatefulWidget {
//   final Uint8List videoBytes;

//   const VideoFromBytesWidget({super.key, required this.videoBytes});

//   @override
//   State<VideoFromBytesWidget> createState() => _VideoFromBytesWidgetState();
// }

// class _VideoFromBytesWidgetState extends State<VideoFromBytesWidget> {
//   VideoPlayerController? _controller;
//   bool isPlaying = false;

//   @override
//   void initState() {
//     super.initState();
//     _initVideo();
//   }

//   Future<void> _initVideo() async {
//     final tempDir = await getTemporaryDirectory();
//     final tempFile = File('${tempDir.path}/temp_video.mp4');
//     await tempFile.writeAsBytes(widget.videoBytes);

//     _controller = VideoPlayerController.file(tempFile);

//     await _controller!.initialize();
//     _controller!.play();
//     setState(() => isPlaying = true);

//     _controller!.addListener(() {
//       if (mounted) setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '${twoDigits(duration.inHours)}:$minutes:$seconds';
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Column(
//       children: [
//         AspectRatio(
//           aspectRatio: _controller!.value.aspectRatio,
//           child: Stack(
//             alignment: Alignment.bottomCenter,
//             children: [
//               VideoPlayer(_controller!),
//               _ControlsOverlay(
//                 controller: _controller!,
//                 onTogglePlay: () {
//                   setState(() {
//                     if (_controller!.value.isPlaying) {
//                       _controller!.pause();
//                       isPlaying = false;
//                     } else {
//                       _controller!.play();
//                       isPlaying = true;
//                     }
//                   });
//                 },
//               ),
//               VideoProgressIndicator(
//                 _controller!,
//                 allowScrubbing: true,
//                 padding: const EdgeInsets.all(10.0),
//               ),
//             ],
//           ),
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(_formatDuration(_controller!.value.position)),
//             Text(_formatDuration(_controller!.value.duration)),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _ControlsOverlay extends StatelessWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onTogglePlay;

//   const _ControlsOverlay({
//     required this.controller,
//     required this.onTogglePlay,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTogglePlay,
//       child: Center(
//         child: Icon(
//           controller.value.isPlaying
//               ? Icons.pause_circle_filled
//               : Icons.play_circle_filled,
//           size: 40.0,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
// }
