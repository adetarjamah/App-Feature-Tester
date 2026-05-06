import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const int INPUT_SIZE = 112;
  static const double MATCH_THRESHOLD = 0.75;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter =
          await Interpreter.fromAsset('mobilefacenet.tflite', options: options);
      _isInitialized = true;
      debugPrint('✅ FaceRecognitionService initialized');
    } catch (e) {
      debugPrint('❌ Failed to init interpreter: $e');
    }
  }

  /// Preprocess gambar: resize → normalize → reshape ke [1, 112, 112, 3]
  Future<List<List<List<List<double>>>>> _preprocessImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(Uint8List.fromList(bytes));

    if (image == null) throw Exception('Gagal decode gambar');

    // Resize ke 112x112
    final resized =
        img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);

    // Normalize ke [-1, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        INPUT_SIZE,
        (y) => List.generate(
          INPUT_SIZE,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Extract face embedding dari gambar
  Future<List<double>?> getEmbedding(File file) async {
    if (!_isInitialized || _interpreter == null) {
      debugPrint('Interpreter belum diinisialisasi');
      return null;
    }

    try {
      final input = await _preprocessImage(file);

      // Ambil output shape dari model
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final embeddingSize = outputShape[1]; // biasanya 128 atau 192 atau 512

      final output = List.generate(1, (_) => List.filled(embeddingSize, 0.0));

      _interpreter!.run(input, output);

      // L2 normalize embedding
      return _l2Normalize(output[0]);
    } catch (e) {
      debugPrint('❌ Error getEmbedding: $e');
      return null;
    }
  }

  /// L2 Normalization agar cosine similarity lebih akurat
  List<double> _l2Normalize(List<double> embedding) {
    double norm = 0.0;
    for (final v in embedding) {
      norm += v * v;
    }
    norm = sqrt(norm);
    if (norm == 0) return embedding;
    return embedding.map((v) => v / norm).toList();
  }

  /// Cosine similarity antara dua embedding
  double compare(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 0.0;

    double dot = 0;
    for (int i = 0; i < e1.length; i++) {
      dot += e1[i] * e2[i];
    }
    // Karena sudah L2-normalized, dot product = cosine similarity
    return dot.clamp(-1.0, 1.0);
  }

  bool isMatch(double similarity) => similarity >= MATCH_THRESHOLD;

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
