import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

Future<String> extractPosterText(String imagePath) =>
    FlutterTesseractOcr.extractText(imagePath, language: 'eng');
