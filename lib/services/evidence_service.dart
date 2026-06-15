import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EvidenceService {
  CameraController? _cameraController;
  
  bool _isRecording = false;
  Timer? _chunkTimer;
  
  static const String _serverUploadUrl = 'http://3.111.147.106:3000/api/upload';

  Future<void> initCamera() async {
    try {
      if (kIsWeb) return; 
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
        // Explicitly enable audio here to include it in the .mp4 file
        _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: true);
        await _cameraController!.initialize();
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    _isRecording = true;

    _startChunkCycle();
  }

  Future<void> _startChunkCycle() async {
    if (!_isRecording) return;

    try {
      // Start Video (with built-in audio)
      if (!kIsWeb && _cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.startVideoRecording();
      }

      // Set timer to stop, upload, and restart (every 3 seconds)
      _chunkTimer = Timer(const Duration(seconds: 3), () async {
        if (!_isRecording) return;
        await _stopAndUploadChunk();
        _startChunkCycle(); // Loop
      });
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopAndUploadChunk() async {
    try {
      // Stop Video
      if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
        final videoFile = await _cameraController!.stopVideoRecording();
        // Save to gallery as backup
        await GallerySaver.saveVideo(videoFile.path, albumName: 'VEERA Evidence');
        _uploadToServer(videoFile.path, 'video', 'mp4');
      }
    } catch (e) {
      debugPrint("Error stopping/saving evidence chunk: $e");
    }
  }

  Future<void> _uploadToServer(String filePath, String type, String ext) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'unknown_user';
      final file = File(filePath);
      
      var request = http.MultipartRequest('POST', Uri.parse(_serverUploadUrl));
      request.fields['uid'] = uid;
      request.fields['type'] = type;
      request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: '${DateTime.now().millisecondsSinceEpoch}.$ext'));

      // Fire and forget upload to EC2 Server
      request.send().then((response) {
         if (response.statusCode == 200) {
            debugPrint("Successfully uploaded $type chunk to EC2");
            // Optional: delete local chunk after upload to save space
            try { file.delete(); } catch(e) {}
         } else {
            debugPrint("Failed to upload $type chunk to EC2: ${response.statusCode}");
         }
      }).catchError((e) {
         debugPrint("Upload error: $e");
      });
    } catch (e) {
      debugPrint("Server upload error: $e");
    }
  }

  Future<Map<String, String?>> stopAndUpload(String userId) async {
    if (!_isRecording) return {'audioUrl': null, 'videoUrl': null};
    _isRecording = false;
    _chunkTimer?.cancel();
    await _stopAndUploadChunk();
    return {'audioUrl': 'Uploaded to EC2 (in video)', 'videoUrl': 'Uploaded to EC2'};
  }

  void dispose() {
    _chunkTimer?.cancel();
    _cameraController?.dispose();
  }
}
