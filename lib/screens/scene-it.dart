import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';

class CameraScanPage extends StatefulWidget {
  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  String? _videoPath;

  List<File> _extractedFrames = [];
  bool _isExtractingFrames = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera and microphone permissions are required.")),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _extractedFrames.clear();
        _videoPath = null;
      });
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;

    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = file.path;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Video saved: ${path.basename(file.path)}"),
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        _isExtractingFrames = true;
      });

      final directory = await getTemporaryDirectory();
      final framesDir = Directory(path.join(directory.path, "frames_${DateTime.now().millisecondsSinceEpoch}"));
      await framesDir.create();

      await extractFrames(file.path, framesDir.path);

      final extractedFiles = framesDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList();

      setState(() {
        _extractedFrames = extractedFiles;
        _isExtractingFrames = false;
      });
    } catch (e) {
      print("Error stopping recording or extracting frames: $e");
      setState(() {
        _isRecording = false;
        _isExtractingFrames = false;
      });
    }
  }

  Future<void> extractFrames(String videoPath, String outputDir) async {
    final command = '-i "$videoPath" -vf fps=1 "$outputDir/frame_%03d.png"';
    await FFmpegKit.execute(command);
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Scan Room")),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                CameraPreview(_cameraController!),
                if (_isRecording)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Recording...",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
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
          ),

          if (_isExtractingFrames)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text("Extracting frames..."),
                ],
              ),
            ),

          if (_extractedFrames.isNotEmpty)
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                color: Colors.black12,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _extractedFrames.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Image.file(_extractedFrames[index]),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Add your SceneItScreen back here:
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
