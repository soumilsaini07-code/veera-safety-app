import 'dart:io';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:flutter/foundation.dart';

class EvidenceService {
  CameraController? _cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  String? _audioPath;
  bool _isRecording = false;

  Future<void> initCamera() async {
    try {
      if (kIsWeb) return; // Camera capture to file is complex on web, skipping for demo safety
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
        _cameraController = CameraController(camera, ResolutionPreset.medium);
        await _cameraController!.initialize();
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    _isRecording = true;

    try {
      // Start Audio
      if (await _audioRecorder.hasPermission()) {
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          _audioPath = '${dir.path}/evidence_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: _audioPath!);
        }
      }

      // Start Video
      if (!kIsWeb && _cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.startVideoRecording();
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<Map<String, String?>> stopAndUpload(String userId) async {
    if (!_isRecording) return {'audioUrl': null, 'videoUrl': null};
    _isRecording = false;

    String? audioUrl;
    String? videoUrl;

    if (kIsWeb) return {'audioUrl': null, 'videoUrl': null}; // Mock for web

    try {
      // Stop Audio
      final audioFile = await _audioRecorder.stop();
      if (audioFile != null) {
        audioUrl = audioFile; // Saved locally
      }

      // Stop Video
      if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
        final videoFile = await _cameraController!.stopVideoRecording();
        await GallerySaver.saveVideo(videoFile.path, albumName: 'VEERA Evidence');
        videoUrl = videoFile.path; // Saved locally
      }
    } catch (e) {
      debugPrint("Error stopping/saving evidence: $e");
    }

    return {'audioUrl': audioUrl, 'videoUrl': videoUrl};
  }

  void dispose() {
    _cameraController?.dispose();
    _audioRecorder.dispose();
  }
}
