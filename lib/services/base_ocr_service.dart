import '../core/models/ocr_result.dart';

/// Abstract base class for OCR services
/// All OCR implementations must extend this
abstract class BaseOcrService {
  Future<OcrResult> recognizeText(String imagePath);
}
