import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../common/bottom_navigation.dart';
import '../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  List<UserFeed> feeds = [];
  bool isLoading = false;
  String? nextPageUrl;
  final PageController _pageController = PageController();
  //final int _currentPageIndex = 0;
  late TabController _tabController;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeeds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _tabController.dispose();
    _disposeAllVideos();
    super.dispose();
  }

  void _disposeAllVideos() {
    for (var controller in _controllers.values) {
      if (controller.value.isInitialized) {
        controller.dispose();
      }
    }
    _controllers.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Add a post-frame callback to check if we're still mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Check if the route has changed
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        _pauseAllVideos();
      }
    });
  }

  void _pauseAllVideos() {
    // Pause all videos in the controllers map
    for (var controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
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
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');

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
          // if (isLoading && feeds.isEmpty)
          //   const Center(child: CircularProgressIndicator(color: Colors.white))
          // else
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
                  Colors.grey.withOpacity(0.5), // Semi-transparent grey
                  Colors.transparent,           // Fully transparent
                ],
              ),
            ),
            padding:
            const EdgeInsets.only(top: 70, left: 34, right: 109, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(), // Pushes content to the center
                // Center Content
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // "Explore" Text
                    const Text(
                      "Explore",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6), // Space between text and dot

                    // Small Dot
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white, // Dot color
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6), // Space between dot and text

                    // "Following" Text
                    const Text(
                      "Following",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
  final String? bio; // Make bio nullable
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
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profilePictureUrl: json['profile_picture_url'] ?? '',
      yoe: json['yoe'] ?? 0,
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      bio: json['bio'],
    );
  }
}

class Video {
  final int id;
  final double duration;
  final String tag;
  final String videoUrl;

  final String title;
  final String? caption1;
  final String? caption2;
  final String? caption3;

  Video({
    required this.id,
    required this.tag,
    required this.videoUrl,
    required this.title,
    this.caption1,
    this.caption2,
    this.caption3,
    required this.duration,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? 0,
      duration: (json['duration'] ?? 0.0),
      tag: json['tag'] ?? '',
      videoUrl: json['video_url'] ?? '',
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

  void pauseAllVideos() {
    for (var controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
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
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
      _controllers[i] = controller;
      controller.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen video
        Padding(
          padding: const EdgeInsets.only(
              top: 20.0, bottom: 0.0),
          // Adjust the top and bottom padding
          child: PageView.builder(
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
              return VideoPlayerWidget(
                video: widget.feed.videos[index],
                allVideos: widget.feed.videos,
                currentIndex: index,
              );
            },
          ),
        ),

        // User info overlay
        Positioned(
          left: 24,
          bottom: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 23,
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.feed.user.bio ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          //fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Static buttons like share, comment
        Positioned(
          right: 16,
          bottom: 20,
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

        // Video tag overlay
        Positioned(
          right: 143,
          left: 143,
       // Adjust left position relative to screen width
          bottom: MediaQuery.of(context).size.height * 0.034, // Adjust bottom position relative to screen height
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF118C7E),


              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.feed.videos[_currentVideoIndex].tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold, // Added bold styling
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          top: 38, // Distance from the top
          left: 20, // Distance from the right
          child: SvgPicture.asset(
            'assets/bell_image.svg',
            width: 30, // Decreased width
            height: 30, // Decreased height
          ),
        ),
      ],
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final List<Video> allVideos; // Add this
  final int currentIndex;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.allVideos, // Add this
    required this.currentIndex,
  });

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
    _controller.addListener(() {
      setState(
          () {}); // This will rebuild the widget when video position changes
    });
  }

  Future<void> _initializeVideo() async {
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentCaption = widget.video.caption1;
        });
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
      debugPrint('Error initializing video: $e');
    }
  }

  void _onVideoEnd() {
    final parentState =
        context.findAncestorStateOfType<_FullScreenFeedItemState>();
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

  void _pauseVideo() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        _pauseVideo();
      }
    });
  }

  void _updateCaption() {
    if (!_controller.value.isInitialized) {
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
          padding: const EdgeInsets.only(
              top: 50), // Adjust the top padding as needed
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
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),

        if (_currentCaption != null)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.17, // Adjust bottom position
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
                  _formatCaption(_currentCaption!),
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


        // Progress bar

        Positioned(
          bottom: 10,
          left: 20,
          right: 20,
          child: InstagramStoryProgressBar(
            videos: widget.allVideos,
            currentController: _controller,
            currentIndex:
                widget.currentIndex, // Use the index passed from parent
          ),
        ),
      ],
    );
  }
}

String _formatCaption(String caption) {
  // Split the caption into words
  List<String> words = caption.split(' ');
  List<String> lines = [];
  String currentLine = '';

  for (String word in words) {
    // Check if adding the word exceeds 38 characters
    if ((currentLine + word).length <= 38) {
      currentLine += (currentLine.isEmpty ? '' : ' ') + word;
    } else {
      lines.add(currentLine);
      currentLine = word;
    }
  }
  if (currentLine.isNotEmpty) {
    lines.add(currentLine);
  }
  // Join the lines with line breaks
  return lines.join('\n');
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

class InstagramStoryProgressBar extends StatelessWidget {
  final List<Video> videos;
  final VideoPlayerController currentController;
  final int currentIndex;

  const InstagramStoryProgressBar({
    super.key,
    required this.videos,
    required this.currentController,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        children: List.generate(
          videos.length,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: index == currentIndex
                  ? _ProgressBar(
                      controller: currentController,
                      isActive: true,
                    )
                  : Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: index < currentIndex
                            ? Colors.green
                            : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isActive;

  const _ProgressBar({
    required this.controller,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, VideoPlayerValue value, child) {
        final duration = value.duration.inMilliseconds;
        final position = value.position.inMilliseconds;
        double progress = duration == 0 ? 0 : position / duration;

        // Only show progress if this is the active progress bar
        if (!isActive) {
          progress = 0;
        }

        return Container(
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),

            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
