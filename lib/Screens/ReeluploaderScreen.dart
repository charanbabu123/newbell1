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

  VideoSection({
    required this.label,
    this.videoFile,
    this.thumbnailController,
    this.captions,
    this.videoId,
  });
}

class ReelUploaderScreen extends StatefulWidget {
  const ReelUploaderScreen({
    super.key,
    this.videoPath,
    this.showAppBar = true,
    this.showSkip = true,
  });
  final String? videoPath;
  final bool showAppBar, showSkip;

  @override
  _ReelUploaderScreenState createState() => _ReelUploaderScreenState();
}

class _ReelUploaderScreenState extends State<ReelUploaderScreen> {
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
          },
        ),
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
                children: [
                  Expanded(
                    child: section.captions != null &&
                            section.captions!.isNotEmpty
                        ? Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "caption1: ${section.captions![0]}",
                                      style:
                                          const TextStyle(color: Colors.pink),
                                    ),
                                    Text(
                                      "caption2: ${section.captions![1]}",
                                      style:
                                          const TextStyle(color: Colors.pink),
                                    ),
                                    Text(
                                      "caption3: ${section.captions![2]}",
                                      style:
                                          const TextStyle(color: Colors.pink),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Logic to edit captions
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      final TextEditingController
                                          caption1Controller =
                                          TextEditingController(
                                              text: section.captions!.length > 0
                                                  ? section.captions![0]
                                                  : '');
                                      final TextEditingController
                                          caption2Controller =
                                          TextEditingController(
                                              text: section.captions!.length > 1
                                                  ? section.captions![1]
                                                  : '');
                                      final TextEditingController
                                          caption3Controller =
                                          TextEditingController(
                                              text: section.captions!.length > 2
                                                  ? section.captions![2]
                                                  : '');
                                      return AlertDialog(
                                        title: const Text('Edit Captions'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: caption1Controller,
                                              decoration: const InputDecoration(
                                                labelText: 'Caption 1',
                                                labelStyle: TextStyle(
                                                    color: Colors
                                                        .pink), // Label color
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .pink), // Underline color when not focused
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .pink), // Underline color when focused
                                                ),
                                              ),
                                            ),
                                            TextField(
                                              controller: caption2Controller,
                                              decoration: const InputDecoration(
                                                labelText: 'Caption 2',
                                                labelStyle: TextStyle(
                                                    color: Colors
                                                        .pink), // Label color
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .pink), // Underline color when not focused
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .pink), // Underline color when focused
                                                ),
                                              ),
                                            ),
                                            TextField(
                                              controller: caption3Controller,
                                              decoration: const InputDecoration(
                                                labelText: 'Caption 3',
                                                labelStyle: TextStyle(
                                                    color: Colors
                                                        .pink), // Label color
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .pink), // Underline color when not focused
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .pink), // Underline color when focused
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () async {
                                              // Validation logic
                                              if (caption1Controller.text
                                                          .split(' ')
                                                          .length >
                                                      10 ||
                                                  caption2Controller.text
                                                          .split(' ')
                                                          .length >
                                                      10 ||
                                                  caption3Controller.text
                                                          .split(' ')
                                                          .length >
                                                      10 ||
                                                  caption1Controller
                                                      .text.isEmpty ||
                                                  caption2Controller
                                                      .text.isEmpty ||
                                                  caption3Controller
                                                      .text.isEmpty) {
                                                // Show an error message if validation fails
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Each caption must be less than 10 words and all fields are mandatory'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              } else {
                                                // Save captions logic if validation passes
                                                setState(() {
                                                  section.captions = [
                                                    caption1Controller.text,
                                                    caption2Controller.text,
                                                    caption3Controller.text
                                                  ];
                                                });
                                                await uploadCaptions(
                                                  section.captions ?? [],
                                                  sections[index]
                                                      .videoId
                                                      .toString(),
                                                );
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            child: const Text('Submit'),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.pink, // Text color
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon:
                                    const Icon(Icons.edit, color: Colors.pink),
                              ),
                            ],
                          )
                        : (caption1Controller.text.isEmpty)
                            ? TextButton.icon(
                                onPressed: () {
                                  // Logic to add captions based on video duration
                                  // For example, you can show a dialog to input captions
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            title: const Text('Add Captions'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller:
                                                      caption1Controller,
                                                  onChanged: (text) {
                                                    if (text.length > 10) {
                                                      caption1Controller.text =
                                                          text.substring(0, 10);
                                                      caption1Controller
                                                              .selection =
                                                          TextSelection.fromPosition(
                                                              TextPosition(
                                                                  offset: caption1Controller
                                                                      .text
                                                                      .length));
                                                    }
                                                    setState(
                                                        () {}); // Update the UI
                                                  },
                                                  decoration: InputDecoration(
                                                    labelText: 'Caption 1 *',
                                                    labelStyle: const TextStyle(
                                                        color: Colors
                                                            .pink), // Label color
                                                    helperText:
                                                        '${caption1Controller.text.length}/10',
                                                    enabledBorder:
                                                        const UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .pink), // Underline color when not focused
                                                    ),
                                                    focusedBorder:
                                                        const UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .pink), // Underline color when focused
                                                    ),
                                                  ),
                                                ),
                                                TextField(
                                                  controller:
                                                      caption2Controller,
                                                  onChanged: (text) {
                                                    if (text.length > 10) {
                                                      caption2Controller.text =
                                                          text.substring(0, 10);
                                                      caption2Controller
                                                              .selection =
                                                          TextSelection.fromPosition(
                                                              TextPosition(
                                                                  offset: caption2Controller
                                                                      .text
                                                                      .length));
                                                    }
                                                    setState(
                                                        () {}); // Update the UI
                                                  },
                                                  decoration: InputDecoration(
                                                    labelText: 'Caption 2 *',
                                                    labelStyle: const TextStyle(
                                                        color: Colors
                                                            .pink), // Label color
                                                    helperText:
                                                        '${caption2Controller.text.length}/10',
                                                    enabledBorder:
                                                        const UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .pink), // Underline color when not focused
                                                    ),
                                                    focusedBorder:
                                                        const UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .pink), // Underline color when focused
                                                    ),
                                                  ),
                                                ),
                                                TextField(
                                                  controller:
                                                      caption3Controller,
                                                  onChanged: (text) {
                                                    if (text.length > 10) {
                                                      caption3Controller.text =
                                                          text.substring(0, 10);
                                                      caption3Controller
                                                              .selection =
                                                          TextSelection.fromPosition(
                                                              TextPosition(
                                                                  offset: caption3Controller
                                                                      .text
                                                                      .length));
                                                    }
                                                    setState(
                                                        () {}); // Update the UI
                                                  },
                                                  decoration: InputDecoration(
                                                    labelText: 'Caption 3 *',
                                                    labelStyle: const TextStyle(
                                                        color: Colors
                                                            .pink), // Label color
                                                    helperText:
                                                        '${caption3Controller.text.length}/10',
                                                    enabledBorder:
                                                        const UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .pink), // Underline color when not focused
                                                    ),
                                                    focusedBorder:
                                                        const UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .pink), // Underline color when focused
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () async {
                                                  // Validation logic
                                                  if (caption1Controller.text.length > 10 ||
                                                      caption2Controller.text.length >
                                                          10 ||
                                                      caption3Controller
                                                              .text.length >
                                                          10 ||
                                                      caption1Controller
                                                          .text.isEmpty ||
                                                      caption2Controller
                                                          .text.isEmpty ||
                                                      caption3Controller
                                                          .text.isEmpty) {
                                                    // Show an error message if validation fails
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Each caption must be less than or equal to 10 characters and all fields are mandatory'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  } else {
                                                    // Save captions logic if validation passes
                                                    setState(() {
                                                      section.captions = [
                                                        caption1Controller.text,
                                                        caption2Controller.text,
                                                        caption3Controller.text
                                                      ];
                                                    });
                                                    await uploadCaptions(
                                                      section.captions ?? [],
                                                      sections[index]
                                                          .videoId
                                                          .toString(),
                                                    );
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.pink, // Text color
                                                ),
                                                child: const Text('Submit'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Captions'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.pink,
                                ),
                              )
                            : Column(
                                children: [
                                  Text(
                                    caption1Controller.text,
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    caption2Controller.text,
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    caption3Controller.text,
                                  )
                                ],
                              ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => deleteVideo(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              )
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

  void previewReels() {
    List<String> videoPaths = sections
        .where((section) => section.videoFile != null)
        .map((section) => section.videoFile!.path)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewReelsScreen(
          videoPaths: videoPaths,
          sectionLabels: sections
              .where((section) => section.videoFile != null)
              .map((section) => section.label)
              .toList(),
          sections: sections, // Add this line to pass the sections argument
          videoTitles: const [],
        ),
      ),
    );
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
                  onPressed: allVideosUploaded ? previewReels : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        allVideosUploaded ? Colors.pink : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
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
