import 'package:flutter_ocr_native/flutter_ocr_native.dart';

Future<String> extractPosterText(String imagePath) async {
  final result = await OcrReader().readFromPath(imagePath);
  return result.text;
}
