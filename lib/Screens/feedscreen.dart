import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/auth_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver,SingleTickerProviderStateMixin {
  List<UserFeed> feeds = [];
  bool isLoading = false;
  String? nextPageUrl;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
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
            padding: const EdgeInsets.only(top: 46, left: 54, right: 10, bottom: 16),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Spacer(), // Pushes content to the center

                // Search Icon
                const Icon(Icons.search, color: Colors.white, size: 28),
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
      bio: json['bio'] ,
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
      duration: (json['duration'] ?? 0.0) ,
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
        Padding(
          padding: const EdgeInsets.only(top: 25.0, bottom: 0.0), // Adjust the top and bottom padding
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
          left: 16,
          bottom: 70,
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
                        widget.feed.user.bio ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
          bottom: 85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Like Button
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.white),
                        iconSize: 30,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text("Like", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15), // Space between icons
              // Comment Button
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment, color: Colors.white),
                        iconSize: 30,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text("Comment", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15), // Space between icons
              // Share Button
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        iconSize: 30,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text("Share", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        // Video tag overlay
        Positioned(
          right: 143,
          left: 143,
          bottom: 20,
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
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

}

class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final List<Video> allVideos;  // Add this
  final int currentIndex;


  const VideoPlayerWidget({super.key, required this.video,required this.allVideos,   // Add this
    required this.currentIndex,});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _currentCaption;
  int _currentVideoIndex = 0;



  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _controller.addListener(() {
      setState(() {});  // This will rebuild the widget when video position changes
    });
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
            bottom: 150,
            left: 0, // Align the container to the left edge of the parent
            right: 10, // Align the container to the right edge of the parent
            child: Center( // Center the container within the available space
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5), // Adjust padding for the background
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatCaption(_currentCaption!), // Format the caption to limit 5 words per line
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Ensures the text is bold
                  ),
                ),
              ),
            ),
          ),

        // Progress bar

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: InstagramStoryProgressBar(
            videos: widget.allVideos,
            currentController: _controller,
            currentIndex: widget.currentIndex,  // Use the index passed from parent
          ),
        ),
      ],
    );
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
    Key? key,
    required this.videos,
    required this.currentController,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                height: 4,
                decoration: BoxDecoration(
                  color: index < currentIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
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
    Key? key,
    required this.controller,
    required this.isActive,
  }) : super(key: key);

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
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String profilePicUrl = '';

  @override
  void initState() {
    super.initState();
    fetchProfilePic();
  }

  Future<void> fetchProfilePic() async {
    try {
      final accessToken = await AuthService.getAuthToken();
      if (accessToken == null) {
        debugPrint('Access token not found. Please log in.');
        return;
      }

      final response = await http.get(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/profile/'),
        headers: {
          'Authorization': 'Bearer $accessToken', // Include the access token
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        setState(() {
          profilePicUrl = user['profile_picture'] ?? ''; // Set profile picture URL
        });
      } else {
        debugPrint('Failed to load profile picture: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching profile picture: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 65, // Adjust the height to match LinkedIn's style
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.home_filled, color: Colors.white, size: 26), // Adjust size to LinkedIn's icon size
                onPressed: () {},
              ),
              Transform.translate(
                offset: const Offset(0, -5), // Move the text 5 pixels upward
                child: const Text(
                  'Home',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.search, color: Colors.white, size: 26), // Adjust size
                onPressed: () {},
              ),
              Transform.translate(
                offset: const Offset(0, -5), // Move the text 5 pixels upward
                child: const Text(
                  'Search',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.forward_to_inbox, color: Colors.white, size: 26), // Adjust size
                onPressed: () {},
              ),

              Transform.translate(
                offset: const Offset(0, -5), // Move the text 5 pixels upward
                child: const Text(
                  'Inbox',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16, // Adjust size for profile picture
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: profilePicUrl.isNotEmpty
                        ? Image.network(
                      profilePicUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.grey,
                        );
                      },
                    )
                        : const Icon(
                      Icons.person,
                      color: Colors.grey,
                    ), // Fallback for empty profilePicUrl
                  ),
                ),
                const SizedBox(height: 4), // Space between profile icon and text
                Transform.translate(
                  offset: const Offset(0, -0), // Move the text 5 pixels upward
                  child: const Text(
                    'Profile',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}