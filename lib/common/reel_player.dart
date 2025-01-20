import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoEnd;
  final bool isPlaying;
  final Function(double)? onProgressUpdate;
  final bool autoPlay;
  final String? caption1;
  final String? caption2;
  final String? caption3;
  final double duration;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.onVideoEnd,
    this.isPlaying = false,
    this.onProgressUpdate,
    this.autoPlay = false,
    this.caption1,
    this.caption2,
    this.caption3,
    this.duration = 30.0,
  });

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  String? currentCaption;
  late double segmentDuration;

  @override
  void initState() {
    super.initState();
    segmentDuration = widget.duration / 3;
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _controller.initialize();
    if (widget.isPlaying && widget.autoPlay) {
      _controller.play();
      _isPlaying = true;
    }
    _controller.addListener(_videoListener);
    setState(() {});
  }

  void _videoListener() {
    if (_controller.value.isPlaying) {
      final duration = _controller.value.duration.inMilliseconds;
      final position = _controller.value.position.inMilliseconds;

      if (duration > 0) {
        final progress = position / duration;
        widget.onProgressUpdate?.call(progress);

        // Update caption based on video position
        final currentTime = _controller.value.position.inSeconds;
        setState(() {
          if (currentTime < segmentDuration) {
            currentCaption = widget.caption1;
          } else if (currentTime < segmentDuration * 2) {
            currentCaption = widget.caption2;
          } else {
            currentCaption = widget.caption3;
          }
        });
      }

      if (_controller.value.position >= _controller.value.duration) {
        widget.onVideoEnd?.call();
      }
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.value.isPlaying) {
      _controller.play();
      _isPlaying = true;
    } else if (!widget.isPlaying && _controller.value.isPlaying) {
      _controller.pause();
      _isPlaying = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover, // Ensures videos scale properly
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (currentCaption != null)
                Positioned(
                  bottom: 180, // Adjust this value for vertical positioning
                  left:
                      0, // Required to ensure the child can center horizontally
                  right:
                      0, // Required to ensure the child can center horizontally
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2), // Padding for the background
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.6), // Semi-transparent background color
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),

                      child: Text(
                        currentCaption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _togglePlayPause,
                child: AnimatedOpacity(
                  opacity: !_isPlaying ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // Makes the color semi-transparent
                    child: Center(
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 60.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
  }
}
