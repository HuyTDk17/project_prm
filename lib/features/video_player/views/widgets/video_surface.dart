import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 16:9 black box that plays [url] with ready-made controls (chewie).
class VideoSurface extends StatefulWidget {
  const VideoSurface({super.key, required this.url});

  final String? url;

  @override
  State<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<VideoSurface> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          aspectRatio: controller.value.aspectRatio,
          allowFullScreen: true,
        );
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: _failed
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.white70, size: 40),
                    SizedBox(height: 8),
                    Text('This video cannot be played.', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            : chewie == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Center(
                    child: AspectRatio(
                      aspectRatio: _video!.value.aspectRatio,
                      child: Chewie(controller: chewie),
                    ),
                  ),
      ),
    );
  }
}
