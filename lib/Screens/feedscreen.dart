import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../common/BottomNavigation.dart';
import '../services/auth_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  List<UserFeed> feeds = [];
  bool isLoading = false;
  String? nextPageUrl;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Pause all videos when app goes to background
      _pauseAllVideos();
    }
  }

  void _pauseAllVideos() {
    // Get all video player widgets in the widget tree
    final List<_VideoPlayerWidgetState> videoStates =
        context.findAncestorStateOfType<_VideoPlayerWidgetState>() != null
            ? [context.findAncestorStateOfType<_VideoPlayerWidgetState>()!]
            : [];

    for (var videoState in videoStates) {
      if (videoState._controller.value.isPlaying) {
        videoState._controller.pause();
      }
    }
  }

  Future<void> _loadFeeds() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final validToken = await _getValidToken();
      if (validToken == null) {
        throw Exception('Unable to authenticate. Please login again.');
      }

      final response = await http.get(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/feed/'),
        headers: {'Authorization': 'Bearer $validToken'},
      );
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          feeds = (data['results'] as List)
              .map((feed) => UserFeed.fromJson(feed))
              .toList();
          nextPageUrl = data['next'];
        });
      } else {
        throw Exception('Failed to load feeds: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isLoading && feeds.isEmpty)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              itemCount: feeds.length,
              itemBuilder: (context, index) {
                return FullScreenFeedItem(feed: feeds[index]);
              },
            ),

          // Overlay header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding:
                const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Explore",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.search, color: Colors.white, size: 28),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class UserFeed {
  final User user;
  final List<Video> videos;

  UserFeed({required this.user, required this.videos});

  factory UserFeed.fromJson(Map<String, dynamic> json) {
    return UserFeed(
      user: User.fromJson(json['user']),
      videos: (json['videos'] as List).map((v) => Video.fromJson(v)).toList(),
    );
  }
}

class User {
  final int id;
  final String name;
  final String profilePictureUrl;
  final int yoe;
  final String email;
  final String city;

  User({
    required this.id,
    required this.name,
    required this.profilePictureUrl,
    required this.yoe,
    required this.email,
    required this.city,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profilePictureUrl: json['profile_picture_url'] ?? '',
      yoe: json['yoe'] ?? 0,
      email: json['email'] ?? '',
      city: json['city'] ?? '',
    );
  }
}

class Video {
  final int id;
  final double duration;
  final String tag;
  final String videoUrl;
  final DateTime uploadedAt;
  final String title;
  final String? caption1;
  final String? caption2;
  final String? caption3;

  Video({
    required this.id,
    required this.tag,
    required this.videoUrl,
    required this.uploadedAt,
    required this.title,
    this.caption1,
    this.caption2,
    this.caption3,
    required this.duration,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? 0,
      duration: (json['duration'] ?? 0.0) ,
      tag: json['tag'] ?? '',
      videoUrl: json['video_url'] ?? '',
      uploadedAt: DateTime.parse(
          json['uploaded_at'] ?? DateTime.now().toIso8601String()),
      title: json['title'] ?? '',
      caption1: json['caption_1'],
      caption2: json['caption_2'],
      caption3: json['caption_3'],
    );
  }
}

class FullScreenFeedItem extends StatefulWidget {
  final UserFeed feed;


  const FullScreenFeedItem({super.key, required this.feed});

  @override
  State<FullScreenFeedItem> createState() => _FullScreenFeedItemState();
}

class _FullScreenFeedItemState extends State<FullScreenFeedItem> {
  final PageController _videoController = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentVideoIndex = 0;

  void _registerController(int index, VideoPlayerController controller) {
    _controllers[index] = controller;
    // Force rebuild to update progress bar
    setState(() {});
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen video
        PageView.builder(
          controller: _videoController,
          itemCount: widget.feed.videos.length,
          onPageChanged: (index) => setState(() => _currentVideoIndex = index),
          itemBuilder: (context, index) {
            return VideoPlayerWidget(video: widget.feed.videos[index]);
          },
        ),

        // User info overlay
        Positioned(
          left: 16,
          bottom: 75,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        NetworkImage(widget.feed.user.profilePictureUrl),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.feed.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.feed.user.city} • ${widget.feed.user.yoe} YOE',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.feed.videos[_currentVideoIndex].caption1 != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    widget.feed.videos[_currentVideoIndex].caption1!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Video progress indicator
        Positioned(
          bottom: 1,
          left: 6,
          right: 6,
          child: Row(
            children: List.generate(widget.feed.videos.length, (index) {
              final controller = _controllers[index];
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: StreamBuilder<Duration?>(
                    stream: controller?.position.asStream(),
                    builder: (context, AsyncSnapshot<Duration?> snapshot) {
                      double progress = 0.0;
                      if (controller != null &&
                          controller.value.isInitialized &&
                          controller.value.duration.inMilliseconds > 0) {
                        progress = (snapshot.data?.inMilliseconds ?? 0) /
                            controller.value.duration.inMilliseconds;
                      }

                      return Stack(
                        children: [
                          // Background (grey) bar
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Progress (white) bar
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),

        // Static buttons like share, comment
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Video tag overlay
        Positioned(
          left: 143,
          bottom: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.feed.videos[_currentVideoIndex].tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final Video video;

  const VideoPlayerWidget({super.key, required this.video});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.network(widget.video.videoUrl);
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.play();
        _controller.addListener(_onVideoEnd);

        // Register controller with parent
        final parentState =
            context.findAncestorStateOfType<_FullScreenFeedItemState>();
        if (parentState != null) {
          parentState._registerController(widget.video.id, _controller);
        }
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _onVideoEnd() {
    if (_controller.value.position == _controller.value.duration) {
      // Automatically play the next video
      final nextIndex = (widget.video.id + 1) % widget.video.id;
      if (nextIndex != 0) {
        _controller = VideoPlayerController.network(widget.video.videoUrl)
          ..initialize().then((_) {
            setState(() => _isInitialized = true);
            _controller.play();
          });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Pause video when widget is being removed from widget tree
    if (_controller.value.isPlaying) {
      _controller.pause();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _controller.value.size?.width ?? 0,
              height: _controller.value.size?.height ?? 0,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        if (widget.video.caption1 != null)
          Positioned(
            bottom: 50,
            left: 16,
            child: Text(
              widget.video.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (widget.video.caption2 != null)
          Positioned(
            bottom: 40,
            left: 16,
            child: Text(
              widget.video.caption2!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        if (widget.video.caption3 != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: Text(
              widget.video.caption3!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Progress bar

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.white,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

Future<String?> _getValidToken() async {
  String? accessToken = await AuthService.getAuthToken();

  if (accessToken == null) {
    return null;
  }

  try {
    // Verify token validity with a lightweight API call
    final response = await http.get(
      Uri.parse(
          'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/verify-token/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 401) {
      // Token expired, try refresh
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null) return null;

      final refreshResponse = await http.post(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/token/refresh/'),
        body: {'refresh': refreshToken},
      );

      if (refreshResponse.statusCode == 200) {
        final data = json.decode(refreshResponse.body);
        await AuthService.saveAuthToken(data['access']);
        return data['access'];
      }
      return null;
    }
    return accessToken;
  } catch (e) {
    return null;
  }
}
