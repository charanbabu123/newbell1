import 'dart:convert';
import 'dart:io';
import '../../profile/user_preview_screen.dart';
import '../../screens/reel_uploader_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../login/login_phone_screen.dart';
import '../models/video_model.dart';
import '../services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  File? _profileImage;
  String username = "Loading...";
  String bio = "";
  String email = "Loading...";
  String city = "Loading...";
  num yoe = 0;
  String? userProfilePicture;
  List<VideoModel> videos = [];

  num posts = 23;
  num followers = 500;
  num following = 340;
  bool isLoading = true;
  bool isLoggingOut = false;

  final String apiEndpoint =
      "https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/profile/";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AuthService.refreshToken();
    fetchUserProfile();
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    try {
      setState(() => isLoading = true);

      final response = await _makeAuthenticatedRequest((token) => http.get(
            Uri.parse(apiEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
            },
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          final user = data['user'];
          username = user['name'] ?? "Unknown";
          bio = user['bio'] ?? "unknown";
          email = user['email'] ?? "Unknown";
          city = user['city'] ?? "Unknown";
          userProfilePicture = user['profile_picture'];
          yoe = user['yoe'] ?? 0;
          videos = (data['videos'] as List)
              .map((video) => VideoModel.fromJson(video))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch profile: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching profile: $e")),
        );
      }
    }
  }

  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token found');
      }

      final response = await http.post(
        Uri.parse(
            '${apiEndpoint}refresh-token'), // Adjust the endpoint as needed
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];
        await AuthService.saveAuthToken(newAccessToken);
        return newAccessToken;
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }

  Future<http.Response> _makeAuthenticatedRequest(
      Future<http.Response> Function(String token) requestFunction) async {
    // First try with current access token
    String? accessToken = await AuthService.getAuthToken();
    if (accessToken == null) {
      throw Exception("No access token found");
    }

    var response = await requestFunction(accessToken);

    // If unauthorized, try to refresh token and retry the request
    if (response.statusCode == 401) {
      final newAccessToken = await _refreshAccessToken();

      if (newAccessToken != null) {
        // Retry the request with new token
        response = await requestFunction(newAccessToken);
      } else {
        // If refresh failed, logout and redirect to login
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
            (route) => false,
          );
        }
        throw Exception("Session expired. Please login again.");
      }
    }

    return response;
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _editProfile() async {
    final updatedData = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          username: username,
          bio: bio,
          city: city,
        ),
      ),
    );

    if (updatedData != null) {
      setState(() {
        username = updatedData['username'];
        bio = updatedData['bio'];
        city = updatedData['city'];
      });
    }
  }

  void _handleLogout() async {
    setState(() {
      isLoggingOut = true;
    });

    //await Future.delayed(const Duration(seconds: 1)); // Simulate logout process

    setState(() {
      isLoggingOut = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User logged off successfully')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
      (route) => false,
    );
  }

  void _openMenuScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => MenuScreen(onLogout: _handleLogout)),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (userProfilePicture != null
                              ? NetworkImage(userProfilePicture!)
                              : null) as ImageProvider?,
                      child: _profileImage == null && userProfilePicture == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  if (_profileImage == null && userProfilePicture == null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.add, size: 16, color: Colors.pink),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn("Posts", posts),
                    _buildStatColumn("Followers", followers),
                    _buildStatColumn("Following", following),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            " $username",
            style: const TextStyle(
              color: Colors.pink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            " $city",
            style: const TextStyle(
              color: Colors.pink,
              fontSize: 18,
            ),
          ),
          // Text(
          //   " ${yoe.toString()} YOE",
          //   style: const TextStyle(
          //     color: Colors.pink,
          //     fontSize: 18,
          //   ),
          // ),
          Text(
            " $bio",
            style: const TextStyle(
              color: Colors.pink,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _editProfile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink),
              ),
              child: const Center(
                child: Text(
                  "Edit profile",
                  style: TextStyle(
                    color: Colors.pink,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: isLoggingOut
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Logging off...",
                    style: TextStyle(color: Colors.pink, fontSize: 18),
                  ),
                ],
              ),
            )
          : NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: Colors.pink,
                    expandedHeight:
                        285.0, // Adjust this value based on your header content
                    floating: false,
                    pinned: true,
                    stretch: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: Colors.pink[50],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: 60), // Space for the app bar
                            _buildProfileHeader(),
                          ],
                        ),
                      ),
                    ),
                    title: Text(
                      innerBoxIsScrolled ? username : "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: _openMenuScreen,
                      ),
                    ],
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.pink,
                        tabs: const [
                          Tab(
                              icon: Icon(Icons.video_library,
                                  color: Colors.pink)),
                          Tab(icon: Icon(Icons.grid_on, color: Colors.pink)),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  SwipeableVideoView(videos: videos),
                  const ReelUploaderScreen(
                    showAppBar: false,
                    showSkip: false,
                  ),
                ],
              ),
            ),
    );
  }
}

Widget _buildStatColumn(String label, num count) {
  return Column(
    children: [
      Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.pink,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.black, fontSize: 14)),
    ],
  );
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.pink[50],
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class MenuScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const MenuScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.pink, fontSize: 16),
            ),
            onTap: () {},
          ),
          ListTile(
            title: const Text(
              'Privacy',
              style: TextStyle(color: Colors.pink, fontSize: 16),
            ),
            onTap: () {},
          ),
          ListTile(
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String username;
  final String bio;
  final String city;

  const EditProfileScreen(
      {super.key,
      required this.username,
      required this.bio,
      required this.city});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _cityController = TextEditingController(text: widget.city);
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/register/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bio': _bioController.text,
          'city': _cityController.text,
        }),
      );
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop({
            'username': _usernameController.text,
            'bio': _bioController.text,
            'city': _cityController.text,
          });
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("Edit profile", style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.pink[50],
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.pink, // Set the back arrow icon color to white
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Username",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.pink),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter username",
                hintStyle: const TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "City",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.pink),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter city",
                hintStyle: const TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Bio",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.pink),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter bio",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoGridSection extends StatelessWidget {
  final List<VideoModel> videos;

  const VideoGridSection({super.key, required this.videos});
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  ///TODO: Uncomment the below code to display the thumbnail of the video
  /*Widget _buildThumbnail(String? thumbnail) {
    if (!_isValidUrl(thumbnail)) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white54,
            size: 30,
          ),
        ),
      );
    }

    return Image.network(
      thumbnail!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: const Icon(
            Icons.error_outline,
            color: Colors.white,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white54,
            ),
          ),
        );
      },
    );
  }*/

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(
        child: Text(
          "No videos yet",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return GestureDetector(
          onTap: () {
            if (_isValidUrl(video.videoUrl)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(video: video),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid video URL'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              //_buildThumbnail(video.thumbnail),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(video.duration.toInt()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class SwipeableVideoView extends StatefulWidget {
  final List<VideoModel> videos;

  const SwipeableVideoView({super.key, required this.videos});

  @override
  _SwipeableVideoViewState createState() => _SwipeableVideoViewState();
}

class _SwipeableVideoViewState extends State<SwipeableVideoView> {
  late PageController _pageController;
  //final int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
        viewportFraction:
            0.6); // Adjust the viewport fraction to make the cards smaller
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Center(
        child: Text(
          "No videos yet",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Number of videos per row
        crossAxisSpacing: 0.5,
        mainAxisSpacing: 0.5,
        childAspectRatio:
            9 / 16, // Adjust the aspect ratio to make it look like a reel card
      ),
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        if (video.videoUrl == null) {
          return const Center(
            child: Text(
              "Invalid video URL",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(4.0), // Add padding around each card
          child: VideoPlayerScreen(video: video),
        );
      },
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final List<VideoModel> videos;
  final int initialIndex;

  const FullScreenVideoPlayer({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Number of videos per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1, // Square tiles for videos
          ),
          itemCount: widget.videos.length,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            return VideoPlayerScreen(video: video);
          },
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  List<dynamic> videos = [];
  int currentVideoIndex = 0;
  List<double> progressValues = [];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (!mounted || widget.video.videoUrl == null) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl!),
      );

      await _controller?.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller?.setLooping(true);
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  // void _playNextVideo() {
  //   setState(() {
  //     currentVideoIndex = (currentVideoIndex + 1) % videos.length;
  //     progressValues[currentVideoIndex] = 0.0;
  //   });
  // }
  //
  // void _updateProgress(int index, double progress) {
  //   setState(() {
  //     progressValues[index] = progress;
  //   });
  // }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  //
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PreviewReelsScreen1(),
          ),
        );
      },
      child: Container(
        color: Colors.black,
        child: _isInitialized && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      ),
    );
  }
}
