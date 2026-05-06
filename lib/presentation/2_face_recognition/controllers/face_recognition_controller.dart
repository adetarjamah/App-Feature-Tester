import 'dart:io';
import 'package:appfeaturetester/core/services/face_recognition_service.dart';
import 'package:get/get.dart';

class FaceRecognitionController extends GetxController {
  var image1 = Rx<File?>(null);
  var image2 = Rx<File?>(null);

  var result = "".obs;

  var embedding1 = Rx<List<double>>([]);
  var embedding2 = Rx<List<double>>([]);

  final faceService = FaceRecognitionService();

  @override
  void onInit() {
    super.onInit();
    faceService.init();
  }

  // HAPUS semua camera logic dari sini

  void setImage1(File file) async {
    image1.value = file;

    final emb = await faceService.getEmbedding(file);
    embedding1.value = emb!;
  }

  void setImage2(File file) async {
    image2.value = file;

    final emb = await faceService.getEmbedding(file);
    embedding2.value = emb!;
  }

  void compareFaces() {
    if (embedding1.value.isEmpty || embedding2.value.isEmpty) {
      result.value = "Embedding belum siap!";
      return;
    }

    final similarity = faceService.compare(embedding1.value, embedding2.value);

    if (similarity > 0.8) {
      result.value = "✅ MATCH (${similarity.toStringAsFixed(3)})";
    } else {
      result.value = "❌ NOT MATCH (${similarity.toStringAsFixed(3)})";
    }
  }
}
