// lib/core/tflite/face_recognizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ثابت‌هایی که معمولاً برای مدل‌های Face Recognition استفاده می‌شوند
const int _inputSize = 112;
const int _outputSize =
    192; // اندازه بردار ویژگی خروجی مدل (مثلاً MobileFaceNet)

class FaceRecognizer {
  late Interpreter _interpreter;
  static const String _modelPath =
      'assets/face_recognition.tflite'; // تغییر .map به .tflite

  static final FaceRecognizer _instance = FaceRecognizer._internal();
  factory FaceRecognizer() => _instance;
  FaceRecognizer._internal();

  final Float32List _inputBuffer = Float32List(_inputSize * _inputSize * 3);

  /// بارگذاری مدل از assets
  Future<void> loadModel() async {
    try {
      final modelData = await rootBundle.load(_modelPath);
      final interpreter = Interpreter.fromBuffer(
        modelData.buffer.asUint8List(),
      );
      _interpreter = interpreter;
      print('TFLite model loaded successfully from assets: $_modelPath');
    } catch (e) {
      print('Failed to load TFLite model: $e');
      rethrow;
    }
  }

  /// محاسبه فاصله اقلیدسی (L2 distance)
  double _calculateDistance(List<double> emb1, List<double> emb2) {
    double sum = 0.0;
    for (int i = 0; i < emb1.length; i++) {
      final diff = emb1[i] - emb2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// پیش‌پردازش تصویر: تغییر اندازه + نرمال‌سازی به [-1, 1]
  Float32List _preProcess(img.Image image) {
    final resizedImage = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
    );
    const double imageMean = 127.5;
    const double imageStd = 127.5;
    int pixelIndex = 0;

    // پاک کردن بافر
    _inputBuffer.fillRange(0, _inputBuffer.length, 0.0);

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // دسترسی به کانال‌های رنگ با استفاده از .r, .g, .b
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        _inputBuffer[pixelIndex++] = (r - imageMean) / imageStd;
        _inputBuffer[pixelIndex++] = (g - imageMean) / imageStd;
        _inputBuffer[pixelIndex++] = (b - imageMean) / imageStd;
      }
    }
    return _inputBuffer;
  }

  /// استخراج بردار ویژگی (Embedding) از تصویر
  Future<List<double>?> getFaceEmbedding(String imagePath) async {
    try {
      final bytes = File(imagePath).readAsBytesSync();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        print('Failed to decode image: $imagePath');
        return null;
      }

      final inputTensor = _preProcess(originalImage);

      // خروجی مدل
      final outputBuffer = Float32List(_outputSize);
      final outputMap = {0: outputBuffer};

      // اجرای مدل
      _interpreter.run(inputTensor, outputMap);

      return outputBuffer.toList(growable: false);
    } catch (e) {
      print('Error running inference: $e');
      return null;
    }
  }

  /// مقایسه دو چهره
  Future<bool> compare(
    String liveImagePath,
    List<double> savedEmbedding,
  ) async {
    final liveEmbedding = await getFaceEmbedding(liveImagePath);

    if (liveEmbedding == null) {
      print('Failed to extract embedding from live image.');
      return false;
    }

    final distance = _calculateDistance(liveEmbedding, savedEmbedding);

    const double distanceThreshold = 1.2; // قابل تنظیم بسته به مدل

    print(
      'Face similarity distance: $distance (threshold: $distanceThreshold)',
    );

    return distance <= distanceThreshold;
  }

  /// آزادسازی منابع (اختیاری)
  void close() {
    _interpreter.close();
  }
}
