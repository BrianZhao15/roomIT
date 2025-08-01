import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScanPage extends StatefulWidget {
  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  String? _videoPath;
  List<String> _extractedFrames = [];

  static const MethodChannel _channel = MethodChannel('scan_media');

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    if (cameraStatus.isGranted && micStatus.isGranted && storageStatus.isGranted) {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: true,
        );
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
      List<String> frames = await extractFrames(_videoPath!, frameCount: 10);
      setState(() {
        _extractedFrames = frames;
      });
    }
  }

  Future<List<String>> extractFrames(String videoPath, {int frameCount = 10}) async {
    List<String> savedPaths = [];

    final status = await Permission.storage.request();
    if (!status.isGranted) return savedPaths;

    for (int i = 0; i < frameCount; i++) {
      final int timeMs = i * 1000;
      final Uint8List? bytes = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.PNG,
        timeMs: timeMs,
        quality: 75,
      );

      if (bytes != null) {
        final result = await ImageGallerySaver.saveImage(
          bytes,
          quality: 75,
            name: "frame_${i}_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (result['isSuccess']) {
          savedPaths.add(result['filePath']);
        }
      }
    }

    return savedPaths;
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
        appBar: AppBar(title: Text("Scan Room")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Scan Room")),
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
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.file(File(_extractedFrames[index])),
                  );
                },
              ),
            )
                : SizedBox(),
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
        appBar: AppBar(title: Text('Scene It')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Scene It')),
      body: CameraPreview(_controller!),
    );
  }
}
