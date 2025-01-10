
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'ReeluploaderScreen.dart';


class PreviewReelsScreen extends StatefulWidget {
  final List<String> videoPaths;
  final List<String> sectionLabels;
  final List<VideoSection> sections; // Add this line to accept sections

  const PreviewReelsScreen({
    super.key,
    required this.videoPaths,
    required this.sectionLabels,
    required this.sections, // Add this line to accept sections
    required List videoTitles,
  });

  @override
  _PreviewReelsScreenState createState() => _PreviewReelsScreenState();
}

class _PreviewReelsScreenState extends State<PreviewReelsScreen> {


  Future<void> publishAndReorderReels() async {
    for (var controller in _controllers.values) {
      if (controller.value.isPlaying) {
        await controller.pause();
      }
    }
    final String? token = await AuthService.getAuthToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token not found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // First, publish the reel
      final publishResponse = await http.post(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/publish-reel/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (publishResponse.statusCode != 200) {
        throw Exception('Failed to publish reel: ${publishResponse.body}');
      }

      // Then, reorder the videos
      List<Map<String, dynamic>> reelsData = [];
      for (int i = 0; i < widget.videoPaths.length; i++) {
        // Assuming we're storing video IDs in the sections
        final videoSection = widget.sections[i];
        if (videoSection.videoId != null) {
          reelsData.add({
            'id': videoSection.videoId,
            'position': i,
          });
        }
      }

      final reorderResponse = await http.post(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/videos/reorder/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reels': reelsData,
        }),
      );
      print('Status Code: ${reorderResponse.statusCode}');
      print('Response Headers: ${reorderResponse.headers}');
      print('Response Body: ${reorderResponse.body}');
      if (reorderResponse.statusCode != 200) {
        throw Exception('Failed to reorder videos: ${reorderResponse.body}');
      }
      for (var controller in _controllers.values) {
        await controller.dispose();
      }
      _controllers.clear();
      // If both operations are successful, navigate to feed
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamed("/feed");
      }
    } catch (e) {
      for (var controller in _controllers.values) {
        await controller.dispose();
      }
      _controllers.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onVideoEnd() {
    if (currentIndex < widget.videoPaths.length - 1) {


      // Trigger carousel to move to next page
      _carouselController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }



  int currentIndex = 0;
  String username = "charan";
  String location = "bengaluru 2 YOE";
  final CarouselSliderController _carouselController = CarouselSliderController();
  final int maxCachedControllers = 3;
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentPlaying = -1;
  bool _isInitializing = false;




  // @override
  // void initState() {
  //   super.initState();
  //   _getCaptions();
  //   _initializeController(0);
  // }
  //
  // String? currentCaption = '';
  // List<String> captions = [];
  //
  // Future<void> _getCaptions() {
  //   //Get response from api and then convert into a list of string
  //   for(int i = 0; i< apiResponse.length; i++) {
  //     captions.add(apiResponse[i]);
  //   }
  // }
  //
  // void _updateCaption() {
  //   final duration = _controller.value.duration;
  //   final position = _controller.value.position;
  //
  //   if (duration != null) {
  //     final segmentDuration = duration.inMilliseconds ~/ 3;
  //
  //     setState(() {
  //       if (position.inMilliseconds < segmentDuration) {
  //         currentCaption = captions[0];
  //       } else if (position.inMilliseconds < 2 * segmentDuration) {
  //         currentCaption = captions[1];
  //       } else {
  //         currentCaption = captions[2];
  //       }
  //     });
  //   }
  // }

  Future<void> _initializeController(int index) async {
    if (index < 0 ||
        index >= widget.videoPaths.length ||
        _controllers.containsKey(index) ||
        _isInitializing) return;

    _isInitializing = true;

    try {
      final controller = VideoPlayerController.file(File(widget.videoPaths[index]));
      await controller.initialize();

      controller.addListener(() {
        if (controller.value.position >= controller.value.duration &&
            index == currentIndex) {
          _carouselController.nextPage();
        }
      });

      _controllers[index] = controller;
      controller.setLooping(false);

      if (mounted && index == currentIndex) {
        await controller.play();
        setState(() => _currentPlaying = index);
      }
    } catch (e) {
      print('Error initializing video $index: $e');
    } finally {
      _isInitializing = false;
    }
  }


  void _cleanupControllers() {
    if (_controllers.length <= maxCachedControllers) return;

    final keepIndices = {
      if (currentIndex - 1 >= 0) currentIndex - 1,
      currentIndex,
      if (currentIndex + 1 < widget.videoPaths.length) currentIndex + 1,
    };

    final disposableControllers =
    Map<int, VideoPlayerController>.from(_controllers)
      ..removeWhere((index, _) => keepIndices.contains(index));

    for (var entry in disposableControllers.entries) {
      entry.value.dispose();
      _controllers.remove(entry.key);
    }
  }

  Future<void> _onPageChanged(int index, CarouselPageChangedReason reason) async {
    if (index == currentIndex) return;

    // Pause the currently playing video
    if (_currentPlaying >= 0 && _controllers.containsKey(_currentPlaying)) {
      await _controllers[_currentPlaying]?.pause();
    }

    setState(() {
      currentIndex = index;
    });

    // Initialize controllers for previous, current, and next videos
// Pre-initialize next video
    await Future.wait([
      _initializeController(index),
      if (index + 1 < widget.videoPaths.length) _initializeController(index + 1),
    ]);

    // Ensure current video plays
    if (_controllers.containsKey(index)) {
      final controller = _controllers[index]!;
      await controller.seekTo(Duration.zero);
      await controller.play();
      setState(() {
        _currentPlaying = index;
      });
    }

    _cleanupControllers();
  }


  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _controllers[index];

    return controller != null && controller.value.isInitialized
        ? GestureDetector(
      onTap: () {
        setState(() {
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            // Resume playback when tapped
            controller.play();
          }
        });
      },
      child: Container(
        color: Colors.black,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    )
        : const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
      ),
    );
  }



  Widget _buildNavItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.videoPaths.length,
            itemBuilder: (context, index, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0, bottom: 5.0), // Increased bottom padding
                    child: _buildVideoPlayer(index),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 18,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage('assets/img10.png'),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [

                                const SizedBox(width: 4),

                                Text(
                                  location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 170,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.sectionLabels[index],
                        style: const TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),


                  Positioned(
                    bottom: 55, // Fixed distance from the bottom edge of the screen
                    right: 25, // Fixed distance from the right edge of the screen
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjust padding here
                      ),
                      onPressed: publishAndReorderReels,
                      child: const Text(
                        "Publish Your Reel",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
              onPageChanged: _onPageChanged,
              scrollPhysics: const BouncingScrollPhysics(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 6,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),


          Positioned(
            bottom: 1, // Position above the navigation bar
            left: 6,
            right: 6,
            child: Row(
              children: List.generate(widget.videoPaths.length * 2 - 1, (index) {
                if (index % 2 == 1) {
                  // Add a black thin line between progress bars
                  return SizedBox(
                    width: 1, // Adjust the width of the black line as needed
                    child: Container(
                      color: Colors.black, // Color of the line
                    ),
                  );
                }

                final progressIndex = index ~/ 2;
                return Expanded(
                  child: AnimatedBuilder(
                    animation: _controllers[progressIndex] ?? ValueNotifier(0.0),
                    builder: (context, child) {
                      final controller = _controllers[progressIndex];
                      final progress = controller != null && controller.value.isInitialized
                          ? controller.value.position.inMilliseconds / controller.value.duration.inMilliseconds
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: progress >= 1.0
                                ? Colors.white // Completed video
                                : Colors.grey.withOpacity(1), // Not started
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0), // Progress percentage
                            child: Container(
                              color: Colors.white, // Active progress bar
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

