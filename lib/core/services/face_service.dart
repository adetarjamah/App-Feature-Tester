import 'dart:io';

class FaceService {
  Future<List<double>> extractEmbedding(File imageFile) async {
    // preprocess image → resize → normalize
    // run tflite model (FaceNet)
    // return embedding vector (128/512 dimensi)
    return [];
  }

  double compare(List<double> e1, List<double> e2) {
    double sum = 0;
    for (int i = 0; i < e1.length; i++) {
      sum += (e1[i] - e2[i]) * (e1[i] - e2[i]);
    }
    return sum; // semakin kecil = semakin mirip
  }
}
