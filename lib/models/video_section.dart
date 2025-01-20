import 'dart:io';
import 'package:video_player/video_player.dart';

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
