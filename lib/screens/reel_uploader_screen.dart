// with progress bar
import 'dart:convert';
import '../../screens/preview_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;
import '../common/common_widgets.dart';
import '../models/video_section.dart';
import '../providers/video_section_provider.dart';
import '../services/auth_service.dart';
import 'full_screen_camera_screen.dart';
import 'dart:math' as math;

class ReelUploaderScreen extends StatefulWidget {
  const ReelUploaderScreen({
    super.key,
    this.videoPath,
    this.showAppBar = true,
    this.showSkip = true,
    this.sectionIndex,
  });
  final String? videoPath;
  final bool showAppBar, showSkip;
  final int? sectionIndex;

  @override
  ReelUploaderScreenState createState() => ReelUploaderScreenState();
}

class ReelUploaderScreenState extends State<ReelUploaderScreen> {
  final TextEditingController caption1Controller = TextEditingController();
  final TextEditingController caption2Controller = TextEditingController();
  final TextEditingController caption3Controller = TextEditingController();

  List<VideoSection> sections = [
    VideoSection(label: "Introduction"),
    VideoSection(label: "Skills"),
    VideoSection(label: "Experience"),
    VideoSection(label: "Hobbies"),
  ];

  String currentCaption = "";

  bool get allVideosUploaded =>
      sections.every((section) => section.videoFile != null);

  final List<File> _selectedVideos = [];

  @override
  void initState() {
    super.initState();
    //Refresh token
    AuthService.refreshToken();

    if (widget.videoPath != null) {
      // Assuming `sectionIndex` is valid and matches a card
      sections[widget.sectionIndex ?? 0].videoFile = File(widget.videoPath!);
      debugPrint("index in reeluploaderscreen = ${widget.sectionIndex}");
      handleVideo(widget.sectionIndex ?? 0);
    }

    // Reinitialize controllers for existing videos
    reinitializeControllers();
  }

  void reinitializeControllers() {
    for (var section in sections) {
      if (section.videoFile != null &&
          (section.thumbnailController == null ||
              !section.thumbnailController!.value.isInitialized)) {
        section.thumbnailController =
            VideoPlayerController.file(section.videoFile!);
        section.thumbnailController!.initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  Future<void> handleVideo(int index) async {
    debugPrint("handling video for $index");
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please upload a video which is greater than 10 seconds'),
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

  Future<void> _openCamera(int index) async {
    final cameras = await availableCameras();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenCamera(
          cameras: cameras,
          onVideoRecorded: (File video) {
            setState(() {
              _selectedVideos.add(video);
            });
          },
          sectionIndex: index,
        ),
      ),
    );
  }

  Future<void> reorderReels() async {
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

    // Prepare the body for the request
    final List<Map<String, dynamic>> reelsData = sections
        .where((section) => section.videoId != null)
        .map((section) => {
              'id': section.videoId,
              'position': sections.indexOf(section),
            })
        .toList();

    try {
      final response = await http.post(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/videos/reorder/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reels': reelsData}),
      );
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Reels reordered successfully: $jsonResponse');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   // const SnackBar(
        //   //  // content: Text('Reels reordered successfully.'),
        //   //  // backgroundColor: Colors.pink,
        //   // ),
        // );
        // Navigate to the preview screen after reordering
        navigateToPreview();
      } else {
        debugPrint('Failed to reorder reels: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder reels: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error reordering reels: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering reels: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void navigateToPreview() {
    // List<String> videoPaths = sections
    //     .where((section) => section.videoFile != null)
    //     .map((section) => section.videoFile!.path)
    //     .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PreviewReelsScreen(),
      ),
    );
  }

  Future<void> pickVideo(int index) async {
    if (sections[index].thumbnailController != null &&
        sections[index].thumbnailController!.value.isPlaying) {
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result != null && result.files.single.path != null) {
        File videoFile = File(result.files.single.path!);

        final VideoPlayerController tempController =
            VideoPlayerController.file(videoFile);
        await tempController.initialize();
        final int videoDuration = tempController.value.duration.inSeconds;
        tempController.dispose();

        if (videoDuration < 10) {
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

        // Simulate upload progress
        int fileSizeMB = (videoFile.lengthSync() / (1024 * 1024)).ceil();
        int estimatedDuration = fileSizeMB.clamp(3, 15);

        for (int i = 1; i <= 100; i++) {
          await Future.delayed(
              Duration(milliseconds: (estimatedDuration * 10)));
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

        // Compress the video if needed
        final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.LowQuality,
          deleteOrigin: false,
        );

        if (compressedVideo == null || compressedVideo.file == null) {
          throw Exception("Video compression failed");
        }

        File compressedFile = File(compressedVideo.file!.path);

        // Wait for the video to upload
        await uploadVideo(compressedFile, index);

        // Update UI after successful upload
        VideoPlayerController controller =
            VideoPlayerController.file(compressedFile);
        await controller.initialize();

        if (mounted) {
          setState(() {
            sections[index].thumbnailController?.dispose();
            sections[index].videoFile = compressedFile;
            sections[index].thumbnailController = controller;
            sections[index].isProcessing = false;
            sections[index].processingTime = '';
            sections[index].uploadProgress = 0.0;
          });

          Provider.of<VideoSectionsProvider>(context, listen: false)
              .updateVideo(index, compressedFile);
        }
      }
    } catch (e) {
      debugPrint("Error picking or initializing video: $e");

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchProfileData() async {
    final String? token = await AuthService.getAuthToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse(
          'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/preview-videos/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile data');
    }
  }

  Future<void> deleteVideo(int index) async {
    final int? videoId = sections[index].videoId;
    if (videoId == null) {
      // No video ID to delete
      return;
    }

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

    final url =
        'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/videos/detail/$videoId/';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('Status Code: ${response.statusCode}');
      if (response.statusCode == 204) {
        // Successfully deleted
        setState(() {
          sections[index].thumbnailController?.dispose();
          sections[index].thumbnailController = null;
          sections[index].videoFile = null;
          sections[index].videoId = null; // Reset the video ID
        });

        debugPrint('Video deleted successfully');
      } else {
        debugPrint('Failed to delete video: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete video: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future uploadCaptions(List<String> captions, String videoId) async {
    debugPrint('Uploading captions...${captions.length}');
    if (captions == []) return;

    const String baseUrl =
        "https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/videos/detail/";
    final url = Uri.parse("$baseUrl$videoId/");
    final String? token = await AuthService.getAuthToken();
    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final body = <String, dynamic>{};
    int index = 1;
    for (var element in captions) {
      body["caption_$index"] = element;
      index++;
    }

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint(jsonDecode(response.body).toString());
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        debugPrint('Error: ${jsonDecode(response.body)["error"].toString()}');
        return {"error": jsonDecode(response.body)["error"]};
      } else {
        throw Exception(
            "Failed to update captions. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error updating captions: $e");
    }
  }

  void reorderSections(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final VideoSection section = sections.removeAt(oldIndex);
      sections.insert(newIndex, section);
    });

    // Trigger vibration haptics after reordering
    HapticFeedback.mediumImpact();
  }

  Widget buildVideoSection(int index) {
    final sections = Provider.of<VideoSectionsProvider>(context).sections;
    VideoSection section = sections[index];
    //bool isPreviousVideoUploaded = index == 0 || sections[index - 1].videoFile != null;

    return Card(
      color: Colors.white, // Change to white
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                section.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (section.videoFile != null &&
                section.thumbnailController != null) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 15, bottom: 15, left: 70, right: 70),
                    // Adjust the value to increase/decrease spacing
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: VideoPlayer(section.thumbnailController!),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15, // Adjust the bottom position as needed
                    right: 75, // Adjust the right position as needed
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(
                            0.5), // Black background with some opacity
                        borderRadius:
                            BorderRadius.circular(50), // Round the edges
                      ),
                      child: IconButton(
                        onPressed: () => deleteVideo(index),
                        icon: const Icon(Icons.delete,
                            color:
                                Colors.white), // Icon color white for contrast
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (section.captions != null)
                    Container(
                      margin: const EdgeInsets.only(top: 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, // Light beige background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < section.captions!.length; i++)
                            SizedBox(
                              width:
                                  300, // Set fixed width for each caption card
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 8), // Space between captions
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xFFFAF6F0), // White background inside beige container
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Caption ${i + 1} (${_getCaptionTimeRange(i, section.thumbnailController?.value.duration.inSeconds ?? 60)})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      section.captions![i],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 3, // Prevent overflow
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8), // Space before buttons
                          Align(
                            alignment: Alignment
                                .bottomRight, // Align buttons to bottom-right
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right:
                                      8), // Adds spacing from the right edge
                              child: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Ensures row wraps around content
                                mainAxisAlignment: MainAxisAlignment
                                    .end, // Align icons to the right
                                children: [
                                  const SizedBox(
                                      width: 185),
                                  Container(
                                    decoration: BoxDecoration(
    color: const Color(0xFFDCF8C7), // Light green background
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20, color: Colors.black),
                                      onPressed: () => _showCaptionDialog(
                                          section, index,
                                          isEdit: true),
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 15), // Space between buttons
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCF8C7), // Light green background
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 20, color: Colors.black),
                                      onPressed: () {
                                        setState(() {
                                          section.captions = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: 325,  // Take full width
                      child: Column(  // Use Column instead of Row
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              _showCaptionDialog(section, index, isEdit: false);
                            },
                            icon: const Icon(Icons.add, color: Colors.green),
                            label: const Text(
                              'Add Captions',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),

                  //const Spacer(),
                ],
              ),
            ] else if (section.isProcessing) ...[
              Text(
                section.processingTime,
                style: const TextStyle(color: Colors.grey),
              ),
            ] else if (section.isLoading) ...[
              LinearProgressIndicator(
                value: section.uploadProgress,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              Text(
                "Uploading... ${(section.uploadProgress * 100).toInt()}%",
                style: const TextStyle(color: Colors.green),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Center(

                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF8C7),
                    //border: Border.all(color: const Color(0xFFDCF8C7), width: 1), // Green border
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext context) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      pickVideo(index);
                                    },
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCF8C7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.upload_file,
                                            color: Color(0xFF118C7E),),
                                          SizedBox(height: 8),
                                          Text(
                                            'Upload Video',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _openCamera(index);
                                    },
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCF8C7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.videocam,
                                            color: Color(0xFF118C7E),//background: #118C7E;

                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Record Video',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },

                    icon: const Icon(Icons.upload_file, color: Color(0xFF118C7E),),
                    label: const Text(
                      "Upload Video",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12), // Button padding
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCaptionTimeRange(int captionIndex, int totalDuration) {
    final int segmentDuration = (totalDuration / 3).ceil();
    final int start = captionIndex * segmentDuration;
    final int end =
        math.min((captionIndex + 1) * segmentDuration, totalDuration);
    return '${start}s-${end}s';
  }

  void _showCaptionDialog(VideoSection section, int index,
      {required bool isEdit}) {
    final provider = Provider.of<VideoSectionsProvider>(context, listen: false);
    final TextEditingController caption1Controller =
        TextEditingController(text: section.captions?.elementAt(0) ?? '');
    final TextEditingController caption2Controller =
        TextEditingController(text: section.captions?.elementAt(1) ?? '');
    final TextEditingController caption3Controller =
        TextEditingController(text: section.captions?.elementAt(2) ?? '');

    if (isEdit && section.captions != null) {
      caption1Controller.text = section.captions![0];
      caption2Controller.text = section.captions![1];
      caption3Controller.text = section.captions![2];
    }

    // Focus nodes to track keyboard state
    final FocusNode focus1 = FocusNode();
    final FocusNode focus2 = FocusNode();
    final FocusNode focus3 = FocusNode();

    // Get video duration in seconds
    final int videoDuration =
        section.thumbnailController?.value.duration.inSeconds ??
            60; // Default 60 seconds
    final List<String> intervals = _getCaptionIntervals(videoDuration, 3);

    // Calculate intervals
    final int interval = (videoDuration / 3).ceil();
    final String interval1 = "0-${interval}s";
    final String interval2 = "${interval + 1}-${interval * 2}s";
    final String interval3 = "${(interval * 2) + 1}-${videoDuration}s";

    bool isKeyboardVisible = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Add listeners to focus nodes
            void updateKeyboardVisibility() {
              setState(() {
                isKeyboardVisible =
                    focus1.hasFocus || focus2.hasFocus || focus3.hasFocus;
              });
            }

            focus1.addListener(updateKeyboardVisibility);
            focus2.addListener(updateKeyboardVisibility);
            focus3.addListener(updateKeyboardVisibility);

            Widget buildCaptionInput(String label,
                TextEditingController controller, FocusNode focusNode) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 60,
                      maxHeight: 85, // Increased max height to accommodate two lines and counter
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: 5,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        hintText: 'Enter caption',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.only(
                  top: isKeyboardVisible
                      ? MediaQuery.of(context).size.height * 0.15
                      : MediaQuery.of(context).size.height * 0.35,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enter Caption',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.close, size: 24),
                          ),
                        ],
                      ),
                    ),
                    // Caption inputs
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildCaptionInput('Caption 1 ($interval1)',
                                caption1Controller, focus1),
                            buildCaptionInput('Caption 2 ($interval2)',
                                caption2Controller, focus2),
                            buildCaptionInput('Caption 3 ($interval3)',
                                caption3Controller, focus3),
                            // Add extra padding at bottom when keyboard is visible
                            if (isKeyboardVisible) const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                    // Submit button (only visible when keyboard is hidden)

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (caption1Controller.text.length > 100 ||
                              caption2Controller.text.length > 100 ||
                              caption3Controller.text.length > 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Each caption must be less than 100 characters'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          List<String> newCaptions = [
                            caption1Controller.text,
                            caption2Controller.text,
                            caption3Controller.text,
                          ].where((caption) => caption.isNotEmpty).toList();

                          try {
                            await uploadCaptions(newCaptions, section.videoId.toString());

                            // Update the local state
                            setState(() {
                              section.captions = newCaptions;
                            });

                            // Update the provider state
                            provider.updateCaptions(index, newCaptions);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Captions added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }

                            Navigator.of(context).pop();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating captions: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24D366),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<String> _getCaptionIntervals(int videoDuration, int segmentCount) {
    int segmentLength = (videoDuration / segmentCount).ceil();
    List<String> intervals = [];
    for (int i = 0; i < segmentCount; i++) {
      int start = i * segmentLength;
      int end = (i + 1) * segmentLength;
      if (end > videoDuration) end = videoDuration;
      intervals.add('$start-$end seconds');
    }
    return intervals;
  }

  void skipToNext() {
    Navigator.of(context, rootNavigator: true).pushNamed("/feed");
  }

  @override
  Widget build(BuildContext context) {
    sections = Provider.of<VideoSectionsProvider>(context).sections;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 246, 240, 1),
      appBar: widget.showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color.fromRGBO(250, 246, 240, 1),
              title: Row(
                mainAxisSize:
                    MainAxisSize.min, // Keeps the Row as small as possible
                children: [
                  BackButton(
                    color: Colors.black,
                    onPressed: () => SystemNavigator.pop(),
                  ),
                  const SizedBox(
                      width: 8), // Adjust spacing between icon and text
                  const Text(
                    "Create Your Video Resume",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              centerTitle: false, // Ensures the title stays on the left
              titleSpacing: 0, // Moves the title further left
              actions: [
                if (widget
                    .showSkip) // Only show skip button if showSkip is true
                  TextButton(
                    onPressed: skipToNext,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          right: 15.0,
                          top: 3.0), // Adjust right padding for spacing
                      child: TextButton(
                        onPressed: skipToNext,
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Color.fromRGBO(17, 140, 126, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.all(16),
              onReorder: reorderSections,
              children: List.generate(
                sections.length,
                (index) => Container(
                  key: ValueKey(sections[index].label),
                  child: buildVideoSection(index),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: allVideosUploaded ? reorderReels : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allVideosUploaded
                        ? const Color(0xFFEBEBEB)
                        : const Color(
                            0xFFEFEFEF), // Matches the light grey background
                    padding: const EdgeInsets.symmetric(
                        horizontal: 98, vertical: 15), // Updated padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                  ),
                  child: Text(
                    "Preview Your Resume",
                    style: TextStyle(
                      color: allVideosUploaded
                          ? const Color(0xFF24D366)
                          : const Color(
                              0xFF8E8E8E), // Text color matches active/inactive state
                      fontSize: 16,
                      fontWeight: FontWeight.w600, // Semi-bold to match design
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
