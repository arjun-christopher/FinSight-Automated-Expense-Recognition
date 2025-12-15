/// Model representing the result of OCR text recognition
class OcrResult {
  /// The full raw text extracted from the image
  final String rawText;

  /// Individual text blocks detected
  final List<TextBlockData> textBlocks;

  /// Whether the OCR was successful
  final bool success;

  /// Optional error message if OCR failed
  final String? errorMessage;

  /// Timestamp when OCR was performed
  final DateTime timestamp;

  /// Confidence level (0.0 to 1.0) - average of all text blocks
  final double? confidence;

  const OcrResult({
    required this.rawText,
    required this.textBlocks,
    required this.success,
    this.errorMessage,
    required this.timestamp,
    this.confidence,
  });

  /// Factory constructor for successful OCR
  factory OcrResult.success({
    required String rawText,
    required List<TextBlockData> textBlocks,
    double? confidence,
  }) {
    return OcrResult(
      rawText: rawText,
      textBlocks: textBlocks,
      success: true,
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  /// Factory constructor for failed OCR
  factory OcrResult.failure({
    required String errorMessage,
  }) {
    return OcrResult(
      rawText: '',
      textBlocks: [],
      success: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  /// Check if OCR result has any text
  bool get hasText => rawText.isNotEmpty;

  /// Get number of text blocks detected
  int get textBlockCount => textBlocks.length;

  /// Get all detected text as a single string with line breaks
  String get formattedText => textBlocks.map((block) => block.text).join('\n');

  /// Get lines of text (split by newlines)
  List<String> get lines => rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();

  @override
  String toString() {
    if (!success) {
      return 'OcrResult(success: false, error: $errorMessage)';
    }
    return 'OcrResult(success: true, textBlocks: ${textBlocks.length}, confidence: $confidence)';
  }
}

/// Represents a single text block detected by OCR
class TextBlockData {
  /// The text content of this block
  final String text;

  /// Bounding box coordinates (x, y, width, height)
  final BoundingBox? boundingBox;

  /// Confidence level for this text block (0.0 to 1.0)
  final double? confidence;

  /// List of individual lines within this block
  final List<String> lines;

  const TextBlockData({
    required this.text,
    this.boundingBox,
    this.confidence,
    required this.lines,
  });

  @override
  String toString() => 'TextBlock(text: "$text", lines: ${lines.length})';
}

/// Bounding box coordinates for detected text
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Get the center point of the bounding box
  Point get center => Point(x + width / 2, y + height / 2);

  @override
  String toString() => 'BoundingBox(x: $x, y: $y, w: $width, h: $height)';
}

/// Simple point class for coordinates
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  @override
  String toString() => 'Point($x, $y)';
}
