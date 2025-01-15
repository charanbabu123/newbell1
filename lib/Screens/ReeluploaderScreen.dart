// with progess bar
import 'dart:convert';

import 'package:bell_app1/Screens/previewScreen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;

import '../common/common_widgets.dart';
import '../services/auth_service.dart';
import 'VideoUploadScreen.dart';

class VideoSection {
  final String label;
  File? videoFile;
  VideoPlayerController? thumbnailController;
  List<String>? captions;
  bool isLoading = false;
  double uploadProgress = 0.0;
  bool isProcessing = false;
  String processingTime = '';
  int? videoId;
  String? errorMessage; // New property to store error messages

  VideoSection({
    required this.label,
    this.videoFile,
    this.thumbnailController,
    this.captions,
    this.videoId,
    this.errorMessage,
  });

  void updateCaptions(List<String> newCaptions) {
    captions = newCaptions.toList();
  }

  void clearCaptions() {
    captions = null;
  }
}
class ReelUploaderScreen extends StatefulWidget {
  const ReelUploaderScreen({
    super.key,
    this.videoPath,
    this.showAppBar = true,
    this.showSkip = true,
    this.sectionIndex = 0,

  });
  final String? videoPath;
  final bool showAppBar, showSkip;
  final int sectionIndex;

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

  Future<void> _openCamera() async {
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
          },sectionIndex: widget.sectionIndex,
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
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/videos/reorder/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reels': reelsData}),
      );
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Reels reordered successfully: $jsonResponse');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reels reordered successfully.'),
            backgroundColor: Colors.pink,
          ),
        );
        // Navigate to the preview screen after reordering
        navigateToPreview();
      } else {
        print('Failed to reorder reels: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder reels: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error reordering reels: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reordering reels: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void navigateToPreview() {
    List<String> videoPaths = sections
        .where((section) => section.videoFile != null)
        .map((section) => section.videoFile!.path)
        .toList();

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
          // Show a SnackBar message if the video duration is less than 10 seconds
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please upload a video which is greater than 10 seconds'),
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
      }
    } catch (e) {
      print("Error picking or initializing video: $e");

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
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
      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 204) {
        // Successfully deleted
        setState(() {
          sections[index].thumbnailController?.dispose();
          sections[index].thumbnailController = null;
          sections[index].videoFile = null;
          sections[index].videoId = null; // Reset the video ID
        });

        print('Video deleted successfully');
      } else {
        print('Failed to delete video: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete video: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting video: $e');
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
    VideoSection section = sections[index];
    bool isPreviousVideoUploaded =
        index == 0 || sections[index - 1].videoFile != null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.drag_handle, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  section.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (section.videoFile != null &&
                section.thumbnailController != null) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: VideoPlayer(section.thumbnailController!),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled,
                        size: 50, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: section.captions != null
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < section.captions!.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              "Caption ${i + 1}: ${section.captions![i]}",
                              style: const TextStyle(color: Colors.pink),
                              maxLines: 5, // Limit to two lines
                              overflow: TextOverflow.ellipsis, // Adds ellipsis if text exceeds two lines
                              softWrap: true, // Ensures text wraps if it exceeds one line
                            ),
                          ),

                        const SizedBox(width: 60.0), // Adjust spacing here
                      ],
                    )
                        : TextButton.icon(
                      onPressed: () {
                        _showCaptionDialog(section, index, isEdit: false);
                      },
                      icon: const Icon(Icons.add, color: Colors.pink),
                      label: const Text(
                        'Add Captions',
                        style: TextStyle(color: Colors.pink),
                      ),
                    ),
                  ),
                  //const Spacer(),
                  Column(
                    children: [
                      // Only show Edit Button if captions exist
                      if (section.captions != null)
                        TextButton.icon(
                          onPressed: () {
                            _showCaptionDialog(section, index, isEdit: true);
                          },
                          icon: const Icon(Icons.edit, color: Colors.pink),
                          label: const Text(
                            'Edit Captions',
                            style: TextStyle(color: Colors.pink),
                          ),
                        ),
                      // Delete Button
                      IconButton(
                        onPressed: () => deleteVideo(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
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
                color: Colors.pink,
              ),
              const SizedBox(height: 8),
              Text(
                "Uploading... ${(section.uploadProgress * 100).toInt()}%",
                style: const TextStyle(color: Colors.grey),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => pickVideo(index),
                      icon: const Icon(Icons.upload_file, color: Colors.pink),
                      label: const Text(
                        "Upload Video",
                        style: TextStyle(
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CommonWidgets.recordVideoButton(
                      onPressed: _openCamera,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

  }
  void _showCaptionDialog(VideoSection section, int index, {required bool isEdit}) {
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
    final int videoDuration = section.thumbnailController?.value.duration.inSeconds ?? 60; // Default 60 seconds
    final List<String> intervals = _getCaptionIntervals(videoDuration, 3);


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Captions' : 'Add Captions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caption1Controller,
                decoration: InputDecoration(
                  labelText: intervals.isNotEmpty ? 'Caption 1 (${intervals[0]}) *' : 'Caption 1 *',
                  errorText: section.errorMessage,
                  labelStyle: const TextStyle(color: Colors.pink),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                style: const TextStyle(fontSize: 14), // Adjust font size to fit within 3 rows
        ),
              TextField(
                controller: caption2Controller,
                decoration: InputDecoration(
                  labelText: intervals.isNotEmpty ? 'Caption 2 (${intervals[1]}) *' : 'Caption 2 *',
                  errorText: section.errorMessage,
                  labelStyle: const TextStyle(color: Colors.pink),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
              ),
              TextField(
                controller: caption3Controller,
                decoration: InputDecoration(
                  labelText: intervals.isNotEmpty ? 'Caption 3 (${intervals[2]}) *' : 'Caption 3 *',
                  errorText: section.errorMessage,
                  labelStyle: const TextStyle(color: Colors.pink),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
              ),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (caption1Controller.text.isEmpty ||
                    caption2Controller.text.isEmpty ||
                    caption3Controller.text.isEmpty ||
                    caption1Controller.text.split(' ').length > 100 ||
                    caption2Controller.text.split(' ').length > 100 ||
                    caption3Controller.text.split(' ').length > 100) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Each caption must be less than 100 words and all fields are mandatory'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                List<String> newCaptions = [
                  caption1Controller.text,
                  caption2Controller.text,
                  caption3Controller.text,
                ];

                try {
                  // Call API to upload captions only on first submission
                    await uploadCaptions(newCaptions, section.videoId.toString());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Captions added successfully'),
                        backgroundColor: Colors.pink,
                      ),
                    );


                  // Update local state
                  setState(() {
                    section.updateCaptions(newCaptions);
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating captions: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
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
      intervals.add('$start-${end} seconds');
    }
    return intervals;
  }




  void skipToNext() {
    Navigator.of(context, rootNavigator: true).pushNamed("/feed");
  }

  @override
  void dispose() {
    for (var section in sections) {
      section.thumbnailController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: widget.showAppBar
          ? AppBar(
              iconTheme: const IconThemeData(
                color: Colors.white, // Set the back arrow icon color to white
              ),
              backgroundColor: Colors.pink,
              title: const Text("Create Your Video Resume",
                  style: TextStyle(color: Colors.white)),
              centerTitle: true,
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
                    backgroundColor: allVideosUploaded ? Colors.pink : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    "Preview Your Reel",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

                const SizedBox(width: 20),
                widget.showSkip
                    ? TextButton(
                        onPressed: skipToNext,
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.pink,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
