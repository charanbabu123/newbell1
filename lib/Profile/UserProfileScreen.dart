import 'dart:convert';
import 'dart:io';
import 'package:bell_app1/Screens/ReeluploaderScreen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../common/BottomNavigation.dart';
import '../common/reel_player.dart';
import '../common/videoplayer.dart';
import '../login/LoginPhoneScreen.dart';
import '../models/video_model.dart';
import '../services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const UserProfileScreen(),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
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

  final String apiEndpoint = "https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/profile/";

  @override
  void initState() {
    super.initState();
    //Refresh token
    AuthService.refreshToken();
    fetchUserProfile();

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
        Uri.parse('${apiEndpoint}refresh-token'), // Adjust the endpoint as needed
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
      print('Error refreshing token: $e');
      return null;
    }
  }

  Future<http.Response> _makeAuthenticatedRequest(Future<http.Response> Function(String token) requestFunction) async {
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
        builder: (context) => EditProfileScreen(username: username, bio: bio),
      ),
    );

    if (updatedData != null) {
      setState(() {
        username = updatedData['username'];
        bio = updatedData['bio'];
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
      MaterialPageRoute(builder: (context) => MenuScreen(onLogout: _handleLogout)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back arrow icon color to white
        ),
        title: Text(
          username,
          style: const TextStyle(
            color: Colors.pink,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: _openMenuScreen,
          ),
        ],
      ),
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
          : Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (userProfilePicture != null ? NetworkImage(userProfilePicture!) : null),
                        child: _profileImage == null && userProfilePicture == null
                            ? const Icon(Icons.person, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    if (_profileImage == null && userProfilePicture == null) // Check if no profile picture
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue,
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
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name : $username",
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "City : $city",
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Year of Exp: ${yoe.toString()}",
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bio,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _editProfile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Center(
                      child: Text(
                        "Edit Profile",
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
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Colors.pink,
                    tabs: [

                      Tab(icon: Icon(Icons.video_library, color: Colors.pink)),
                      Tab(icon: Icon(Icons.grid_on, color: Colors.pink)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [

                        SwipeableVideoView(videos: videos),
                        //VideoGridSection(videos: videos),
                        const ReelUploaderScreen(
                          showAppBar: false,
                          showSkip: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

class MenuScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const MenuScreen({Key? key, required this.onLogout}) : super(key: key);

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




  const EditProfileScreen({Key? key, required this.username, required this.bio })
      : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/register/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bio': _bioController.text,
        }),
      );
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop({
            'username': _usernameController.text,
            'bio': _bioController.text,
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
        title: const Text("Edit Profile", style: TextStyle(color: Colors.pink)),
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
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.pink),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                hintText: "Enter username",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Bio",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.pink),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
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
                    backgroundColor: Colors.blue,
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
                    "Save",
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

  const VideoGridSection({Key? key, required this.videos}) : super(key: key);
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  Widget _buildThumbnail(String? thumbnail) {
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
  }

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
                    color: Colors.grey
                        .withOpacity(0.7),
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

  String _formatDuration(int  seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class SwipeableVideoView extends StatefulWidget {
  final List<VideoModel> videos;

  const SwipeableVideoView({Key? key, required this.videos}) : super(key: key);

  @override
  _SwipeableVideoViewState createState() => _SwipeableVideoViewState();
}

class _SwipeableVideoViewState extends State<SwipeableVideoView> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6); // Adjust the viewport fraction to make the cards smaller
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
        childAspectRatio: 9 /16, // Adjust the aspect ratio to make it look like a reel card
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
    Key? key,
    required this.videos,
    required this.initialIndex,
  }) : super(key: key);

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
      backgroundColor: Colors.black,
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

  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

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
      print("Error initializing video: $e");
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
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
            builder: (context) =>const PreviewReelsScreen1(),

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

class PreviewReelsScreen1 extends StatefulWidget {
  const PreviewReelsScreen1({Key? key}) : super(key: key);

  @override
  _PreviewReelsScreen1State createState() => _PreviewReelsScreen1State();
}

class _PreviewReelsScreen1State extends State<PreviewReelsScreen1> {
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
      child: Container(
        // Debug background
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (profileData?['profile_picture'] != null)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey, // Grey background color for fallback
                    backgroundImage: profileData?['profile_picture'] != null &&
                        profileData!['profile_picture'].isNotEmpty
                        ? NetworkImage(profileData!['profile_picture'])
                        : null, // Load image only if profile_picture is non-null and not empty
                    child: (profileData?['profile_picture'] == null ||
                        profileData!['profile_picture'].isEmpty)
                        ? const Icon(
                      Icons.person, // Default icon for fallback
                      color: Colors.white,
                      size: 20,
                    )
                        : null, // No fallback icon if profile_picture is provided
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
                        // const Icon(
                        //   Icons.location_on,
                        //   color: Colors.white,
                        //   size: 14,
                        // ),
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
            Transform.translate(
              offset: const Offset(48, -25), // 20 pixels right, 10 pixels down
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