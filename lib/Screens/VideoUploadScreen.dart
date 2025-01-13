import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bell_app1/common/common_widgets.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../Profile/UserProfileScreen.dart';
import '../services/auth_service.dart';
import 'ReeluploaderScreen.dart';


class FullScreenCamera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(File video) onVideoRecorded;

  const FullScreenCamera({
    required this.cameras,
    required this.onVideoRecorded,
    super.key,
  });

  @override
  State<FullScreenCamera> createState() => _FullScreenCameraState();
}

class _FullScreenCameraState extends State<FullScreenCamera> {
  late CameraController _cameraController;
  double _recordingProgress = 0.0;
  late Timer _timer;
  late int _recordingTime;
  String _formattedTime = "00:00";
  bool _isRecording = false;
  String? _videoPath;
  bool _isFrontCamera = false;
  bool _canStopRecording = false;


  @override
  void initState() {
    super.initState();
    _initializeCamera(widget.cameras.first);
  }




  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    _cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {});
  }

  void _startRecording() async {
    if (_cameraController.value.isInitialized) {
      _recordingTime = 0;
      _formattedTime = "00:00";
      _canStopRecording = false;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingTime++;
          _recordingProgress = _recordingTime / 90;
          _formattedTime =
          "${(_recordingTime ~/ 60).toString().padLeft(2, '0')}:${(_recordingTime % 60).toString().padLeft(2, '0')}";
          if (_recordingTime >= 10) {
            _canStopRecording = true;
          }
        });

        if (_recordingTime >= 90) {
          _stopRecording();
        }
      });

      final tempDir = await getTemporaryDirectory();
      final videoFile =
      File("${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4");
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
        _videoPath = videoFile.path;
      });
    }
  }

  void _stopRecording() async {
    if (_cameraController.value.isRecordingVideo && _canStopRecording) {
      final XFile videoFile = await _cameraController.stopVideoRecording();
      _timer.cancel();
      setState(() {
        _isRecording = false;
        _videoPath = videoFile.path;
      });
      _showVideoPreview();
    }
  }

  void _showVideoPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(
          videoPath: _videoPath!,
          onDiscard: () {
            Navigator.pop(context);
          },
          onContinue: () {
            widget.onVideoRecorded(File(_videoPath!));
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _toggleCamera() async {
    if (_isRecording) return;

    final cameras = await availableCameras();
    final newCamera = cameras[_isFrontCamera ? 1 : 0];

    await _initializeCamera(newCamera);
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[600]!),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_cameraController),
          ),
          Positioned(
            bottom: 50,
            right: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isFrontCamera ? Icons.camera_rear : Icons.camera_front,
                  color: Colors.white,
                ),
                onPressed: _toggleCamera,
              ),
            ),
          ),
          if (_isRecording)
            Positioned(
              top: 30,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: Colors.pink[600]?.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(_formattedTime,
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _isRecording ? _recordingProgress : 0.0,
                      strokeWidth: 6,
                      color: Colors.pink[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.pink[600],
                      child: _isRecording && !_canStopRecording
                          ? const Icon(Icons.lock, color: Colors.white)
                          : (_isRecording
                          ? const Icon(Icons.stop, color: Colors.white)
                          : const Icon(Icons.fiber_manual_record,
                          color: Colors.white)),
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
}

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;
  final VoidCallback onDiscard;
  final VoidCallback onContinue;


  const VideoPreviewScreen({

    required this.videoPath,
    required this.onDiscard,
    required this.onContinue,
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
    if (sections[index].thumbnailController != null && sections[index].thumbnailController!.value.isPlaying) {
      return;
    }

    try {
      File videoFile = sections[index].videoFile!;
      final VideoPlayerController tempController = VideoPlayerController.file(videoFile);
      await tempController.initialize();
      final int videoDuration = tempController.value.duration.inSeconds;
      tempController.dispose();

      if (videoDuration < 10) {
        // Show a SnackBar message if the video duration is less than 10 seconds
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a video which is greater than 10 seconds'),
            backgroundColor: Colors.red,
          ),
        );
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
        VideoPlayerController controller = VideoPlayerController.file(videoFile);
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

      VideoPlayerController controller = VideoPlayerController.file(compressedFile);
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
      print("Error handling video: $e");

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
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

        print('Video uploaded: $jsonResponse');
      } else {
        print('Failed to upload video: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error uploading video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                    Colors.black.withOpacity(0.7),
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
                    Colors.black.withOpacity(0.8),
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
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
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
                  _videoPlayerController.seekTo(Duration(seconds: value.toInt()));
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
                    print(widget.videoPath);
                    int count = 0;
                    Navigator.of(context).popUntil((_) => count++ >= 2);
                    handleVideo(index);
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