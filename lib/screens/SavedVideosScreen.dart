import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'SavedVideosFeedScreen.dart';
import 'package:video_player/video_player.dart';

class SavedVideosScreen extends StatefulWidget {
  const SavedVideosScreen({super.key});

  @override
  State<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> {
  List<Map<String, dynamic>> savedVideos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedVideos();
  }

  Future<void> _fetchSavedVideos() async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) throw Exception("Authentication failed");

      final response = await http.get(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/saved-videos/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          List<dynamic> results = data['results'];

          savedVideos = results
              .where((item) => (item as Map<String, dynamic>)['videos'].isNotEmpty)
              .map<Map<String, dynamic>>((item) {
            final mapItem = item as Map<String, dynamic>;
            return {
              'user': mapItem['user'],
              'first_video': mapItem['videos'][0], // First video of each user
            };
          }).toList();
        });
      } else {
        throw Exception("Failed to load saved videos");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),// Instagram-style dark background
      appBar: AppBar(
        title: const Text("Saved Videos", style: TextStyle(color: Colors.green)),
        backgroundColor: const Color(0xFFFAF6F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : savedVideos.isEmpty
          ? const Center(
        child: Text(
          "No saved videos found",
          style: TextStyle(color: Colors.white),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Instagram-style grid
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: savedVideos.length,
          itemBuilder: (context, index) {
            final video = savedVideos[index]['first_video'];
            final user = savedVideos[index]['user'];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => profilefeedscreen(userId: user['id']),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video thumbnail using video frame
                    VideoThumbnail(videoUrl: video['video_url']),

                    // Overlay for Instagram-style effect
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),

                    // Username at the bottom
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        user['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Widget to display the first frame of the video as a thumbnail
class VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnail({super.key, required this.videoUrl});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    )
        : Container(
        color: Colors.grey[800]); // Placeholder before thumbnail loads
  }
}