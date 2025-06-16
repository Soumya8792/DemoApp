import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textapp/provider/home_provider.dart';
import 'package:textapp/service/utils.dart';
import 'package:textapp/ui/home/chat_message.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatProvider with ChangeNotifier {

  String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;
  List<Uint8List> webImages = [];
  List<File> mobileImages = [];
  List<String> imgUrl = [];
  List<String> history = [];
  String promt = "";

  final ImageGeneratorProvider imageGeneratorProvider;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? errorMsg;
  String? originalImageUrl;
  String? enhancedImageUrl;
  String? multiImageUrl;
  String? videoUrl;
  String? previousText;
  String? selectedimgModel;
  String? selectedvideoModel;

  bool isImageLoading = false;
  bool isEnhanceLoading = false;
  bool isVideoLoading = false;
  bool isImageUploading = false;
  bool isMultiImgLoading = false;

  late final Box<ChatMessage> _box;

  ChatProvider(this.imageGeneratorProvider) {
    _init();
    reloadMessages();
  }

/// initialization for the Hive
  Future<void> _init() async {
    if (!Hive.isBoxOpen('chat_messages')) {
      _box = await Hive.openBox<ChatMessage>('chat_messages');
    } else {
      _box = Hive.box<ChatMessage>('chat_messages');
    }

    _messages.clear();
    _messages.addAll(_box.values.toList());

    final prefs = await SharedPreferences.getInstance();
    history = prefs.getStringList('chat_history') ?? [];

    notifyListeners();
  }

  Future<void> reloadMessages() async {
    if (!Hive.isBoxOpen('chat_messages')) {
      _box = await Hive.openBox<ChatMessage>('chat_messages');
    } else {
      _box = Hive.box<ChatMessage>('chat_messages');
    }

    _messages
      ..clear()
      ..addAll(_box.values.toList());

    notifyListeners();
  }

  void addUserMessage(String text) {
    final message = ChatMessage(text: text, isUser: true);
    _messages.add(message);
    _box.add(message);
    addToHistory(text);
    notifyListeners();
  }

  void addAIMessage(String text, {Uint8List? image, Uint8List? vedioUrl}) {
    final message = ChatMessage(
      text: text,
      isUser: false,
      image: image,
      videoUrl: vedioUrl,
    );

    _messages.add(message);
    _box.add(message);
    notifyListeners();
  }

  Future<void> clearChat() async {
    await _box.clear();
    _messages.clear();
    originalImageUrl = null;
    enhancedImageUrl = null;
    multiImageUrl = null;
    videoUrl = null;
    notifyListeners();
  }

  void addToHistory(String prompt) {
    if (!history.contains(prompt)) {
      history.insert(0, prompt);
      _saveHistory();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chat_history', history);
  }

  void clearHistory() async {
    history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    notifyListeners();
  }

  /// model dialog box for the img and video model. both web and mobile

  void showModelSelectorDialog(
    BuildContext context,
    Map<String, String> models,
    String? selectedModel,
    void Function(String selected) onSelected, {
    required String title,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        String? tempSelectedModel = selectedModel;

        Widget dialogContent = StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: models.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final modelKey = models.keys.elementAt(index);
                    return RadioListTile<String>(
                      title: Text(
                        modelKey,
                        style: const TextStyle(fontSize: 16),
                      ),
                      value: modelKey,
                      groupValue: tempSelectedModel,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            tempSelectedModel = value;
                          });
                          Future.delayed(const Duration(milliseconds: 200), () {
                            Navigator.of(context).pop();
                            if (context.mounted) onSelected(value);
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            );
          },
        );

        if (kIsWeb) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: dialogContent,
            ),
          );
        } else {
          return dialogContent;
        }
      },
    );
  }

  void updateSelectedImageModel(String model) {
    selectedimgModel = model;
    log('selectedimgModel $selectedimgModel');
    notifyListeners();
  }

  void updateSelectedVideoModel(String model) {
    selectedvideoModel = model;
    log('selectedvideoModel$selectedvideoModel');
    notifyListeners();
  }


/// img picker for the both mobile and web
  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    errorMsg = null;
    notifyListeners();

    if (result != null && result.files.isNotEmpty) {
      if (result.files.length < 2) {
        errorMsg = "At least 2 images are needed";
        notifyListeners();
        return;
      }

      isImageUploading = true;
      notifyListeners();

      if (kIsWeb) {
        webImages = result.files.map((f) => f.bytes!).toList();
        notifyListeners();
        imgUrl = await uploadImagesBytesToFirebase(webImages);
      } else {
        mobileImages = result.paths.map((path) => File(path!)).toList();
        notifyListeners();
        imgUrl = await uploadImagesToFirebase(mobileImages);
      }

      isImageUploading = false;
      notifyListeners();
    }
  }

  /// upload the selected img in firebase - mobile

  Future<List<String>> uploadImagesToFirebase(List<File> images) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'multiimg/image_${i}_$timestamp.jpg';

      try {
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        print("❌ Error uploading image $i: $e");
      }
    }

    return downloadUrls;
  }


  /// upload the selected img in firebase - web
  Future<List<String>> uploadImagesBytesToFirebase(
    List<Uint8List> images,
  ) async {
    List<String> urls = [];
    for (var i = 0; i < images.length; i++) {
      try {
        final ref = FirebaseStorage.instance.ref(
          'web/image_$i${DateTime.now().millisecondsSinceEpoch}.png',
        );
        final uploadTask = await ref.putData(images[i]);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print("❌ Web upload error at $i: $e");
      }
    }
    return urls;
  }

  void clearAllImages() {
    webImages.clear();
    mobileImages.clear();
    notifyListeners();
  }


  /// API Call for the fetcting and generate the img and video 

  Future<void> callMultiImageApi(String text) async {
    if (imgUrl.isEmpty || promt.trim().isEmpty) {
      print("❌ Prompt or image URLs missing.");
      return;
    }

    webImages.clear();
    mobileImages.clear();
    isMultiImgLoading = true;
    notifyListeners();

    final headers = {'Content-Type': 'application/json'};
    final url = Uri.parse('$baseurl/multi-Images');

    final body = json.encode({
      "prompt": text,
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

        multiImageUrl = decoded['enhancedImageUrl'];
        final imageBytesResponse = await http.get(Uri.parse(multiImageUrl!));

        addAIMessage(
          'Multi-image Generated',
          image: imageBytesResponse.bodyBytes,
        );
        print("✅ Success: ${decoded["message"]}");
      } else {
        print("❌ Error ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
    }

    isMultiImgLoading = false;
    notifyListeners();
  }

  Future<void> generateImage(String prompt) async {
    if (prompt.isEmpty) {
      errorMsg = 'Prompt cannot be empty.';
      log('errorMsg: $errorMsg');
      notifyListeners();
      return;
    }
    errorMsg = null;

    _isLoading = true;
    isImageLoading = true;
    notifyListeners();

    try {
      final imageResponse = await http.post(
        Uri.parse('$baseurl/text-to-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'modelName': imageGeneratorProvider.selectedimgModel,
        }),
      );

      if (imageResponse.statusCode == 200) {
        final imageData = json.decode(imageResponse.body);
        originalImageUrl = imageData['imageUrl'];
        previousText = imageData['prompt'];

        final imageBytesResponse = await http.get(Uri.parse(originalImageUrl!));
        addAIMessage(prompt, image: imageBytesResponse.bodyBytes);
      } else {
        errorMsg = 'Image generation failed: ${imageResponse.reasonPhrase}';
        log('errorMsg$errorMsg');
      }
    } catch (e) {
      errorMsg = 'Error: $e';
      log('errorMsg$errorMsg');
    }

    _isLoading = false;
    isImageLoading = false;
    notifyListeners();
  }

  Future<void> generateEnhancedImage(String prompt) async {
    if (prompt.isEmpty) {
      errorMsg = 'Prompt cannot be empty.';
      notifyListeners();
      return;
    }
    errorMsg = null;
    _isLoading = true;
    isEnhanceLoading = true;
    notifyListeners();

    try {
      if (previousText != prompt) {
        await generateImage(prompt);
        if (originalImageUrl == null) {
          _isLoading = false;
          return;
        }
      }

      final res = await http.post(
        Uri.parse('$baseurl/enhance-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageUrl': originalImageUrl}),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        enhancedImageUrl = data['enhancedImageUrl'];

        final imageRes = await http.get(Uri.parse(enhancedImageUrl!));
        addAIMessage('Enhanced Image', image: imageRes.bodyBytes);
      } else {
        errorMsg = 'Failed to enhance image.';
      }
    } catch (e) {
      errorMsg = 'Error: $e';
    }

    _isLoading = false;
    isEnhanceLoading = false;
    notifyListeners();
  }

  Future<void> generateVideo(String prompt) async {
    if (prompt.isEmpty) {
      errorMsg = 'Prompt cannot be empty.';
      notifyListeners();
      return;
    }

    errorMsg = null;
    _isLoading = true;
    isVideoLoading = true;
    notifyListeners();

    try {
      if (previousText != prompt) {
        await generateImage(prompt);
        if (originalImageUrl == null) {
          errorMsg = 'Image generation failed. Cannot continue.';
          _isLoading = false;
          isVideoLoading = false;
          notifyListeners();
          return;
        }

        await generateEnhancedImage(prompt);
      }

      final imageUrlToUse = enhancedImageUrl ?? originalImageUrl;
      if (imageUrlToUse == null) {
        errorMsg = 'No valid image available for video generation.';
        _isLoading = false;
        isVideoLoading = false;
        notifyListeners();
        return;
      }

      final res = await http.post(
        Uri.parse('$baseurl/generate-video'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'imageUrl': imageUrlToUse,
          'prompt': prompt,
          'modelName': imageGeneratorProvider.selectedvideoModel,
        }),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        videoUrl = data['videoUrl'];

        final videoBytesResponse = await http.get(Uri.parse(videoUrl!));

        addAIMessage('Generated video', vedioUrl: videoBytesResponse.bodyBytes);
      } else {
        errorMsg = 'Failed to generate video: ${res.body}';
        log('Video API Error: ${res.body}');
      }
    } catch (e) {
      errorMsg = 'Error: $e';
    }

    _isLoading = false;
    isVideoLoading = false;
    notifyListeners();
  }
}






  // Future<void> storeMessageInFirestore({
  //   required String userId,
  //   required String prompt,
  //   String? imageUrl,
  //   String? videoUrl,
  //   required bool isUser,
  // }) async {
  //   try {
  //     await _firestore
  //         .collection('chats')
  //         .doc(userId)
  //         .collection('messages')
  //         .add({
  //           'text': prompt,
  //           'imageUrl': imageUrl,
  //           'videoUrl': videoUrl,
  //           'isUser': isUser,
  //           'timestamp': FieldValue.serverTimestamp(),
  //         });
  //   } catch (e) {
  //     print("❌ Error saving to Firestore: $e");
  //   }
  // }




















  // Future<void> fetchChatHistory(String userId) async {
  //   final snapshot = await _firestore
  //       .collection('chats')
  //       .doc(userId)
  //       .collection('messages')
  //       .orderBy('timestamp')
  //       .get();

  //   messages.clear();

  //   for (var doc in snapshot.docs) {
  //     final data = doc.data();

  //     Uint8List? img;
  //     Uint8List? video;

  //     try {
  //       if (data['imageUrl'] != null &&
  //           data['imageUrl'].toString().isNotEmpty) {
  //         final imgRes = await http.get(Uri.parse(data['imageUrl']));
  //         if (imgRes.statusCode == 200) {
  //           img = imgRes.bodyBytes;
  //         }
  //       }

  //       if (data['videoUrl'] != null &&
  //           data['videoUrl'].toString().isNotEmpty) {
  //         final vidRes = await http.get(Uri.parse(data['videoUrl']));
  //         if (vidRes.statusCode == 200) {
  //           video = vidRes.bodyBytes;
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint('Error loading media: $e');
  //     }

  //     messages.add(
  //       ChatMessage(
  //         text: data['text'] ?? '',
  //         senderId: data['senderId'],
  //         isUser: data['senderId'] == FirebaseAuth.instance.currentUser?.uid,
  //         image: img,
  //         videoUrl: video,
  //       ),
  //     );
  //   }

  //   notifyListeners();
  // }

// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:stability_image_generation/stability_image_generation.dart';
// import '../ui/home/chat_message.dart';

// class ChatProvider extends ChangeNotifier {
//   final StabilityAI _ai = StabilityAI();
//   final String apiKey = 'sk-W2TUswiUDwZmGxPE5DEKjRNUwQsoZMI6MBZIrDwERa0UjUxl';
//   final ImageAIStyle imageAIStyle = ImageAIStyle.digitalPainting;

//   final List<ChatMessage> _messages = [];
//   List<ChatMessage> get messages => _messages;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   String? _error;
//   String? get error => _error;

//   late final Box<ChatMessage> _box;

//   ChatProvider() {
//     _init();
//   }

//   Future<void> _init() async {
//     _box = Hive.box<ChatMessage>('chat_messages');
//     _messages.clear();
//     _messages.addAll(_box.values.toList());
//     notifyListeners();
//   }

//   void addUserMessage(String text) {
//     final message = ChatMessage(text: text, image: null, isUser: true);
//     _messages.add(message);
//     _box.add(message);
//     notifyListeners();
//   }

//   Future<void> generateImage(String prompt) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final image = await _ai.generateImage(
//         apiKey: apiKey,
//         imageAIStyle: imageAIStyle,
//         prompt: prompt,
//       );

//       if (image.isNotEmpty) {
//         final aiMessage = ChatMessage(text: prompt, image: image, isUser: false);
//         _messages.add(aiMessage);
//         _box.add(aiMessage);
//       } else {
//         _error = 'No image was generated.';
//       }
//     } catch (e) {
//       _error = e.toString();
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> clearChat() async {
//     await _box.clear();
//     _messages.clear();
//     notifyListeners();
//   }
// }
