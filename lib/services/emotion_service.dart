import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('EmotionService');

enum EmotionType {
  Happy,
  Sad,
  Surprised,
  Fearful,
  Angry,
  Disgusted,
  Neutral
}

class EmotionService extends ChangeNotifier {
  CameraController? _cameraController;
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isInitialized = false;
  EmotionType? _currentEmotion;
  String? _errorMessage;
  bool _isProcessing = false;

  bool get isInitialized => _isInitialized;
  EmotionType? get currentEmotion => _currentEmotion;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  CameraController? get cameraController => _cameraController;

  Future<void> initialize() async {
    try {
      // Initialize camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Use front camera for selfies
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      // Initialize TFLite model and labels
      await _loadModel();
      
      _isInitialized = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> _loadModel() async {
    try {
      // Load model from assets
      final modelFile = await _getAssetFile('assets/models/emotion_detection.tflite');
      _interpreter = Interpreter.fromFile(modelFile.path as File);
      
      // Load labels
      final labelsContent = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsContent.split('\n');
      
      _logger.info('Model and labels loaded successfully');
    } catch (e) {
      throw Exception('Failed to load model or labels: $e');
    }
  }

  Future<File> _getAssetFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${assetPath.split('/').last}';
      final tempFile = File(tempPath);
      
      // Write asset to temporary file
      await tempFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
      );
      
      return tempFile;
    } catch (e) {
      throw Exception('Failed to load asset file: $e');
    }
  }

  Future<EmotionType?> detectEmotion() async {
    if (!_isInitialized || _isProcessing) {
      return null;
    }

    try {
      _isProcessing = true;
      notifyListeners();

      // Capture image from camera
      final image = await _cameraController!.takePicture();
      
      // Process image
      final processedImage = await _preprocessImage(image.path);
      
      // Prepare input tensor
      final inputShape = _interpreter.getInputTensor(0).shape;
      final outputShape = _interpreter.getOutputTensor(0).shape;
      
      // Create input tensor
      final inputArray = processedImage;
      
      // Create output tensor
      final outputArray = List<double>.filled(outputShape.reduce((a, b) => a * b), 0);
      
      // Run inference
      _interpreter.run(inputArray, outputArray);
      
      // Get emotion with highest confidence
      int maxIndex = 0;
      double maxConfidence = outputArray[0];
      
      for (int i = 1; i < outputArray.length; i++) {
        if (outputArray[i] > maxConfidence) {
          maxIndex = i;
          maxConfidence = outputArray[i];
        }
      }
      
      // Convert label to emotion type
      final predictedLabel = _labels[maxIndex];
      _currentEmotion = EmotionType.values.firstWhere(
        (e) => e.toString().split('.').last == predictedLabel,
        orElse: () => EmotionType.Neutral
      );
      
      _logger.info('Detected emotion: $_currentEmotion (confidence: ${maxConfidence.toStringAsFixed(2)})');
      _errorMessage = null;
      notifyListeners();
      
      return _currentEmotion;
    } catch (e) {
      _errorMessage = 'Error detecting emotion: $e';
      notifyListeners();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<List<double>> _preprocessImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // Create a square crop of the image (centered)
      final size = min(image.width, image.height);
      final x = (image.width - size) ~/ 2;
      final y = (image.height - size) ~/ 2;
      
      // Resize to 224x224
      final ui.Image croppedImage = await _cropAndResizeImage(
        image,
        x,
        y,
        size,
        size,
        224,
        224,
      );

      // Convert to bytes and normalize
      final buffer = await _imageToBuffer(croppedImage);
      final List<double> normalizedBuffer = [];

      // Convert to RGB and normalize to 0-1
      for (int i = 0; i < buffer.length; i += 4) {
        normalizedBuffer.add(buffer[i] / 255.0);     // R
        normalizedBuffer.add(buffer[i + 1] / 255.0); // G
        normalizedBuffer.add(buffer[i + 2] / 255.0); // B
      }

      return normalizedBuffer;
    } catch (e) {
      _errorMessage = 'Error preprocessing image: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<ui.Image> _cropAndResizeImage(
    ui.Image image,
    int x,
    int y,
    int width,
    int height,
    int targetWidth,
    int targetHeight,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Draw cropped and resized image
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    final src = Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
    final dst = Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
    canvas.drawImageRect(image, src, dst, paint);

    final picture = pictureRecorder.endRecording();
    return await picture.toImage(targetWidth, targetHeight);
  }

  Future<List<int>> _imageToBuffer(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData!.buffer.asUint8List();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter.close();
    super.dispose();
  }
}