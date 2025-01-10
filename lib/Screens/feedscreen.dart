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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }


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
  void _initializeControllers() {
    for (int i = 0; i < widget.feed.videos.length; i++) {
      final video = widget.feed.videos[i];
      final controller = VideoPlayerController.network(video.videoUrl);
      _controllers[i] = controller;
      controller.initialize();
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
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
          onPageChanged: (index) {
            setState(() {
              _currentVideoIndex = index;

              // Pause all controllers
              for (var controller in _controllers.values) {
                controller.pause();
              }

              // Play the video for the current page
              _controllers[index]?.play();
            });
          },

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

            ],
          ),
        ),

        // Video progress indicator
        // Positioned(
        //   bottom: 10,
        //   left: 16,
        //   right: 16,
        //   child: Row(
        //     children: List.generate(widget.feed.videos.length, (index) {
        //       final controller = _controllers[index];
        //       return Expanded(
        //         child: Stack(
        //           children: [
        //             // Background (grey) bar
        //             Container(
        //               height: 4,
        //               margin: const EdgeInsets.symmetric(horizontal: 2),
        //               decoration: BoxDecoration(
        //                 color: Colors.grey.withOpacity(0.5),
        //                 borderRadius: BorderRadius.circular(2),
        //               ),
        //             ),
        //             // Progress (white) bar
        //             if (controller != null)
        //               ValueListenableBuilder<VideoPlayerValue>(
        //                 valueListenable: controller,
        //                 builder: (context, value, child) {
        //                   double progress = 0.0;
        //                   if (value.isInitialized &&
        //                       value.duration.inMilliseconds > 0) {
        //                     progress = value.position.inMilliseconds /
        //                         value.duration.inMilliseconds;
        //                   }
        //
        //                   return FractionallySizedBox(
        //                     alignment: Alignment.centerLeft,
        //                     widthFactor: progress.clamp(0.0, 1.0),
        //                     child: Container(
        //                       height: 4,
        //                       decoration: BoxDecoration(
        //                         color: Colors.white,
        //                         borderRadius: BorderRadius.circular(2),
        //                       ),
        //                     ),
        //                   );
        //                 },
        //               ),
        //           ],
        //         ),
        //       );
        //     }),
        //   ),
        // ),


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
            alignment: Alignment.center, // Center aligns the content inside the Container
            child: Text(
              widget.feed.videos[_currentVideoIndex].tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center, // Ensures multi-line text is center-aligned
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
  String? _currentCaption;

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
        setState((){  _isInitialized = true;
            _currentCaption = widget.video.caption1;});
        _controller.addListener(_updateCaption);
        _controller.play();
        _controller.addListener(() {
          if (_controller.value.isInitialized &&
              _controller.value.position >= _controller.value.duration &&
              !_controller.value.isPlaying) {
            _onVideoEnd();
          }
        });

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
    final parentState = context.findAncestorStateOfType<_FullScreenFeedItemState>();
    if (parentState != null) {
      // Determine the next video index
      final nextVideoIndex = parentState._currentVideoIndex + 1;

      // Check if there's a next video
      if (nextVideoIndex < parentState.widget.feed.videos.length) {
        parentState._videoController.animateToPage(
          nextVideoIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }





  void _updateCaption() {
    if (!_controller.value.isInitialized || _controller.value.duration == null) {
      return;
    }

    final position = _controller.value.position.inSeconds;
    final totalDuration = _controller.value.duration.inSeconds;

    if (totalDuration > 0) {
      final segment = totalDuration ~/ 3;

      setState(() {
        if (position < segment) {
          _currentCaption = widget.video.caption1;
        } else if (position < 2 * segment) {
          _currentCaption = widget.video.caption2;
        } else {
          _currentCaption = widget.video.caption3;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.removeListener(_updateCaption);
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
        Padding(
          padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
          child: GestureDetector(
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
        ),

        if (_currentCaption != null)
          Positioned(
            bottom: MediaQuery.of(context).size.height / 3, // 1/3 from the bottom
            left: 16,
            right: 16,
            child: Text(
              _currentCaption!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.bold, // Ensures the text is bold
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
