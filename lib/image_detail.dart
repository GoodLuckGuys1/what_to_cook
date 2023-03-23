import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'text_detector.dart';
class DetailScreen extends StatefulWidget {
  final String imagePath;

  const DetailScreen({super.key, required this.imagePath});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final String _imagePath;
  late final TextRecognizer _textRecognizer;
  Size? _imageSize;
  final List<TextElement> _elements = [];

  List<String>? _listEmailStrings;


  @override
  void initState() {
    _imagePath = widget.imagePath;
    // Initializing the text detector
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _recognizeEmails();
    super.initState();
  }

  @override
  void dispose() {
    // Disposing the text detector when not used anymore
    _textRecognizer.close();
    super.dispose();
  }


  // Fetching the image size from the image file
  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();
    final Image image = Image.file(imageFile);

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;

    setState(() {
      _imageSize = imageSize;
    });
  }

  void _recognizeEmails() async {
    _getImageSize(File(_imagePath));
    // Creating an InputImage object using the image path
    final inputImage = InputImage.fromFilePath(_imagePath);
// Retrieving the RecognisedText from the InputImage
    final text = await _textRecognizer.processImage(inputImage);

    // Regular expression for verifying an email address
    String pattern = r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
    RegExp regEx = RegExp(pattern);

    List<String> emailStrings = [];

// Finding and storing the text String(s)
    for (TextBlock block in text.blocks) {
      for (TextLine line in block.lines) {
        if (regEx.hasMatch(line.text)) {
          emailStrings.add(line.text);
          // Retrieve the elements and store them in a list
          for (TextElement element in line.elements) {
            _elements.add(element);
          }
        }
      }
    }

    setState(() {
      _listEmailStrings = emailStrings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Details"),
      ),
      body: _imageSize != null
          ? Stack(
        children: [
          Container(
            width: double.maxFinite,
            color: Colors.black,
            child: CustomPaint(
              foregroundPainter: TextDetectorPainter(
                _imageSize!,
                _elements,
              ),
              child: AspectRatio(
                aspectRatio: _imageSize!.aspectRatio,
                child: Image.file(
                  File(_imagePath),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Identified emails",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      child: SingleChildScrollView(
                        child: _listEmailStrings != null
                            ? ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _listEmailStrings!.length,
                          itemBuilder: (context, index) =>
                              Text(_listEmailStrings![index]),
                        )
                            : Container(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
          : Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }


}