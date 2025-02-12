import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Widget/CommentBox.dart';
import '../common/bottom_navigation.dart';
import '../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  static final Set<int> reportedUserIds = <int>{};

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
  List<UserFeed> get filteredFeeds {
    return feeds.where((feed) =>
    !FeedScreen.reportedUserIds.contains(feed.user.id)
    ).toList();
  }


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

  Future<void> reloadFeeds() async {
    setState(() {
      feeds = [];
      isLoading = true;
    });
    await _loadFeeds();
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
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          else
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: filteredFeeds.length,
            itemBuilder: (context, index) {
              return FullScreenFeedItem(feed: filteredFeeds[index]);
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
                  Colors.transparent, // Fully transparent
                ],
              ),
            ),
            padding: const EdgeInsets.only(
                top: 45, left: 25, right: 32, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Positioned(
                  // top: 37, // Distance from the top
                  // left: 30, // Distance from the left
                  child: SvgPicture.asset(
                    'assets/bell_image.svg',
                    width: 28, // Decreased width
                    height: 28, // Decreased height
                  ),
                ),

                // const Spacer(), // Pushes content to the center
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
            const Positioned(
              // top: 38, // Distance from the top
              right: 30, // Distance from the right
              child: Icon(
                Icons.search, // Search icon
                size: 30, // Same size as the previous SVG
                color: Colors.green, // You can change the color if needed
              ),
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
  final int likeCount;
  final bool isLiked ;

  UserFeed({required this.user, required this.videos,required this.likeCount, required this.isLiked});

  factory UserFeed.fromJson(Map<String, dynamic> json) {
    final bool isLiked = json['is_liked'] ?? false;
    final int likeCount = json['video_data']?['like_count'] ?? 0;

    return UserFeed(
      user: User.fromJson(json['user']),
      videos: (json['videos'] as List).map((v) {
        var video = Video.fromJson(v);
        // Set initial like state and count from feed data
        video.isLiked = isLiked;
        video.likeCount = likeCount;
        return video;
      }).toList(),
      likeCount: likeCount,
      isLiked: isLiked,
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
  bool isLiked; // Add this
  int likeCount;
  int? commentCount;

  Video({
    required this.id,
    required this.tag,
    required this.videoUrl,
    required this.title,
    this.caption1,
    this.caption2,
    this.caption3,
    required this.duration,
    this.isLiked = false, // Add this
    this.likeCount = 0,
    this.commentCount,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    print('Raw comment_count: ${json['comment_count']}');
    print('Raw video_data: ${json['video_data']}');
    return Video(
      id: json['id'] ?? 0,
      duration: (json['duration'] ?? 0.0),
      tag: json['tag'] ?? '',
      videoUrl: json['video_url'] ?? '',
      title: json['title'] ?? '',
      caption1: json['caption_1'],
      caption2: json['caption_2'],
      caption3: json['caption_3'],
      isLiked: (json['is_liked'] as bool?) ?? false, // Add this
      likeCount: json['video_data']?['like_count'] ?? 0,
      commentCount: 0,
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
  bool isSaved = false;


  @override
  void initState() {
    super.initState();
    _initializeControllers();
    for (var video in widget.feed.videos) {
      video.likeCount = widget.feed.likeCount;
    }
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
  double _getTagBottomPosition(String? caption) {
    if (caption == null) {
      return MediaQuery.of(context).size.height * 0.12;
    }

    // Count the number of lines in the formatted caption
    List<String> lines = _formatCaption(caption).split('\n');
    int lineCount = lines.length;

    switch (lineCount) {
      case 1:
        return MediaQuery.of(context).size.height * 0.18;
      case 2:
        return MediaQuery.of(context).size.height * 0.22;
      case 3:
        return MediaQuery.of(context).size.height * 0.23;
      default:
        return MediaQuery.of(context).size.height * 0.23; // For 3+ lines
    }
  }

  Future<void> _handleSaveUser() async {
    try {
      final validToken = await _getValidToken();
      if (validToken == null) {
        throw Exception('Unable to authenticate. Please login again.');
      }

      final response = await http.post(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/users/${widget.feed.user.id}/save/'),
        headers: {
          'Authorization': 'Bearer $validToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String message = data['message'];
        final String action = data['action'];

        if (mounted) {
          setState(() {
            isSaved = action == 'saved';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'saved' ? 'Video saved successfully' : 'Video unsaved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to save/unsave user');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLike(int userId) async {
    try {
      final validToken = await _getValidToken();
      if (validToken == null) {
        throw Exception('Unable to authenticate. Please login again.');
      }

      final response = await http.post(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/like/$userId/'),
        headers: {'Authorization': 'Bearer $validToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Update the current video's like state and count
          widget.feed.videos[_currentVideoIndex].isLiked = data['action'] == 'liked';
          widget.feed.videos[_currentVideoIndex].likeCount = data['total_likes'];

          // Also update the feed's like count to keep it in sync
          widget.feed.videos.forEach((video) {
            video.isLiked = data['action'] == 'liked';
            video.likeCount = data['total_likes'];
          });
        });
      } else {
        throw Exception('Failed to like/unlike');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _formatLikeCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  Future<int> _fetchCommentCount(int userId) async {
    try {
      final token = await _getValidToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/comments/$userId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> comments = json.decode(response.body);
        return comments.length;
      }
    } catch (e) {
      print('Error fetching comment count: $e');
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen video
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 0.0),
          // Adjust the top and bottom padding
          child: PageView.builder(
            controller: _videoController,
            itemCount: widget.feed.videos.length,
            onPageChanged: (index) {
              setState(() {
                _currentVideoIndex = index;
                final currentVideo = widget.feed.videos[index];
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
                onLike: () => _handleLike(widget.feed.user.id), // Pass like function
              );
            },
          ),
        ),

        // User info overlay
        Positioned(
          left: 24,
          bottom: 40,
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
              Column(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.feed.videos[_currentVideoIndex].isLiked
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          color: widget.feed.videos[_currentVideoIndex].isLiked
                              ? Colors.green
                              : Colors.white,
                        ),
                        iconSize: 27,
                        onPressed: () => _handleLike(widget.feed.user.id),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -7),
                        child: Text(
                          _formatLikeCount(
                              widget.feed.videos[_currentVideoIndex].likeCount),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
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
                        icon: const Icon(Icons.mode_comment_outlined,
                            color: Colors.white),
                        iconSize: 27,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            builder: (context) =>
                                CommentBottomSheet(userId: widget.feed.user.id),
                          );
                        },
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -7),
                    child: FutureBuilder<int>(
                      future: _fetchCommentCount(widget.feed.user.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text(
                          _formatCount(count),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        );
                      },
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
                        icon: const Icon(Icons.share_outlined,
                            color: Colors.white),
                        iconSize: 27,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -7), // Move the text up by 2 pixels
                    child: const Text(
                      "Share",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Space between icons
              // Save Button
              // In the build method where you use _buildMoreOptionsButton
              _buildMoreOptionsButton(context, _handleSaveUser, isSaved, widget.feed.user.id),
            ],
          ),
        ),

        // Video tag overlay
        Positioned(
          //left: MediaQuery.of(context).size.width * 0.5 - 43,
          left: MediaQuery.of(context).size.width *
              0.07,
          // Adjust left position relative to screen width
          bottom: _getTagBottomPosition(widget.feed.videos[_currentVideoIndex].caption1), // Adjust bottom position relative to screen height
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
        // Positioned(
        //   top: 37, // Distance from the top
        //   left: 21, // Distance from the right
        //   child: SvgPicture.asset(
        //     'assets/bell_image.svg',
        //     width: 28, // Decreased width
        //     height: 28, // Decreased height
        //   ),
        // ),
        // const Positioned(
        //   top: 38, // Distance from the top
        //   right: 20, // Distance from the left
        //   child: Icon(
        //     Icons.search, // Search icon
        //     size: 30, // Same size as the previous SVG
        //     color: Colors.green, // You can change the color if needed
        //   ),
        // ),

        // Positioned(
        //   bottom: 80, // Adjust this value as needed
        //   left: 20,
        //   right: 20,
        //   child: InstagramStoryProgressBar(
        //     videos: widget.feed.videos,
        //     currentController: _controllers[_currentVideoIndex] ?? VideoPlayerController.networkUrl(Uri.parse('')),
        //     currentIndex: _currentVideoIndex,
        //   ),
        // ),
      ],
    );
  }
}

String _formatCount(int count) {
  if (count < 1000) return count.toString();
  if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
  return '${(count / 1000000).toStringAsFixed(1)}M';
}

class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final List<Video> allVideos; // Add this
  final int currentIndex;
  final VoidCallback onLike;


  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.allVideos, // Add this
    required this.currentIndex,
    required this.onLike, // Add this
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _currentCaption;
  bool _showHeart = false;


  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _controller.addListener(() {
      setState(
          () {}); // This will rebuild the widget when video position changes
    });
  }
  void _showLikeAnimation() {
    setState(() {
      _showHeart = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _showHeart = false;
      });
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
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          onDoubleTap: () {
            _showLikeAnimation();
            if (!widget.video.isLiked) {
              widget.onLike(); // Call passed function
            }
          },
          child: Stack(
            fit: StackFit.expand, // Ensures full-screen
            children: [
              VideoPlayer(_controller), // Directly use VideoPlayer without FittedBox
              if (_showHeart)
                Positioned(
                  child: AnimatedOpacity(
                    opacity: _showHeart ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.green,
                      size: 100,
                    ),
                  ),
                ),
            ],
          ),
        ),


        if (_currentCaption != null)
          Positioned(
            bottom: MediaQuery.of(context).size.height *
                0.13, // Adjust bottom position
            left: MediaQuery.of(context).size.width *
                0.065, // Keep the left position fixed
            // right: MediaQuery.of(context).size.width * 0.25, // Adjust right position if necessary
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 5, // Add consistent vertical padding
                horizontal: 10, // Add consistent horizontal padding
              ),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(
                    15, 32, 4, 0.9), // Background color with transparency
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: Align(
                alignment: Alignment
                    .centerLeft, // Force alignment to the left inside the container
                child: Text(
                  _formatCaption(_currentCaption!),
                  textAlign:
                      TextAlign.left, // Ensure the text aligns to the left
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
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
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




class ReportDialog extends StatefulWidget {
  final int userId; // Add userId parameter

  const ReportDialog({
    Key? key,
    required this.userId,
  }) : super(key: key);

  static void show(BuildContext context, int userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReportDialog(userId: userId),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final List<String> questions = [
    'Job No Longer Available ',
    'Misleading Job Description ',
    'Suspicious Company/Scam ',
    'Duplicate Job Posting ',
    'Incorrect Salary Information ',
    'Company Information Missing ',
    ' Not Interested ',
    ' Location Information Incorrect ',
    ' Discriminatory Requirements',
    ' Spam/Fake Job Posting',
  ];

  int? selectedIndex;
  bool isSubmitting = false;

  Future<void> _submitReport() async {
    print('🔵 _submitReport started');

    try {
      print('🔵 Fetching valid token...');
      final validToken = await _getValidToken();
      if (validToken == null) {
        print('❌ Token retrieval failed. Prompting re-login.');
        throw Exception('Unable to authenticate. Please login again.');
      }

      final url = Uri.parse(
        'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/user/${widget.userId}/hide-and-report/',
      );
      print('🔵 API URL: $url');

      final body = json.encode({
        'reason': questions[selectedIndex!],
      });
      print('🔵 Request Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $validToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('🟡 HTTP Response Status: ${response.statusCode}');
      print('🟡 HTTP Response Body: ${response.body}');

      if (!mounted) {
        print('⚠️ Widget is unmounted. Exiting function.');
        return;
      }

      if (response.statusCode == 201) {
        print('✅ Report submitted successfully.');

        FeedScreen.reportedUserIds.add(widget.userId);
        print('🟢 Added ${widget.userId} to reportedUserIds.');

        final feedState = context.findAncestorStateOfType<_FeedScreenState>();
        if (feedState != null && feedState.mounted) {
          print('🔵 Disposing all videos before removing feed.');
          feedState._disposeAllVideos();

          feedState.setState(() {
            feedState.feeds.removeWhere((feed) => feed.user.id == widget.userId);
          });
          print('🟢 Removed feed for user ${widget.userId}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video reported successfully', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        print('✅ Snackbar displayed');

        Future.delayed(const Duration(milliseconds: 400), () {
          print('🔵 Navigating back to FeedScreen...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FeedScreen()),
          );
        });
      } else {
        print('❌ Failed to submit report. HTTP Status: ${response.statusCode}');
        throw Exception('Failed to submit report');
      }
    } catch (e) {
      print('❌ Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error submitting report: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
        print('🔵 isSubmitting set to false');
      }
    }

    print('🔵 _submitReport finished');
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAF6F0),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Top indicator bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Why are you reporting this post?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // const Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                //   child: Text(
                //     'Your report is anonymous. If someone is in immediate danger, call the local emergency services - don\'t wait.',
                //     style: TextStyle(
                //       color: Colors.grey,
                //       fontSize: 14,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 8),
                ...List.generate(
                  questions.length,
                      (index) => InkWell(
                    onTap: () {
                      setState(() {
                        selectedIndex = selectedIndex == index ? null : index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: selectedIndex == index
                          ? Colors.green.withOpacity(0.1)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              questions[index],
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (selectedIndex == index)
                            const Icon(Icons.check, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Submit button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ElevatedButton(
                    onPressed: selectedIndex == null ? null : _submitReport, // Disable if no option is selected
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey, // Color when disabled
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isSubmitting ? 'Submitting...' : 'Submit Report',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Replace the bookmark button with this implementation in _FullScreenFeedItemState
Widget _buildMoreOptionsButton(
    BuildContext context,
    Future<void> Function() handleSaveUser,
    bool isSaved,
    int userId,  // Add userId parameter
    ) {
  return Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            iconSize: 27,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                builder: (context) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF6F0),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Save button with circular container
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await handleSaveUser();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                                    color: Colors.green,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isSaved ? 'Unsave' : 'Save',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Report button with circular container
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              ReportDialog.show(context, userId);  // Pass userId here
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.report_outlined,
                                    color: Colors.green,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Report',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
