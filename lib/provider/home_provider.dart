import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:textapp/service/utils.dart';

class ImageGeneratorProvider with ChangeNotifier {
  final TextEditingController textController = TextEditingController();

  String? originalImageUrl;
  String? processedImageUrl;
  String? promt;
  String? vedioUrl;
  String? errormsg;
  int? step;
  String? multiImg;

  bool isLoading = false;
  bool isSelected = false;
  bool isTextToImageLoading = false;
  bool isEnhanceImageLoading = false;
  bool isVideoGenerating = false;

  Map<String, String> imgmodelsMap = {};
  Set<String> removedimgModels = {};
  Map<String, String> videomodelsMap = {};
  Set<String> removedvideoModels = {};
  String? selectedimgModel;
  String? selectedvideoModel;
  List imgUrl = [];


  /// API Call
  /// 
  /// fetch the img model

  Future<void> fetchImgModels() async {
    try {
      final response = await http.get(Uri.parse('$baseurl/img_models'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        imgmodelsMap = Map<String, String>.from(data['models']);

        if (imgmodelsMap.isNotEmpty) {
          selectedimgModel = imgmodelsMap.keys.first;
        }
        notifyListeners();
      } else {
        errormsg = 'Failed to load models: ${response.reasonPhrase}';
        notifyListeners();
        print(errormsg);
      }
    } catch (e) {
      errormsg = 'Error fetching models: $e';
      notifyListeners();
      print(errormsg);
    }
  }

  /// fetch the video model

  Future<void> fetchVideoModels() async {
    try {
      final response = await http.get(Uri.parse('$baseurl/video_models'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        videomodelsMap = Map<String, String>.from(data['models']);

        if (videomodelsMap.isNotEmpty) {
          selectedvideoModel = videomodelsMap.keys.first;
        }
        notifyListeners();
      } else {
        errormsg = 'Failed to load models: ${response.reasonPhrase}';
        notifyListeners();
        print(errormsg);
      }
    } catch (e) {
      errormsg = 'Error fetching models: $e';
      notifyListeners();
      print(errormsg);
    }
  }

  void setSelectedModel(String model) {
    if (!removedimgModels.contains(model)) {
      selectedimgModel = model;
      notifyListeners();
    }
  }

  void toggleModel(String modelName) {
    if (removedimgModels.contains(modelName)) {
      removedimgModels.remove(modelName);
    } else {
      removedimgModels.add(modelName);
      if (selectedimgModel == modelName) {
        selectedimgModel = null;
      }
    }
    notifyListeners();
  }

  void setSelectedModel1(String model) {
    if (!removedvideoModels.contains(model)) {
      selectedvideoModel = model;
      notifyListeners();
    }
  }

  void toggleModel1(String modelName) {
    if (removedvideoModels.contains(modelName)) {
      removedvideoModels.remove(modelName);
    } else {
      removedvideoModels.add(modelName);
      if (selectedvideoModel == modelName) {
        selectedvideoModel = null;
      }
    }
    notifyListeners();
  }


  /// generate the img and video based on the selected step

  Future<void> generateImageFlow(String prompt, int tapStep) async {
    log('tapStep: $tapStep');
    step = tapStep;
    log('step: $step');
    isLoading = true;
    isTextToImageLoading = false;
    isEnhanceImageLoading = false;
    isVideoGenerating = false;
    errormsg = null;

    if (tapStep == 0) {
      originalImageUrl = null;
      processedImageUrl = null;
      promt = null;
      vedioUrl = null;
    }

    notifyListeners();

    try {
      isTextToImageLoading = true;
      notifyListeners();

      final imageResponse = await http.post(
        Uri.parse('$baseurl/text-to-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': prompt, 'modelName': selectedimgModel}),
      );

      if (imageResponse.statusCode != 200) {
        throw Exception(
          'Image generation failed: ${imageResponse.reasonPhrase}',
        );
      }

      final imageData = json.decode(imageResponse.body);
      originalImageUrl = imageData['imageUrl'];
      promt = imageData['prompt'];

      isTextToImageLoading = false;
      notifyListeners();

      // Step 0:
      if (tapStep == 0) {
        if (isSelected) {
          isVideoGenerating = true;
          notifyListeners();

          final videoResponse = await http.post(
            Uri.parse('$baseurl/generate-video'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'imageUrl': originalImageUrl,
              'prompt': promt,
              'modelName': selectedvideoModel,
            }),
          );

          if (videoResponse.statusCode != 200) {
            throw Exception(
              'Video generation failed: ${videoResponse.reasonPhrase}',
            );
          }

          final videoData = json.decode(videoResponse.body);
          vedioUrl = videoData['videoUrl'];

          isVideoGenerating = false;
          isLoading = false;
          notifyListeners();
          return;
        } else {}
      }

      // Step 1:
      if (tapStep == 1) {
        isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2:
      if (tapStep == 2) {
        isEnhanceImageLoading = true;
        notifyListeners();

        final enhanceResponse = await http.post(
          Uri.parse('$baseurl/enhance-image'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'imageUrl': originalImageUrl}),
        );

        if (enhanceResponse.statusCode != 200) {
          throw Exception(
            'Image enhancement failed: ${enhanceResponse.reasonPhrase}',
          );
        }

        final enhanceData = json.decode(enhanceResponse.body);
        processedImageUrl = enhanceData['enhancedImageUrl'];

        isEnhanceImageLoading = false;
        notifyListeners();

        isLoading = false;
        notifyListeners();
        return;
      }

      // Step 3:
      if (tapStep == 3) {
        if (isSelected) {
          isVideoGenerating = true;
          notifyListeners();

          final videoResponse = await http.post(
            Uri.parse('$baseurl/generate-video'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'imageUrl': originalImageUrl,
              'prompt': promt,
              'modelName': selectedvideoModel,
            }),
          );

          if (videoResponse.statusCode != 200) {
            throw Exception(
              'Video generation failed: ${videoResponse.reasonPhrase}',
            );
          }

          final videoData = json.decode(videoResponse.body);
          vedioUrl = videoData['videoUrl'];

          isVideoGenerating = false;
          isLoading = false;
          notifyListeners();
          return;
        } else {}
      }

      isEnhanceImageLoading = true;
      notifyListeners();

      final enhanceResponse = await http.post(
        Uri.parse('$baseurl/enhance-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageUrl': originalImageUrl}),
      );

      if (enhanceResponse.statusCode != 200) {
        throw Exception(
          'Image enhancement failed: ${enhanceResponse.reasonPhrase}',
        );
      }

      final enhanceData = json.decode(enhanceResponse.body);
      processedImageUrl = enhanceData['enhancedImageUrl'];

      isEnhanceImageLoading = false;
      notifyListeners();

      if (promt != null && processedImageUrl != null) {
        isVideoGenerating = true;
        notifyListeners();

        final videoResponse = await http.post(
          Uri.parse('$baseurl/generate-video'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'imageUrl': processedImageUrl,
            'prompt': promt,
            'modelName': selectedvideoModel,
          }),
        );

        if (videoResponse.statusCode != 200) {
          throw Exception(
            'Video generation failed: ${videoResponse.reasonPhrase}',
          );
        }

        final videoData = json.decode(videoResponse.body);
        vedioUrl = videoData['videoUrl'];
      } else {
        throw Exception(
          'Missing prompt or enhanced image for video generation.',
        );
      }
    } catch (e) {
      errormsg = 'Flow failed: $e';
      print(errormsg);
    }

    isVideoGenerating = false;
    isLoading = false;
    notifyListeners();
  }

  /// multi img api 

  Future<void> callMultiImageApi() async {
    final headers = {'Content-Type': 'application/json'};

    final url = Uri.parse('$baseurl/multi-Images');

    final body = json.encode({
      "prompt": promt,
      "aspect_ratio": "4:3",
      "imageUrls": imgUrl,
    });

    final request = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = body;

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final decoded = json.decode(resBody);

        multiImg = decoded['enhancedImageUrl'];

        print("✅ Success: ${decoded["message"]}");
        print("🔗 Enhanced Image URL: ${decoded["enhancedImageUrl"]}");
      } else {
        print("❌ Error ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
    }
  }

  void clearAll() {
    isSelected = false;
    originalImageUrl = null;
    processedImageUrl = null;
    vedioUrl = null;
    promt = null;
    errormsg = null;
    step = null;

    isLoading = false;
    isTextToImageLoading = false;
    isEnhanceImageLoading = false;
    isVideoGenerating = false;

    textController.clear();

    notifyListeners();
  }

  // Future<void> generateImageFlow(String prompt, int tapStep) async {
  //   log('tapSteptapStep$tapStep');
  //   // Reset all states
  //   isLoading = true;
  //   isTextToImageLoading = true;
  //   isEnhanceImageLoading = false;
  //   isVideoGenerating = false;

  //   originalImageUrl = null;
  //   processedImageUrl = null;
  //   vedioUrl = null;
  //   errormsg = null;
  //   notifyListeners();

  //   try {
  //     // 1. Text to Image
  //     final imageResponse = await http.post(
  //       Uri.parse('$baseurl/api/text-to-image'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'prompt': prompt, 'modelName': selectedModelName}),
  //     );

  //     if (imageResponse.statusCode != 200) {
  //       throw Exception(
  //         'Image generation failed: ${imageResponse.reasonPhrase}',
  //       );
  //     }

  //     final imageData = json.decode(imageResponse.body);
  //     originalImageUrl = imageData['imageUrl'];
  //     promt = imageData['prompt'];

  //     isTextToImageLoading = false;
  //     isEnhanceImageLoading = true;
  //     notifyListeners();

  //     // 2. Enhance Image
  //     final enhanceResponse = await http.post(
  //       Uri.parse('$baseurl/api/enhance-image'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'imageUrl': originalImageUrl}),
  //     );

  //     if (enhanceResponse.statusCode != 200) {
  //       throw Exception(
  //         'Image enhancement failed: ${enhanceResponse.reasonPhrase}',
  //       );
  //     }

  //     final enhanceData = json.decode(enhanceResponse.body);
  //     processedImageUrl = enhanceData['enhancedImageUrl'];

  //     isEnhanceImageLoading = false;
  //     isVideoGenerating = true;
  //     notifyListeners();

  //     // 3. Generate Video
  //     final videoResponse = await http.post(
  //       Uri.parse('$baseurl/api/generate-video'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'imageUrl': processedImageUrl, 'prompt': promt}),
  //     );

  //     if (videoResponse.statusCode != 200) {
  //       throw Exception(
  //         'Video generation failed: ${videoResponse.reasonPhrase}',
  //       );
  //     }

  //     final videoData = json.decode(videoResponse.body);
  //     vedioUrl = videoData['videoUrl'];
  //   } catch (e) {
  //     errormsg = 'Flow failed: $e';
  //     print(errormsg);
  //   }

  //   isVideoGenerating = false;
  //   isLoading = false;
  //   notifyListeners();
  // }
}


  // Future<void> generateImage(String prompt) async {
  //   isLoading = true;
  //   originalImageUrl = null;
  //   processedImageUrl = null;
  //   vedioUrl = null;
  //   errormsg = null;
  //   notifyListeners();

  //   try {
  //     final request = http.Request(
  //       'POST',
  //       Uri.parse('$baseurl/generate-and-process'),
  //     );
  //     request.body = json.encode({
  //       'prompt': prompt,
  //       'modelName': selectedModelName,
  //     });
  //     request.headers.addAll({'Content-Type': 'application/json'});

  //     final response = await request.send();

  //     if (response.statusCode == 200) {
  //       final responseBody = await response.stream.bytesToString();
  //       final data = json.decode(responseBody);

  //       originalImageUrl = data['imagenUrl'];
  //       processedImageUrl = data['reduxImageUrl'];
  //       vedioUrl =
  //           data['videoUrl'] ??
  //           'The input or output was flagged as sensitive. Please try again with different inputs';
  //     } else {
  //       errormsg = 'Something went wrong: ${response.reasonPhrase}';
  //     }
  //   } catch (e) {
  //     errormsg = 'Request failed: $e';
  //     print(errormsg);
  //   }

  //   isLoading = false;
  //   notifyListeners();
  // }}
