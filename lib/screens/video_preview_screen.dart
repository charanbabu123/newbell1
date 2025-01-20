import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import '../models/video_section.dart';
import '../services/auth_service.dart';
import 'reel_uploader_screen.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;
  final VoidCallback onDiscard;
  final VoidCallback onContinue;
  final int sectionIndex;

  const VideoPreviewScreen({
    required this.videoPath,
    required this.onDiscard,
    required this.onContinue,
    required this.sectionIndex,
    super.key,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _videoPlayerController;
  double _sliderValue = 0.0;
  List<VideoSection> sections = [
    VideoSection(label: "Introduction"),
    VideoSection(label: "Skills"),
    VideoSection(label: "Experience"),
    VideoSection(label: "Hobbies"),
  ];
  late int index;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController.play();
      });
    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.isInitialized) {
        setState(() {
          _sliderValue =
              _videoPlayerController.value.position.inSeconds.toDouble();
        });
      }
    });
  }

  Future<void> handleVideo(int index) async {
    if (sections[index].thumbnailController != null &&
        sections[index].thumbnailController!.value.isPlaying) {
      return;
    }

    try {
      File videoFile = sections[index].videoFile!;
      final VideoPlayerController tempController =
          VideoPlayerController.file(videoFile);
      await tempController.initialize();
      final int videoDuration = tempController.value.duration.inSeconds;
      tempController.dispose();

      if (videoDuration < 10) {
        // Show a SnackBar message if the video duration is less than 10 seconds
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please upload a video which is greater than 10 seconds'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        sections[index].isLoading = true;
        sections[index].uploadProgress = 0.0;
      });

      int fileSizeMB = (videoFile.lengthSync() / (1024 * 1024)).ceil();
      int estimatedDuration = fileSizeMB.clamp(3, 15);

      for (int i = 1; i <= 100; i++) {
        await Future.delayed(Duration(milliseconds: (estimatedDuration * 10)));
        if (mounted) {
          setState(() {
            sections[index].uploadProgress = i / 100;
          });
        }
      }

      if (sections[index].uploadProgress == 1.0) {
        setState(() {
          sections[index].isProcessing = true;
          sections[index].isLoading = false;
          sections[index].processingTime = "Processing Video... ";
        });
      }

      if (videoFile.lengthSync() < 5 * 1024 * 1024) {
        VideoPlayerController controller =
            VideoPlayerController.file(videoFile);
        await controller.initialize();

        await Future.delayed(Duration(seconds: estimatedDuration));

        if (mounted) {
          setState(() {
            sections[index].thumbnailController?.dispose();
            sections[index].videoFile = videoFile;
            sections[index].thumbnailController = controller;
            sections[index].isProcessing = false;
            sections[index].processingTime = '';
            sections[index].uploadProgress = 0.0;
          });
        }
      }

      final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );

      if (compressedVideo == null || compressedVideo.file == null) {
        throw Exception("Video compression failed");
      }

      File compressedFile = File(compressedVideo.file!.path);

      VideoPlayerController controller =
          VideoPlayerController.file(compressedFile);
      await controller.initialize();

      await Future.delayed(Duration(seconds: estimatedDuration));

      if (mounted) {
        setState(() {
          sections[index].thumbnailController?.dispose();
          sections[index].videoFile = compressedFile;
          sections[index].thumbnailController = controller;
          sections[index].isProcessing = false;
          sections[index].processingTime = '';
          sections[index].uploadProgress = 0.0;
        });
      }

      // Make the API call to upload the video
      await uploadVideo(compressedFile, index);
    } catch (e) {
      debugPrint("Error handling video: $e");

      if (mounted) {
        setState(() {
          sections[index].isLoading = false;
          sections[index].uploadProgress = 0.0;
          sections[index].isProcessing = false;
          sections[index].processingTime = '';
        });
      }
    }
  }

  Future<void> uploadVideo(File videoFile, int index) async {
    final String? token = await AuthService.getAuthToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Authentication token not found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/upload-videos/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files
        .add(await http.MultipartFile.fromPath('video_file', videoFile.path));
    request.fields['position'] = index.toString();
    request.fields['tag'] = sections[index].label;
    request.fields['duration'] = sections[index]
            .thumbnailController
            ?.value
            .duration
            .inSeconds
            .toString() ??
        '0';
    request.fields['status'] = 'PUBLISHED';

    try {
      final response = await request.send();
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        // Store the video ID from the response
        setState(() {
          sections[index].videoId = jsonResponse['id'];
        });

        debugPrint('Video uploaded: $jsonResponse');
      } else {
        debugPrint('Failed to upload video: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload video: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Container
          SizedBox.expand(
            child: _videoPlayerController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoPlayerController.value.size.width,
                      height: _videoPlayerController.value.size.height,
                      child: VideoPlayer(_videoPlayerController),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
          ),

          // Top status bar background gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top + 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls background gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: .8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Video progress slider
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: .3),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _sliderValue,
                min: 0.0,
                max: _videoPlayerController.value.duration.inSeconds.toDouble(),
                onChangeStart: (value) {
                  _videoPlayerController.pause();
                },
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                  _videoPlayerController
                      .seekTo(Duration(seconds: value.toInt()));
                },
                onChangeEnd: (value) {
                  _videoPlayerController.play();
                },
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Discard button
                TextButton(
                  onPressed: widget.onDiscard,
                  child: const Text(
                    "Discard",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Play/Pause button
                IconButton(
                  icon: Icon(
                    _videoPlayerController.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoPlayerController.value.isPlaying) {
                        _videoPlayerController.pause();
                      } else {
                        _videoPlayerController.play();
                      }
                    });
                  },
                ),

                // Upload button
                TextButton(
                  onPressed: () {
                    // Log video path for debugging
                    debugPrint(widget.videoPath);
                    // Navigate directly to ReelUploaderScreen without popping multiple screens
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReelUploaderScreen(
                          videoPath: widget.videoPath,
                          sectionIndex: widget.sectionIndex,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Upload",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
