// lib/core/utils/debug_embedding_helper.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lms/api_client.dart';

class DebugEmbeddingHelper {
  static const String _EMBEDDING_KEY = 'user_face_embedding';
  static final FlutterSecureStorage _storage = ApiClient.instance.storage;

  /// بررسی اینکه آیا embedding ذخیره شده است
  static Future<void> checkEmbedding() async {
    print('\n═══════════════════════════════════');
    print('🔍 DEBUG: Checking Saved Embedding');
    print('═══════════════════════════════════');

    final embeddingString = await _storage.read(key: _EMBEDDING_KEY);

    if (embeddingString == null) {
      print('❌ NO EMBEDDING FOUND IN STORAGE');
      print('Key: $_EMBEDDING_KEY');
    } else {
      final values = embeddingString.split(',');
      print('✅ EMBEDDING FOUND!');
      print('Key: $_EMBEDDING_KEY');
      print('Length: ${values.length} values');
      print('First 5 values: ${values.take(5).join(', ')}...');
      print('Last 5 values: ...${values.skip(values.length - 5).join(', ')}');
    }

    print('═══════════════════════════════════\n');
  }

  /// پاک کردن embedding ذخیره شده (برای تست)
  static Future<void> clearEmbedding() async {
    await _storage.delete(key: _EMBEDDING_KEY);
    print('🗑️ Embedding cleared from storage');
  }

  /// ذخیره یک embedding تستی
  static Future<void> saveTestEmbedding() async {
    final testEmbedding = List.generate(192, (i) => i * 0.01);
    final embeddingString = testEmbedding.join(',');
    await _storage.write(key: _EMBEDDING_KEY, value: embeddingString);
    print('✅ Test embedding saved (192 values)');
  }
}
