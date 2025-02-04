import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/video_preview_screen.dart';

class FullScreenCamera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(File video) onVideoRecorded;
  final int sectionIndex;

  const FullScreenCamera({
    required this.cameras,
    required this.onVideoRecorded,
    required this.sectionIndex,
    super.key,
  });

  @override
  State<FullScreenCamera> createState() => FullScreenCameraState();
}

class FullScreenCameraState extends State<FullScreenCamera> {
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
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () =>
          widget.cameras.first, // Fallback to default if no front camera
    );
    _initializeCamera(frontCamera);
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
          },
          sectionIndex: widget.sectionIndex,
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
      return  Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
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
              decoration: const BoxDecoration(
                color: Colors.green,

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
                    color: Colors.green,
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
                      color: Colors.green,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.green,
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
