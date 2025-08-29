import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class CameraScanPage extends StatefulWidget {
  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  CameraController? _cameraController;
  bool _isRecording = false;
  String? _videoPath;
  List<String> _extractedFrames = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (cam.isGranted && mic.isGranted) {
      final cams = await availableCameras();
      if (cams.isNotEmpty) {
        _cameraController =
            CameraController(cams[0], ResolutionPreset.high, enableAudio: true);
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    await _cameraController!.startVideoRecording();
    setState(() {
      _isRecording = true;
      _extractedFrames.clear();
      _videoPath = null;
    });
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;
    final file = await _cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _videoPath = file.path;
    });

    if (_videoPath != null) {
      final frames = await _saveFramesLocally(_videoPath!, frameCount: 10);
      setState(() {
        _extractedFrames = frames;
      });
    }
  }

  Future<List<String>> _saveFramesLocally(String videoPath,
      {int frameCount = 10}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = await getExternalStorageDirectory();
    if(dir==null) {
      throw Exception("Extra external/internal storage or its directory may not be available");
    }
    final folder = Directory(dir.path);
    logger.d('Frame saved at: ${folder.path}');

    final List<String> saved = [];

    for (var i = 0; i < frameCount; i++) {
      final bytes = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.PNG,
        timeMs: i * 1000,
        quality: 75,
      );
      if (bytes == null) continue;

      final file = File('${dir.path}/frame_$i.png');
      await file.writeAsBytes(bytes);
      saved.add(file.path);
    }
    return saved;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan Room")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Room")),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _extractedFrames.isNotEmpty
                ? SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _extractedFrames.length,
                itemBuilder: (ctx, idx) {
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.file(File(_extractedFrames[idx])),
                  );
                },
              ),
            )
                : const SizedBox(),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                onPressed: _isRecording ? _stopRecording : _startRecording,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SceneItScreen extends StatefulWidget {
  @override
  _SceneItScreenState createState() => _SceneItScreenState();
}

class _SceneItScreenState extends State<SceneItScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) return;
    }

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scene It')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scene It')),
      body: CameraPreview(_controller!),
    );
  }
}
