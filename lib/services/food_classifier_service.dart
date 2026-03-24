import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FoodClassifierService {
  static FoodClassifierService? _instance;
  late Interpreter _interpreter;
  bool _isInitialized = false;

  FoodClassifierService._();

  static FoodClassifierService get instance =>
      _instance ??= FoodClassifierService._();

  // Initialize TFLite model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final gpuDelegateV2 = GpuDelegateV2(
        options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false,
        ),
      );

      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: InterpreterOptions()..addDelegate(gpuDelegateV2),
      );

      _isInitialized = true;
    } catch (e) {
      print('Error loading model: $e');
      // Fallback to CPU if GPU fails
      try {
        _interpreter = await Interpreter.fromAsset(
          'assets/models/model.tflite',
          options: InterpreterOptions(),
        );
        _isInitialized = true;
      } catch (e) {
        print('Error loading model on CPU: $e');
        rethrow;
      }
    }
  }

  // Classify image from file
  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Read image file
      final imageBytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw 'ไม่สามารถอ่านรูปภาพได้';
      }

      return _classifyDecoded(image);
    } catch (e) {
      throw 'เกิดข้อผิดพลาดในการประมวลผลรูปภาพ: $e';
    }
  }

  // Classify decoded image
  Future<ClassificationResult> _classifyDecoded(img.Image image) async {
    try {
      // Resize to 224x224
      final resized = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // Convert to float32 array and normalize
      final input = _preprocessImage(resized);

      // Run inference - output shape should be [1, 2]
      final output = [List<double>.filled(2, 0.0)];
      _interpreter.run(input, output);

      // Parse results
      final foodScore = output[0][0].toDouble(); // Raw score for food
      final nonFoodScore = output[0][1].toDouble(); // Raw score for non-food

      // Apply softmax to normalize scores to [0, 1] range
      final normalizedScores = _softmax([foodScore, nonFoodScore]);
      final normalizedFoodScore = normalizedScores[0];
      final normalizedNonFoodScore = normalizedScores[1];

      // Determine if image is food
      final isFood = normalizedFoodScore > normalizedNonFoodScore;
      final confidence = isFood ? normalizedFoodScore : normalizedNonFoodScore;

      return ClassificationResult(
        isFood: isFood,
        confidence: confidence,
        foodScore: normalizedFoodScore,
        nonFoodScore: normalizedNonFoodScore,
      );
    } catch (e) {
      throw 'เกิดข้อผิดพลาดในการจำแนกรูปภาพ: $e';
    }
  }

  // Preprocess image with proper normalization
  // Input: 224x224 RGB image
  // Output: Float32 array normalized for MobileNet v2
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // ImageNet normalization values
    const List<double> meanValues = [0.485, 0.456, 0.406]; // RGB means
    const List<double> stdValues = [0.229, 0.224, 0.225]; // RGB stds

    // Create 4D tensor [1, 224, 224, 3]
    final List<List<List<List<double>>>> input =
        List.generate(1, (_) => List.generate(224, (_) => List.generate(224, (_) => List.filled(3, 0.0))));

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = image.getPixelSafe(x, y);
        
        // Extract RGB channels
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // Normalize to [0, 1]
        double normR = r / 255.0;
        double normG = g / 255.0;
        double normB = b / 255.0;

        // Apply ImageNet normalization
        normR = (normR - meanValues[0]) / stdValues[0];
        normG = (normG - meanValues[1]) / stdValues[1];
        normB = (normB - meanValues[2]) / stdValues[2];

        input[0][y][x][0] = normR;
        input[0][y][x][1] = normG;
        input[0][y][x][2] = normB;
      }
    }

    return input;
  }

  // Apply softmax to normalize scores to [0, 1] range
  List<double> _softmax(List<double> scores) {
    // Subtract max for numerical stability
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final expScores = scores.map((s) => exp(s - maxScore)).toList();
    
    final sumExp = expScores.fold<double>(0.0, (sum, e) => sum + e);
    return expScores.map((e) => e / sumExp).toList();
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
    }
  }
}

class ClassificationResult {
  final bool isFood;
  final double confidence; // 0.0-1.0
  final double foodScore; // Raw score for food class
  final double nonFoodScore; // Raw score for non-food class

  ClassificationResult({
    required this.isFood,
    required this.confidence,
    required this.foodScore,
    required this.nonFoodScore,
  });

  String get statusText => isFood ? 'อาหาร ✓' : 'ไม่ใช่อาหาร ✗';
  String get confidenceText => '${(confidence * 100).toStringAsFixed(1)}%';
}
