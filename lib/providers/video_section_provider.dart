import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/video_section.dart';

class VideoSectionsProvider with ChangeNotifier {
  final List<VideoSection> _sections = [
    VideoSection(label: "Introduction"),
    VideoSection(label: "Skills"),
    VideoSection(label: "Experience"),
    VideoSection(label: "Hobbies"),
  ];
  List<VideoSection> get sections => _sections;

  void updateVideo(int index, File videoFile) {
    _sections[index].videoFile = videoFile;
    notifyListeners();
  }

  void updateCaptions(int index, List<String> newCaptions) {
    _sections[index].captions = newCaptions;
    notifyListeners();
  }
}
