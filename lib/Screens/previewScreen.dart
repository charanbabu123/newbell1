import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class PreviewReelsScreen extends StatefulWidget {
  const PreviewReelsScreen({Key? key}) : super(key: key);

  @override
  _PreviewReelsScreenState createState() => _PreviewReelsScreenState();
}

class _PreviewReelsScreenState extends State<PreviewReelsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? profileData;
  List<dynamic> videos = [];
  int currentVideoIndex = 0;
  List<double> progressValues = [];
  bool isPublishing = false; // State to manage loading on the button


  @override
  void initState() {
    super.initState();
    _fetchPreviewVideos();
  }

  Future<void> _publishReel() async {
    setState(() {
      isPublishing = true;
    });

    final String? token = await AuthService.getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found.')),
      );
      setState(() {
        isPublishing = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/publish-reel/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'video_id': videos[currentVideoIndex]['id'], // Assuming each video has an 'id'
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel published successfully!'),
            backgroundColor: Colors.pink,
          ),
        );
        Navigator.pushReplacementNamed(context, '/feed'); // Adjust the route name
      } else {
        throw Exception('Failed to publish reel. ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isPublishing = false;
      });
    }
  }


  Future<void> _fetchPreviewVideos() async {
    final String? token = await AuthService.getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found.')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/preview-videos/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profileData = data['profile'];
          videos = data['videos'];
          progressValues = List.filled(videos.length, 0.0);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load preview videos.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _playNextVideo() {
    setState(() {
      currentVideoIndex = (currentVideoIndex + 1) % videos.length;
      progressValues[currentVideoIndex] = 0.0;
    });
  }

  void _updateProgress(int index, double progress) {
    setState(() {
      progressValues[index] = progress;
    });
  }

  Widget _buildProfileInfo() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.top + 40,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (profileData?['profile_picture'] != null)
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profileData!['profile_picture']),
                ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profileData?['name'] ?? '',
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
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profileData?['city'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profileData?['bio'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: [
                Shadow(
                  blurRadius: 4.0,
                  color: Colors.black,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (videos.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No videos available.',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.black,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CarouselSlider.builder(
            itemCount: videos.length,
            itemBuilder: (context, index, _) {
              final video = videos[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayerWidget(
                    videoUrl: video['video_url'],
                    onVideoEnd: _playNextVideo,
                    isPlaying: currentVideoIndex == index,
                    onProgressUpdate: (progress) => _updateProgress(index, progress),
                    autoPlay: true,
                    caption1: video['caption_1'],
                    caption2: video['caption_2'],
                    caption3: video['caption_3'],
                    duration: video['duration'] ?? 30.0,
                  ),
                  // Video tag
                  Positioned(
                    bottom: MediaQuery.of(context).padding.top + 20, // Adjust as needed
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center the container horizontally
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.6), // Background color tightly wrapping the text
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video['tag'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 120,
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.white),
                          onPressed: () {},
                        ),
                        const SizedBox(height: 5), // Add space here
                        IconButton(
                          icon: const Icon(Icons.comment, color: Colors.white),
                          onPressed: () {},
                        ),
                        const SizedBox(height: 5), // Add space here
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Progress bars
                  Positioned(
                    bottom: 20,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: List.generate(videos.length, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: i < currentVideoIndex
                                    ? 1.0
                                    : (i == currentVideoIndex
                                    ? progressValues[i]
                                    : 0.0),
                                backgroundColor: Colors.grey.withOpacity(0.5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                                minHeight: 3,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: false,
              onPageChanged: (index, _) {
                setState(() {
                  currentVideoIndex = index;
                });
              },
            ),
          ),
          _buildProfileInfo(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 6,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0), // Adjust the padding from the bottom
        child: FloatingActionButton.extended(
          onPressed: isPublishing ? null : _publishReel,
          label: isPublishing
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            'Publish Reel',
            style: TextStyle(color: Colors.white), // Ensures text color is white
          ),
          icon: isPublishing ? null : const Icon(Icons.cloud_upload, color: Colors.white), // Ensures icon color is white
          backgroundColor: isPublishing ? Colors.grey : Colors.pink,
        ),
      ),


    );
  }
}

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
    Key? key,
    required this.videoUrl,
    this.onVideoEnd,
    this.isPlaying = false,
    this.onProgressUpdate,
    this.autoPlay = false,
    this.caption1,
    this.caption2,
    this.caption3,
    this.duration = 30.0,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
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
    _controller = VideoPlayerController.network(widget.videoUrl);
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
            left: 0, // Required to ensure the child can center horizontally
            right: 0, // Required to ensure the child can center horizontally
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), // Padding for the background
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.6), // Background color tightly wrapping the text
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                child: Text(
                  currentCaption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
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
              color: Colors.black.withOpacity(0.3),
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