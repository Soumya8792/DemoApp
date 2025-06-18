import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textapp/model/message_model.dart';
import 'package:textapp/model/send_message_model.dart';
import 'package:textapp/model/updaet_message_model.dart';
import 'package:textapp/provider/home_provider.dart';
import 'package:textapp/service/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatProvider with ChangeNotifier {
  List<Data> _messages = [];
  List<Data> get messages => _messages;

  List<Uint8List> webImages = [];
  List<File> mobileImages = [];
  List<String> imgUrl = [];
  List<String> history = [];
  String promt = "";
  String? userId;

  final ImageGeneratorProvider imageGeneratorProvider;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _disposed = false;

  String? errorMsg;
  String? originalImageUrl;
  String? enhancedImageUrl;
  String? multiImageUrl;
  String? videoUrl;
  String? previousText;
  String? selectedimgModel;
  String? selectedvideoModel;
  String? messageId;
  String? msg;

  bool isImageLoading = false;
  bool isEnhanceLoading = false;
  bool isVideoLoading = false;
  bool isImageUploading = false;
  bool isMultiImgLoading = false;

  ChatProvider(this.imageGeneratorProvider) {
    _init();

    fetchMessagesByUser(userId!);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// initialization for the Hive
  Future<void> _init() async {
    _messages.clear();
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;

    if (userId != null) {
      debugPrint("✅ Firebase User ID: $userId");
    } else {
      debugPrint("❌ No Firebase user is currently signed in.");
    }

    final prefs = await SharedPreferences.getInstance();
    history = prefs.getStringList('chat_history') ?? [];

    notifyListeners();
  }

  Future<void> clearChat() async {
    _messages.clear();
    originalImageUrl = null;
    enhancedImageUrl = null;
    multiImageUrl = null;
    videoUrl = null;
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
  ///
  ///
  ///
  ///
  Future<void> fetchMessagesByUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    final uri = Uri.parse('$baseurl/messages/$userId');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final messageModel = MessageModel.fromJson(jsonResponse);
        _messages = messageModel.data ?? [];
      } else {
        print('❌ Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    _isLoading = true;
    notifyListeners();

    final uri = Uri.parse('$baseurl/messages/$userId');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({"text": text, "isUser": true});

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final sendMessageModel = SendMessageModel.fromJson(json);

        if (sendMessageModel.success == true &&
            sendMessageModel.message != null) {
          messageId = sendMessageModel.message!.sId;
          msg = sendMessageModel.message!.text;
          await fetchMessagesByUser(userId!);
          log("✅ Message sent successfully. ID: $messageId");
        } else {
          print("❌ Response success but message data is null");
        }
      } else {
        print(
          '❌ Failed to send message: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('❌ Error sending message: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateMessage(String url, String type) async {
    _isLoading = true;
    notifyListeners();

    final uri = Uri.parse('$baseurl/messages/update/$messageId');
    final headers = {'Content-Type': 'application/json'};

    final Map<String, dynamic> body = {
      "isUser": false,
      if (type == 'image') "image": url,
      if (type == 'video') "videoUrl": url,
      if (type == 'multiImg') "multiImageUrl": [url],
      if (type == 'enhance') "enhancedImageUrl": url,
    };

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final updateResponse = UpdateMessageModel.fromJson(json);

        log("✅ Success: ${updateResponse.success}");
        log("📝 Message Text: ${updateResponse.message?.text}");
        log("📸 Image URL: ${updateResponse.message?.image?.url}");
        log("🎥 Video URL: ${updateResponse.message?.videoUrl?.url}");
        log("🖼️ Multi Images: ${updateResponse.message?.multiImageUrl?.urls}");
        log(
          "✨ Enhanced Image: ${updateResponse.message?.enhancedImageUrl?.url}",
        );
      } else {
        print(
          '❌ Failed to update message: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('❌ Error updating message: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    final url = Uri.parse('$baseurl/messages/delete/$messageId');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final message = data['message'];
      await fetchMessagesByUser(userId!);
      print('✅ Deleted: $message');
    } else {
      print('❌ Failed: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  Future<void> callMultiImageApi(String text) async {
    if (imgUrl.isEmpty || text.trim().isEmpty) {
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

    try {
      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = json.decode(resBody);
        multiImageUrl = decoded['enhancedImageUrl'];

        await updateMessage(multiImageUrl!, 'multiImg');
        msg = null;
        await fetchMessagesByUser(userId!);
        print("✅ Multi-image success: ${decoded["message"]}");
      } else {
        print("❌ Error ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }

    isMultiImgLoading = false;
    notifyListeners();
  }

  Future<void> generateImage(String prompt) async {
    if (prompt.isEmpty) {
      errorMsg = 'Prompt cannot be empty.';
      notifyListeners();
      return;
    }

    errorMsg = null;
    _isLoading = true;
    isImageLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseurl/text-to-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'modelName': imageGeneratorProvider.selectedimgModel,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        originalImageUrl = data['imageUrl'];
        previousText = data['prompt'];

        await updateMessage(originalImageUrl!, 'image');
        await fetchMessagesByUser(userId!);
        msg = null;
      } else {
        errorMsg = 'Image generation failed: ${response.reasonPhrase}';
      }
    } catch (e) {
      errorMsg = 'Error: $e';
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
        if (originalImageUrl == null) return;
      }

      final res = await http.post(
        Uri.parse('$baseurl/enhance-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageUrl': originalImageUrl}),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        enhancedImageUrl = data['enhancedImageUrl'];

        await updateMessage(enhancedImageUrl!, 'enhance');
        await fetchMessagesByUser(userId!);
        msg = null;
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
        if (originalImageUrl == null) return;

        await generateEnhancedImage(prompt);
      }

      final imageUrlToUse = enhancedImageUrl ?? originalImageUrl;
      if (imageUrlToUse == null) {
        errorMsg = 'No valid image available for video generation.';
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

        await updateMessage(videoUrl!, 'video');
        await fetchMessagesByUser(userId!);
        msg = null;
      } else {
        errorMsg = 'Failed to generate video: ${res.body}';
      }
    } catch (e) {
      errorMsg = 'Error: $e';
    }

    _isLoading = false;
    isVideoLoading = false;
    notifyListeners();
  }
}
