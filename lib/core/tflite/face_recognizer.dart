// lib/core/tflite/face_recognizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

const int _inputSize = 112;
const int _outputSize = 192;

class FaceRecognizer {
  late Interpreter _interpreter;
  static const String _modelPath = 'assets/face_recognition.map';

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
      print('✅ TFLite model loaded successfully from assets: $_modelPath');
    } catch (e) {
      print('❌ Failed to load TFLite model: $e');
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

  /// محاسبه شباهت کسینوسی (Cosine Similarity)
  double _calculateCosineSimilarity(List<double> emb1, List<double> emb2) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < emb1.length; i++) {
      dotProduct += emb1[i] * emb2[i];
      normA += emb1[i] * emb1[i];
      normB += emb2[i] * emb2[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// نرمال‌سازی بردار (L2 Normalization)
  List<double> _normalizeEmbedding(List<double> embedding) {
    double norm = 0.0;
    for (final value in embedding) {
      norm += value * value;
    }
    norm = sqrt(norm);

    if (norm == 0) return embedding;

    return embedding.map((value) => value / norm).toList();
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

    _inputBuffer.fillRange(0, _inputBuffer.length, 0.0);

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);

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
      print('📸 Processing image: $imagePath');

      final bytes = File(imagePath).readAsBytesSync();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        print('❌ Failed to decode image: $imagePath');
        return null;
      }

      final inputTensor = _preProcess(originalImage);
      final outputBuffer = Float32List(_outputSize);
      final outputMap = {0: outputBuffer};

      _interpreter.run(inputTensor, outputMap);

      // نرمال‌سازی embedding
      final normalizedEmbedding = _normalizeEmbedding(
        outputBuffer.toList(growable: false),
      );

      print(
        '✅ Embedding extracted successfully (${normalizedEmbedding.length} dimensions)',
      );
      return normalizedEmbedding;
    } catch (e) {
      print('❌ Error running inference: $e');
      return null;
    }
  }

  /// مقایسه دو چهره
  Future<bool> compare(
    String liveImagePath,
    List<double> savedEmbedding,
  ) async {
    print('🔍 Starting face comparison...');

    final liveEmbedding = await getFaceEmbedding(liveImagePath);

    if (liveEmbedding == null) {
      print('❌ Failed to extract embedding from live image.');
      return false;
    }

    // محاسبه فاصله اقلیدسی
    final distance = _calculateDistance(liveEmbedding, savedEmbedding);

    // محاسبه شباهت کسینوسی
    final cosineSim = _calculateCosineSimilarity(liveEmbedding, savedEmbedding);

    // آستانه‌های قابل تنظیم
    const double distanceThreshold = 1.0; // کمتر = یکسان‌تر
    const double cosineThreshold = 0.5; // بیشتر = یکسان‌تر

    print(
      '📊 Distance: ${distance.toStringAsFixed(4)} (threshold: $distanceThreshold)',
    );
    print(
      '📊 Cosine Similarity: ${cosineSim.toStringAsFixed(4)} (threshold: $cosineThreshold)',
    );

    // استفاده از هر دو معیار برای تصمیم‌گیری دقیق‌تر
    final isMatch =
        (distance <= distanceThreshold) && (cosineSim >= cosineThreshold);

    print(
      isMatch
          ? '✅ MATCH - Faces are the same person!'
          : '❌ NO MATCH - Different persons',
    );

    return isMatch;
  }

  /// آزادسازی منابع
  void close() {
    _interpreter.close();
  }
}
