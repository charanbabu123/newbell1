import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class PreviewReelsScreen extends StatefulWidget {
  const PreviewReelsScreen({super.key});

  @override
  PreviewReelsScreenState createState() => PreviewReelsScreenState();
}

class PreviewReelsScreenState extends State<PreviewReelsScreen> {
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
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/publish-reel/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'video_id': videos[currentVideoIndex]
              ['id'], // Assuming each video has an 'id'
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reel published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(
            context, '/feed'); // Adjust the route name
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
    if (currentVideoIndex < videos.length - 1) {
      setState(() {
        currentVideoIndex++;
        progressValues[currentVideoIndex] = 0.0;
      });
    }
  }

  void _updateProgress(int index, double progress) {
    setState(() {
      progressValues[index] = progress;
    });
  }

  Widget _buildProfileInfo() {
    return Positioned(
      bottom:120,
      left: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black,
                // Light pink background
                child: profileData != null &&
                    profileData?['profile_picture'] != null &&
                    profileData?['profile_picture'].isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    profileData?['profile_picture'],
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      // Show icon if image fails to load
                      return const Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 20,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2.0,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                )
                    : Icon(
                  Icons.person,
                  color: Colors.pink.shade400,
                  size: 23,
                ),
              ),

              const SizedBox(width: 8),
              Transform.translate(
                offset: const Offset(4, -9),
                // 20 pixels right, 10 pixels down
                child: Text(
                  profileData?['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    // Added to make the font bold
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Transform.translate(
            offset: const Offset(50, -24), // 20 pixels right, 10 pixels down
            child: Text(
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
          // Video Carousel
          CarouselSlider.builder(
            itemCount: videos.length,
            itemBuilder: (context, index, _) {
              final video = videos[index];
              return VideoPlayerWidget(
                videoUrl: video['video_url'],
                onVideoEnd: _playNextVideo,
                isPlaying: currentVideoIndex == index,
                onProgressUpdate: (progress) =>
                    _updateProgress(index, progress),
                autoPlay: true,
                caption1: video['caption_1'],
                caption2: video['caption_2'],
                caption3: video['caption_3'],
                duration: video['duration'] ?? 30.0,
              );
            },
            options: CarouselOptions(
              height: MediaQuery
                  .of(context)
                  .size
                  .height,
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

          // Static Video Tag
          Positioned(
            right: 143,
            left: 143,
            bottom: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF118C7E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    videos[currentVideoIndex]['tag'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Static Like/Comment/Share Buttons
          Positioned(
            right: 16,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Like Button
                Column(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min, // Reduce spacing within the column
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_outline, color: Colors.white),
                              iconSize: 27,
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Transform.translate(
                          offset: const Offset(0, -7), // Move the text up by 2 pixels
                          child: const Text(
                            "Like",
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Space between icons
                // Comment Button
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.mode_comment_outlined, color: Colors.white),
                          iconSize: 27,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -7), // Move the text up by 2 pixels
                      child: const Text(
                        "Comment",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Space between icons
                // Share Button
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          iconSize: 27,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -7), // Move the text up by 2 pixels
                      child: const Text(
                        "Share",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Space between icons
                // Save Button
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.bookmark_outline_outlined, color: Colors.white),
                          iconSize: 27,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -7), // Move the text up by 2 pixels
                      child: const Text(
                        "Save",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Static Progress Bar
          Positioned(
            bottom: 70,
            left: 50,
            right: 50,
            child: Row(
              children: List.generate(videos.length, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: i < currentVideoIndex
                            ? 1.0
                            : (i == currentVideoIndex
                            ? progressValues[i]
                            : 0.0),
                        backgroundColor: Colors.grey.withOpacity(0.5),
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 5,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Profile Info and Back Button
          _buildProfileInfo(),
          Positioned(
            top: MediaQuery
                .of(context)
                .padding
                .top + 12,
            left: 6,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            left: 30,
            right: 30,
            bottom: 10,
            child: ElevatedButton(
              onPressed: isPublishing ? null : _publishReel,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPublishing ? const Color(0xFF24D366).withOpacity(0.7) : const Color(0xFF24D366),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isPublishing
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],


      ),

    );
  }
}
Widget buildStaticButton(IconData icon, String label,
    VoidCallback onPressed) {
  return Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          IconButton(
            icon: Icon(icon, color: Colors.white),
            iconSize: 30,
            onPressed: onPressed,
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ],
  );
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

    // Calculate segment duration after controller is initialized
    segmentDuration = _controller.value.duration.inSeconds / 3;
    print('Total Video Duration: ${_controller.value.duration.inSeconds}');
    print('Calculated Segment Duration: $segmentDuration');

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

        final currentTime = _controller.value.position.inSeconds;
        final totalDuration = _controller.value.duration.inSeconds;
        segmentDuration = totalDuration / 3;

        setState(() {
          if (currentTime <= segmentDuration) {
            print('Showing Caption 1: $currentTime <= $segmentDuration');
            currentCaption = widget.caption1;
          } else if (currentTime <= segmentDuration * 2) {
            print('Showing Caption 2: $currentTime <= ${segmentDuration * 2}');
            currentCaption = widget.caption2;
          } else {
            print('Showing Caption 3: $currentTime > ${segmentDuration * 2}');
            currentCaption = widget.caption3;
          }
        });

        if (_controller.value.position >= _controller.value.duration) {
          widget.onVideoEnd?.call();
        }
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
            bottom: MediaQuery.of(context).size.height * 0.25, // Adjust bottom position
            left: MediaQuery.of(context).size.width * 0.065, // Keep the left position fixed
            // right: MediaQuery.of(context).size.width * 0.25, // Adjust right position if necessary
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 5, // Add consistent vertical padding
                horizontal: 10, // Add consistent horizontal padding
              ),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(15, 32, 4, 0.9), // Background color with transparency
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: Align(
                alignment: Alignment.centerLeft, // Force alignment to the left inside the container
                child: Text(
                  _formatCaption(currentCaption!),
                  textAlign: TextAlign.left, // Ensure the text aligns to the left
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  softWrap: true, // Ensures text wraps properly
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

String _formatCaption(String caption) {
  // Ensure the caption is split into chunks of 38 characters
  List<String> lines = [];
  for (int i = 0; i < caption.length; i += 38) {
    lines.add(caption.substring(i, i + 38 > caption.length ? caption.length : i + 38));
  }
  // Join the lines with line breaks
  return lines.join('\n');
}
