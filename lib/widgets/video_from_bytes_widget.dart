import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoFromBytesWidget extends StatefulWidget {
  final Uint8List videoBytes;

  const VideoFromBytesWidget({Key? key, required this.videoBytes})
    : super(key: key);

  @override
  State<VideoFromBytesWidget> createState() => _VideoFromBytesWidgetState();
}

class _VideoFromBytesWidgetState extends State<VideoFromBytesWidget> {
  VideoPlayerController? _controller;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/temp_video.mp4';
      final file = File(tempFilePath);
      await file.writeAsBytes(widget.videoBytes);

      _controller = VideoPlayerController.file(file);

      await _controller!.initialize();

      if (!mounted) return;

      _controller!.play();
      setState(() => isPlaying = true);

      _controller!.addListener(_videoListener);
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller!),
              _ControlsOverlay(
                controller: _controller!,
                onTogglePlay: () {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                      isPlaying = false;
                    } else {
                      _controller!.play();
                      isPlaying = true;
                    }
                  });
                },
              ),
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                padding: const EdgeInsets.all(10.0),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_controller!.value.position),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.black87,
                ),
              ),
              Text(
                _formatDuration(_controller!.value.duration),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onTogglePlay;

  const _ControlsOverlay({
    required this.controller,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTogglePlay,
      child: Center(
        child: Icon(
          controller.value.isPlaying
              ? Icons.pause_circle_filled
              : Icons.play_circle_filled,
          size: 48.0,
          color: Colors.white,
        ),
      ),
    );
  }
}
