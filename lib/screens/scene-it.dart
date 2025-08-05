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
    final folder = Directory('${dir!.path}/SceneItFrames');
    logger.d('Frame saved at: ${folder.path}');
    if (!await dir.exists()) await dir.create(recursive: true);

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

// ======================================================================
// Below is your original SceneItScreen code, unchanged to avoid errors:

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

/*import 'package:flutter/material.dart';
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

  int getAndroidSdkInt() {
    if (Platform.isAndroid) {
      try {
        final version = int.parse(Platform.version.split(" ").first);
        return version;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    if (Platform.isAndroid && getAndroidSdkInt() >= 33) {
      await Permission.photos.request();
    } else {
      await Permission.storage.request();
    }
    /*if (cameraStatus.isGranted && micStatus.isGranted && storageStatus.isGranted) {
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
    }*/
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
    if (Platform.isAndroid && getAndroidSdkInt() >= 33) {
      await Permission.photos.request();
    } else {
      await Permission.storage.request();
    }
    //if (!status.isGranted) return savedPaths;

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
          name: "frame_$i",
          isReturnImagePathOfIOS: true,
        );
        /*await ImageGallerySaver.saveImage(
          bytes,
          quality: 75,
            name: "frame_${i}_${DateTime.now().millisecondsSinceEpoch}",
        );*/

        if (result['isSuccess']) {
          savedPaths.add(result['filePath']);
          print("Save result: $result");
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

import 'dart:io';
import 'dart:typed_data';
+ import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class CameraScanPage extends StatefulWidget {
  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  CameraController? _cameraController;
  List<String> _extractedFrames = [];
  bool _isRecording = false;
  String? _videoPath;

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
      _cameraController = CameraController(cams[0], ResolutionPreset.high,
          enableAudio: true);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;

    await _cameraController!.startVideoRecording();
    setState(() {
      _isRecording = true;
      _extractedFrames.clear();
      _videoPath = null;
    });
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) return;

    final file = await _cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _videoPath = file.path;
    });

    if (_videoPath != null) {
      final frames =
      await _saveFramesLocally(_videoPath!, frameCount: 10);
      setState(() => _extractedFrames = frames);
    }
  }

  Future<List<String>> _saveFramesLocally(
      String videoPath, {
        int frameCount = 10,
      }) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/SceneItFrames');
    if (!await folder.exists()) await folder.create(recursive: true);

    List<String> paths = [];

    for (var i = 0; i < frameCount; i++) {
      final bytes = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.PNG,
        timeMs: i * 1000,
        quality: 75,
      );

      if (bytes != null) {
        final file = File('${folder.path}/frame_$i.png');
        await file.writeAsBytes(bytes);
        paths.add(file.path);
      }
    }

    return paths;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext cx) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text("Scan Room")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Scan Room")),
      body: Stack(children: [
        CameraPreview(_cameraController!),
        if (_extractedFrames.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _extractedFrames.length,
                itemBuilder: (_, idx) =>
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.file(File(_extractedFrames[idx])),
                    ),
              ),
            ),
          ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              backgroundColor:
              _isRecording ? Colors.red : Colors.blue,
              onPressed:
              _isRecording ? _stopRecording : _startRecording,
              child:
              Icon(_isRecording ? Icons.stop : Icons.videocam),
            ),
          ),
        ),
      ]),
    );
  }
}*/
