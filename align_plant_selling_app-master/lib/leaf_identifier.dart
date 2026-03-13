import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({Key? key}) : super(key: key);

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  File? file;
  String resultText = "No image selected";
  Interpreter? _interpreter;

  // Define your class names
  final List<String> classNames = [
    'apple',
    'blueberry',
    'cherry',
    'corn',
    'grape',
    'peach',
    'pepper',
    'potato',
    'raspberry',
    'soybean_healthy',
    'strawberry',
    'tomato'
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/modelplant.tflite');
      print('Model loaded successfully.');
    } catch (e) {
      print('Error loading model: $e');
    }
  }


  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _image = image;
        file = File(image.path);
      });

      // Process the image so it can be inserted iin model
      var processedImage = await processImage(file!);
      detectImage(processedImage);
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<Float32List> processImage(File image) async {
    final rawImage = await image.readAsBytes();
    final decodedImage = img.decodeImage(rawImage)!;

    // Resize image to match model input size
    final imageInput = img.copyResize(decodedImage, width: 224, height: 224);


    List<double> imageAsFloat32List = [];
    for (int y = 0; y < imageInput.height; y++) {
      for (int x = 0; x < imageInput.width; x++) {
        final pixel = imageInput.getPixel(x, y);
        imageAsFloat32List.add(
            (img.getRed(pixel) - 127.5) / 127.5); // Normalize red
        imageAsFloat32List.add(
            (img.getGreen(pixel) - 127.5) / 127.5); // Normalize green
        imageAsFloat32List.add(
            (img.getBlue(pixel) - 127.5) / 127.5); // Normalize blue
      }
    }

    Float32List inputArray = Float32List(
        1 * 224 * 224 * 3); // 1 image, 224x224, 3 channels
    for (int i = 0; i < imageAsFloat32List.length; i++) {
      inputArray[i] = imageAsFloat32List[i];
    }

    return inputArray; // shape=[1, 224, 224, 3]
  }


  Future<void> detectImage(Float32List imageBytes) async {
    if (_interpreter == null) {
      print('Interpreter is not initialized');
      setState(() {
        resultText = 'Interpreter is not initialized';
      });
      return;
    }

    try {
      var output = List.filled(1 * 12, 0.0).reshape([1, 12]);

      _interpreter!.run(imageBytes.reshape([1, 224, 224, 3]), output);

      processOutput(output.cast<List<double>>());

      print('Recognition Results: $output');
    } catch (e) {
      print('Error during image detection: $e');
      setState(() {
        resultText = 'Error during image detection';
      });
    }
  }

  void processOutput(List<List<double>> output) {
    // Find the index of the class with the highest score
    int predictedClassIndex = output[0].indexWhere((value) =>
    value == output[0].reduce(max));
    double confidence = output[0][predictedClassIndex];

    // Get the class name based on the predicted index
    String predictedClassName = classNames[predictedClassIndex];


    print(
        'Predicted class: $predictedClassName (Index: $predictedClassIndex) with confidence: $confidence');


    setState(() {
      resultText =
      'Predicted: $predictedClassName\nConfidence: ${confidence.toStringAsFixed(
          2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find out your Leaf',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/backg.jpg'),
              fit: BoxFit.cover,
              opacity: 0.7,
            ),
          ),
        ),
      ),
      body:
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null)
              Image.file(
                File(_image!.path),
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
            else
              const Text(
                'Pick an image to identify',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30,
                  fontWeight:FontWeight.bold,
                ),
              ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text(
                'Pick Image from Gallery',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(resultText),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
