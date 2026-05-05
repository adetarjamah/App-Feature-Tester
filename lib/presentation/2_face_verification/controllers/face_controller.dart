import 'dart:io';
import 'package:get/get.dart';

class FaceController extends GetxController {
  var image1 = Rx<File?>(null);
  var image2 = Rx<File?>(null);
  var result = "".obs;

  void setImage1(File file) {
    image1.value = file;
  }

  void setImage2(File file) {
    image2.value = file;
  }

  void compareFaces() {
    if (image1.value == null || image2.value == null) {
      result.value = "Ambil 2 gambar dulu!";
      return;
    }

    // ⚠️ sementara dummy compare
    // nanti bisa diganti FaceNet embedding
    result.value = "Wajah kemungkinan cocok (dummy)";
  }
}
