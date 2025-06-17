import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_from_bytes_platform.dart'; // <-- Important

class VideoFromBytesWidget extends StatefulWidget {
  final Uint8List videoBytes;

  const VideoFromBytesWidget({super.key, required this.videoBytes});

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
    _controller = await createVideoController(widget.videoBytes);
    await _controller!.initialize();
    _controller!.play();
    setState(() => isPlaying = true);

    _controller!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    disposeVideoResources();
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
        Row(
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
          size: 40.0,
          color: Colors.white,
        ),
      ),
    );
  }
}
