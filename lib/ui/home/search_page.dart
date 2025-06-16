import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:textapp/provider/chat_provider.dart';
import 'package:textapp/provider/home_provider.dart';
import 'package:textapp/widgets/drawer_widget.dart';
import 'package:textapp/widgets/video_from_bytes_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FocusNode textField = FocusNode();
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  void _scrollToBottom(ChatProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && provider.messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final chatProvider = Provider.of<ChatProvider>(context);
      chatProvider.reloadMessages();
    });
    // final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // if (currentUserId != null) {
    //   Provider.of<ChatProvider>(
    //     context,
    //     listen: false,
    //   ).fetchChatHistory(currentUserId);
    // }
  }

  @override
  void dispose() {
    textField.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: kIsWeb
            ? null
            : AppBar(
                title: const Text('AI Image Chat'),
                centerTitle: true,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      final homeProvider = Provider.of<ImageGeneratorProvider>(
                        context,
                        listen: false,
                      );
                      final provider = Provider.of<ChatProvider>(
                        context,
                        listen: false,
                      );

                      if (value == 'image') {
                        await homeProvider.fetchImgModels();

                        if (context.mounted) {
                          provider.showModelSelectorDialog(
                            context,
                            homeProvider.imgmodelsMap,
                            homeProvider.selectedimgModel,
                            (selected) =>
                                provider.updateSelectedImageModel(selected),
                            title: 'Select Image Model',
                          );
                        }
                      } else if (value == 'video') {
                        await homeProvider.fetchVideoModels();

                        if (context.mounted) {
                          provider.showModelSelectorDialog(
                            context,
                            homeProvider.videomodelsMap,
                            homeProvider.selectedvideoModel,
                            (selected) =>
                                provider.updateSelectedVideoModel(selected),
                            title: 'Select Video Model',
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'image', child: Text('Image Model')),
                      PopupMenuItem(value: 'video', child: Text('Video Model')),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
        body: kIsWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, provider, _) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(provider),
              );

              return ListView.builder(
                controller: _scrollController,
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final msg = provider.messages[index];

                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.text, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 8),
                          if (msg.image != null && msg.image!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                msg.image!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                          if (msg.videoUrl != null && msg.videoUrl!.isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: VideoFromBytesWidget(
                                    videoBytes: msg.videoUrl!,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Input Field
        Consumer<ChatProvider>(
          builder: (context, provider, _) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      final int imageCount = kIsWeb
                          ? provider.webImages.length
                          : provider.mobileImages.length;

                      if (imageCount == 0 && !provider.isImageUploading) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          SizedBox(
                            height: 60,
                            child: provider.isImageUploading
                                ? ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 3,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (_, __) => Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: const CircleAvatar(radius: 24),
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imageCount > 2 ? 3 : imageCount,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      bool isLastVisible =
                                          (imageCount <= 2 &&
                                              index == imageCount - 1) ||
                                          (imageCount > 2 && index == 2);

                                      if (index < 2) {
                                        final imageProvider = kIsWeb
                                            ? MemoryImage(
                                                provider.webImages[index],
                                              )
                                            : FileImage(
                                                    provider
                                                        .mobileImages[index],
                                                  )
                                                  as ImageProvider;

                                        return Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundImage: imageProvider,
                                            ),
                                            if (isLastVisible)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    provider.clearAllImages();
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      } else {
                                        // +N avatar
                                        return Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.grey,
                                              child: Text(
                                                '+${imageCount - 2}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            if (isLastVisible)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    provider.clearAllImages();
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: Scrollbar(
                      child: TextField(
                        controller: controller,
                        focusNode: textField,
                        maxLines: null,
                        autofocus: false,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Describe an image....',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: provider.isMultiImgLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : provider.mobileImages.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () {
                                    final text = controller.text.trim();
                                    if (text.isNotEmpty) {
                                      final provider =
                                          Provider.of<ChatProvider>(
                                            context,
                                            listen: false,
                                          );

                                      provider.promt = text;
                                      provider.addUserMessage(text);
                                      provider.callMultiImageApi(text);

                                      controller.clear();
                                    }
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (provider.errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        provider.errorMsg!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          provider.pickImages();
                        },
                      ),

                      const Spacer(),

                      provider.isImageLoading
                          ? _buildShimmerButton()
                          : provider.mobileImages.isEmpty
                          ? ElevatedButton(
                              onPressed: () {
                                final text = controller.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a prompt'),
                                    ),
                                  );
                                } else if (!provider.isLoading) {
                                  provider.addUserMessage(text);
                                  provider.generateImage(text);
                                  controller.clear();
                                }
                              },
                              style: _buttonStyle(),
                              child: const Text(
                                'Image',
                                style: TextStyle(color: Colors.black),
                              ),
                            )
                          : const SizedBox.shrink(),

                      const SizedBox(width: 4),

                      provider.isEnhanceLoading
                          ? _buildShimmerButton()
                          : provider.mobileImages.isEmpty
                          ? ElevatedButton(
                              onPressed: () {
                                final text = controller.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a prompt'),
                                    ),
                                  );
                                } else if (!provider.isLoading) {
                                  provider.addUserMessage(text);
                                  provider.generateEnhancedImage(text);
                                  controller.clear();
                                }
                              },
                              style: _buttonStyle(),
                              child: const Text(
                                'Enhance',
                                style: TextStyle(color: Colors.black),
                              ),
                            )
                          : const SizedBox.shrink(),

                      const SizedBox(width: 8),

                      provider.mobileImages.isEmpty
                          ? provider.isVideoLoading
                                ? _buildShimmerButton()
                                : ElevatedButton(
                                    onPressed: () {
                                      final text = controller.text.trim();
                                      if (text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter a prompt',
                                            ),
                                          ),
                                        );
                                      } else if (!provider.isLoading) {
                                        provider.addUserMessage(text);
                                        provider.generateVideo(text);
                                        controller.clear();
                                      }
                                    },
                                    style: _buttonStyle(),
                                    child: const Text(
                                      'Video',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 350,
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'User Searched Messages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_outlined),
                          tooltip: 'Clear History',
                          onPressed: () {
                            provider.clearHistory();
                            provider.clearChat();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final userMessages = provider.messages
                            .where(
                              (msg) => msg.isUser && msg.text.trim().isNotEmpty,
                            )
                            .toList();

                        return userMessages.isEmpty
                            ? const Center(
                                child: Text("No searched messages found."),
                              )
                            : ListView.builder(
                                itemCount: userMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = userMessages[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.search,
                                      color: Colors.blue,
                                    ),
                                    title: Text(msg.text),
                                    onTap: () {},
                                  );
                                },
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'AI Image Generation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            final homeProvider =
                                Provider.of<ImageGeneratorProvider>(
                                  context,
                                  listen: false,
                                );
                            final provider = Provider.of<ChatProvider>(
                              context,
                              listen: false,
                            );

                            if (value == 'image') {
                              await homeProvider.fetchImgModels();
                              if (context.mounted) {
                                provider.showModelSelectorDialog(
                                  context,
                                  homeProvider.imgmodelsMap,
                                  homeProvider.selectedimgModel,
                                  (selected) => provider
                                      .updateSelectedImageModel(selected),
                                  title: 'Select Image Model',
                                );
                              }
                            } else if (value == 'video') {
                              await homeProvider.fetchVideoModels();
                              if (context.mounted) {
                                provider.showModelSelectorDialog(
                                  context,
                                  homeProvider.videomodelsMap,
                                  homeProvider.selectedvideoModel,
                                  (selected) => provider
                                      .updateSelectedVideoModel(selected),
                                  title: 'Select Video Model',
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'image',
                              child: Text('Image Model'),
                            ),
                            PopupMenuItem(
                              value: 'video',
                              child: Text('Video Model'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Expanded(
                  //   child: ListView.builder(
                  //     padding: const EdgeInsets.all(16),
                  //     itemCount: provider.messages.length,
                  //     itemBuilder: (context, index) {
                  //       final msg = provider.messages[index];
                  //       WidgetsBinding.instance.addPostFrameCallback(
                  //         (_) => _scrollToBottom(provider),
                  //       );

                  //       return Align(
                  //         alignment: msg.isUser
                  //             ? Alignment.centerRight
                  //             : Alignment.centerLeft,
                  //         child: Container(
                  //           margin: const EdgeInsets.symmetric(vertical: 4),
                  //           padding: const EdgeInsets.all(10),
                  //           decoration: BoxDecoration(
                  //             color: msg.isUser
                  //                 ? Colors.blue[100]
                  //                 : Colors.grey[300],
                  //             borderRadius: BorderRadius.circular(10),
                  //           ),
                  //           child: Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 msg.text,
                  //                 style: const TextStyle(fontSize: 15),
                  //               ),

                  //               if ((msg.image?.isNotEmpty ?? false) ||
                  //                   (msg.videoUrl?.isNotEmpty ?? false))
                  //                 const SizedBox(height: 8),

                  //               if (msg.image != null && msg.image!.isNotEmpty)
                  //                 ClipRRect(
                  //                   borderRadius: BorderRadius.circular(8),
                  //                   child: Image.memory(
                  //                     msg.image!,
                  //                     height: 200,
                  //                     width: 400,
                  //                     fit: BoxFit.cover,
                  //                   ),
                  //                 ),

                  //               if (msg.videoUrl != null &&
                  //                   msg.videoUrl!.isNotEmpty)
                  //                 SizedBox(
                  //                   width: 400,
                  //                   height: 250,
                  //                   child: ClipRRect(
                  //                     borderRadius: BorderRadius.circular(8),
                  //                     child: AspectRatio(
                  //                       aspectRatio: 16 / 9,
                  //                       child: VideoFromBytesWidget(
                  //                         videoBytes: msg.videoUrl!,
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //             ],
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                  Expanded(
                    child: Consumer<ChatProvider>(
                      builder: (context, provider, _) {
                        // Scroll to bottom after the frame is rendered
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom(provider);
                        });

                        return ListView.builder(
                          controller: _scrollController, // Don't forget this!
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            final msg = provider.messages[index];

                            return Align(
                              alignment: msg.isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: msg.isUser
                                      ? Colors.blue[100]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.text,
                                      style: const TextStyle(fontSize: 15),
                                    ),

                                    if ((msg.image?.isNotEmpty ?? false) ||
                                        (msg.videoUrl?.isNotEmpty ?? false))
                                      const SizedBox(height: 8),

                                    if (msg.image != null &&
                                        msg.image!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          msg.image!,
                                          height: 200,
                                          width: 400,
                                          fit: BoxFit.cover,
                                        ),
                                      ),

                                    if (msg.videoUrl != null &&
                                        msg.videoUrl!.isNotEmpty)
                                      SizedBox(
                                        width: 400,
                                        height: 250,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: VideoFromBytesWidget(
                                              videoBytes: msg.videoUrl!,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<ChatProvider>(
                          builder: (context, provider, _) {
                            final int imageCount = kIsWeb
                                ? provider.webImages.length
                                : provider.mobileImages.length;

                            if (imageCount == 0 && !provider.isImageUploading) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              children: [
                                SizedBox(
                                  height: 60,
                                  child: provider.isImageUploading
                                      ? ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: provider.webImages.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 8),
                                          itemBuilder: (_, __) =>
                                              Shimmer.fromColors(
                                                baseColor: Colors.grey.shade300,
                                                highlightColor:
                                                    Colors.grey.shade100,
                                                child: const CircleAvatar(
                                                  radius: 24,
                                                ),
                                              ),
                                        )
                                      : ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: imageCount > 2
                                              ? 3
                                              : imageCount,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 8),
                                          itemBuilder: (context, index) {
                                            bool isLastVisible =
                                                (imageCount <= 2 &&
                                                    index == imageCount - 1) ||
                                                (imageCount > 2 && index == 2);

                                            if (index < 2) {
                                              final imageProvider = kIsWeb
                                                  ? MemoryImage(
                                                      provider.webImages[index],
                                                    )
                                                  : FileImage(
                                                          provider
                                                              .mobileImages[index],
                                                        )
                                                        as ImageProvider;

                                              return Stack(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 24,
                                                    backgroundImage:
                                                        imageProvider,
                                                  ),
                                                  if (isLastVisible)
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Colors
                                                                  .black54,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          constraints:
                                                              const BoxConstraints(),
                                                          onPressed: () {
                                                            provider
                                                                .clearAllImages();
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            } else {
                                              return Stack(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor:
                                                        Colors.grey,
                                                    child: Text(
                                                      '+${imageCount - 2}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isLastVisible)
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Colors
                                                                  .black54,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          constraints:
                                                              const BoxConstraints(),
                                                          onPressed: () {
                                                            provider
                                                                .clearAllImages();
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),

                        TextField(
                          controller: controller,
                          focusNode: textField,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: InputBorder.none,

                            suffixIcon: provider.isMultiImgLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : provider.webImages.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () {
                                      final text = controller.text.trim();
                                      if (text.isNotEmpty) {
                                        provider.addUserMessage(text);
                                        provider.callMultiImageApi(text);
                                        controller.clear();
                                      }
                                    },
                                  )
                                : null,
                          ),
                        ),
                        if (provider.errorMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              provider.errorMsg!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                provider.pickImages();
                              },
                            ),

                            const Spacer(),
                            provider.isImageLoading
                                ? _buildShimmerButton()
                                : provider.webImages.isEmpty
                                ? ElevatedButton(
                                    onPressed: () {
                                      final text = controller.text.trim();
                                      if (text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter a prompt',
                                            ),
                                          ),
                                        );
                                      } else if (!provider.isLoading) {
                                        provider.addUserMessage(text);
                                        provider.generateImage(text);
                                        controller.clear();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.deepPurple.shade100,
                                      foregroundColor: Colors.deepPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Text("Image"),
                                  )
                                : const SizedBox.shrink(),

                            const SizedBox(width: 8),
                            provider.isEnhanceLoading
                                ? _buildShimmerButton()
                                : provider.webImages.isEmpty
                                ? ElevatedButton(
                                    onPressed: () {
                                      final text = controller.text.trim();
                                      if (text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter a prompt',
                                            ),
                                          ),
                                        );
                                      } else if (!provider.isLoading) {
                                        provider.addUserMessage(text);
                                        provider.generateEnhancedImage(text);
                                        controller.clear();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.deepPurple.shade100,
                                      foregroundColor: Colors.deepPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Text("Enhance"),
                                  )
                                : const SizedBox.shrink(),

                            const SizedBox(width: 8),
                            provider.isVideoLoading
                                ? _buildShimmerButton()
                                : provider.webImages.isEmpty
                                ? ElevatedButton(
                                    onPressed: () {
                                      final text = controller.text.trim();
                                      if (text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter a prompt',
                                            ),
                                          ),
                                        );
                                      } else if (!provider.isLoading) {
                                        provider.addUserMessage(text);
                                        provider.generateVideo(text);
                                        controller.clear();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.deepPurple.shade100,
                                      foregroundColor: Colors.deepPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Text("Video"),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Expanded(
  //   child: Column(
  //     children: [
  //       Expanded(
  //         child: Consumer<ChatProvider>(
  //           builder: (context, provider, _) {
  //             WidgetsBinding.instance.addPostFrameCallback(
  //               (_) => _scrollToBottom(provider),
  //             );

  //             return ListView.builder(
  //               controller: _scrollController,
  //               itemCount: provider.messages.length,
  //               itemBuilder: (context, index) {
  //                 final msg = provider.messages[index];
  //                 return Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: Row(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisAlignment: msg.isUser
  //                         ? MainAxisAlignment.end
  //                         : MainAxisAlignment.start,
  //                     children: [
  //                       Flexible(
  //                         child: Container(
  //                           padding: const EdgeInsets.all(16),
  //                           decoration: BoxDecoration(
  //                             color: msg.isUser
  //                                 ? Colors.blue[100]
  //                                 : Colors.grey[200],
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                           child: Column(
  //                             crossAxisAlignment:
  //                                 CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 msg.text,
  //                                 style: const TextStyle(fontSize: 16),
  //                               ),
  //                               const SizedBox(height: 10),
  //                               if (msg.image != null &&
  //                                   msg.image!.isNotEmpty)
  //                                 Image.memory(msg.image!),
  //                               if (msg.videoUrl != null &&
  //                                   msg.videoUrl!.isNotEmpty)
  //                                 SizedBox(
  //                                   height: 200,
  //                                   child: AspectRatio(
  //                                     aspectRatio: 16 / 9,
  //                                     child: VideoFromBytesWidget(
  //                                       videoBytes: msg.videoUrl!,
  //                                     ),
  //                                   ),
  //                                 ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //       // Add text input for web at bottom
  //       Padding(
  //         padding: const EdgeInsets.all(12.0),
  //         child: Row(
  //           children: [
  //             Expanded(
  //               child: TextField(
  //                 controller: controller,
  //                 focusNode: textField,
  //                 decoration: const InputDecoration(
  //                   hintText: "Type a message...",
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 10),
  //             IconButton(
  //               icon: const Icon(Icons.send),
  //               onPressed: () {
  //                 final text = controller.text.trim();
  //                 if (text.isNotEmpty) {
  //                   Provider.of<ChatProvider>(
  //                     context,
  //                     listen: false,
  //                   ).addUserMessage(text);
  //                   controller.clear();
  //                 }
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   ),
  // ),

  // Consumer<ChatProvider>(
  //   builder: (context, provider, _) {
  //     return Container(
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         border: Border(top: BorderSide(color: Colors.grey.shade300)),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Consumer<ChatProvider>(
  //             builder: (context, provider, _) {
  //               final int imageCount = provider.webImages.length;

  //               if (imageCount == 0 && !provider.isImageUploading) {
  //                 return const SizedBox.shrink();
  //               }

  //               return Column(
  //                 children: [
  //                   SizedBox(
  //                     height: 60,
  //                     child: provider.isImageUploading
  //                         ? ListView.separated(
  //                             scrollDirection: Axis.horizontal,
  //                             itemCount: 3,
  //                             separatorBuilder: (_, __) =>
  //                                 const SizedBox(width: 8),
  //                             itemBuilder: (_, __) => Shimmer.fromColors(
  //                               baseColor: Colors.grey.shade300,
  //                               highlightColor: Colors.grey.shade100,
  //                               child: const CircleAvatar(radius: 24),
  //                             ),
  //                           )
  //                         : ListView.separated(
  //                             scrollDirection: Axis.horizontal,
  //                             itemCount: imageCount > 2 ? 3 : imageCount,
  //                             separatorBuilder: (_, __) =>
  //                                 const SizedBox(width: 8),
  //                             itemBuilder: (context, index) {
  //                               bool isLastVisible =
  //                                   (imageCount <= 2 &&
  //                                       index == imageCount - 1) ||
  //                                   (imageCount > 2 && index == 2);

  //                               if (index < 2) {
  //                                 final imageProvider = MemoryImage(
  //                                   provider.webImages[index],
  //                                 );

  //                                 return Stack(
  //                                   children: [
  //                                     CircleAvatar(
  //                                       radius: 24,
  //                                       backgroundImage: imageProvider,
  //                                     ),
  //                                     if (isLastVisible)
  //                                       Positioned(
  //                                         top: 0,
  //                                         right: 0,
  //                                         child: GestureDetector(
  //                                           onTap: () {
  //                                             provider.clearAllImages();
  //                                           },
  //                                           child: Container(
  //                                             decoration:
  //                                                 const BoxDecoration(
  //                                                   color: Colors.black54,
  //                                                   shape:
  //                                                       BoxShape.circle,
  //                                                 ),
  //                                             padding:
  //                                                 const EdgeInsets.all(4),
  //                                             child: const Icon(
  //                                               Icons.close,
  //                                               size: 18,
  //                                               color: Colors.white,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                   ],
  //                                 );
  //                               } else {
  //                                 // Show "+N" for remaining images
  //                                 return Stack(
  //                                   children: [
  //                                     CircleAvatar(
  //                                       radius: 24,
  //                                       backgroundColor: Colors.grey[300],
  //                                       child: Text(
  //                                         '+${imageCount - 2}',
  //                                         style: const TextStyle(
  //                                           fontWeight: FontWeight.bold,
  //                                           color: Colors.black,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                     if (isLastVisible)
  //                                       Positioned(
  //                                         top: 0,
  //                                         right: 0,
  //                                         child: GestureDetector(
  //                                           onTap: () {
  //                                             provider.clearAllImages();
  //                                           },
  //                                           child: Container(
  //                                             decoration:
  //                                                 const BoxDecoration(
  //                                                   color: Colors.black54,
  //                                                   shape:
  //                                                       BoxShape.circle,
  //                                                 ),
  //                                             padding:
  //                                                 const EdgeInsets.all(4),
  //                                             child: const Icon(
  //                                               Icons.close,
  //                                               size: 18,
  //                                               color: Colors.white,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                   ],
  //                                 );
  //                               }
  //                             },
  //                           ),
  //                   ),
  //                   const SizedBox(height: 12),
  //                 ],
  //               );
  //             },
  //           ),

  //           ConstrainedBox(
  //             constraints: const BoxConstraints(maxHeight: 150),
  //             child: Scrollbar(
  //               child: TextField(
  //                 controller: controller,
  //                 focusNode: textField,
  //                 maxLines: null,
  //                 autofocus: false,
  //                 keyboardType: TextInputType.multiline,
  //                 decoration: InputDecoration(
  //                   hintText: 'Describe an image...',
  //                   border: InputBorder.none,
  //                   contentPadding: const EdgeInsets.symmetric(
  //                     horizontal: 12,
  //                     vertical: 10,
  //                   ),
  //                   suffixIcon: provider.isMultiImgLoading
  //                       ? const Padding(
  //                           padding: EdgeInsets.all(12),
  //                           child: SizedBox(
  //                             width: 20,
  //                             height: 20,
  //                             child: CircularProgressIndicator(
  //                               strokeWidth: 2,
  //                             ),
  //                           ),
  //                         )
  //                       : (provider.webImages.isNotEmpty ||
  //                             provider.mobileImages.isNotEmpty)
  //                       ? IconButton(
  //                           icon: const Icon(Icons.send),
  //                           onPressed: () {
  //                             final text = controller.text.trim();
  //                             if (text.isNotEmpty) {
  //                               provider.promt = text;
  //                               provider.addUserMessage(text);
  //                               provider.callMultiImageApi(text);
  //                               controller.clear();
  //                             }
  //                           },
  //                         )
  //                       : null,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 8),

  //           if (provider.errorMsg != null)
  //             Padding(
  //               padding: const EdgeInsets.only(bottom: 4),
  //               child: Text(
  //                 provider.errorMsg!,
  //                 style: const TextStyle(color: Colors.red),
  //               ),
  //             ),

  //           Row(
  //             children: [
  //               IconButton(
  //                 icon: const Icon(Icons.add),
  //                 onPressed: () => provider.pickImages(),
  //               ),
  //               const Spacer(),

  //               // Image Button
  //               if (provider.isImageLoading)
  //                 _buildShimmerButton()
  //               else if (provider.webImages.isEmpty &&
  //                   provider.mobileImages.isEmpty)
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     final text = controller.text.trim();
  //                     if (text.isEmpty) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text('Please enter a prompt'),
  //                         ),
  //                       );
  //                     } else if (!provider.isLoading) {
  //                       provider.addUserMessage(text);
  //                       provider.generateImage(text);
  //                       controller.clear();
  //                     }
  //                   },
  //                   style: _buttonStyle(),
  //                   child: const Text(
  //                     'Image',
  //                     style: TextStyle(color: Colors.black),
  //                   ),
  //                 ),

  //               const SizedBox(width: 4),

  //               // Enhance Button
  //               if (provider.isEnhanceLoading)
  //                 _buildShimmerButton()
  //               else if (provider.webImages.isEmpty &&
  //                   provider.mobileImages.isEmpty)
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     final text = controller.text.trim();
  //                     if (text.isEmpty) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text('Please enter a prompt'),
  //                         ),
  //                       );
  //                     } else if (!provider.isLoading) {
  //                       provider.addUserMessage(text);
  //                       provider.generateEnhancedImage(text);
  //                       controller.clear();
  //                     }
  //                   },
  //                   style: _buttonStyle(),
  //                   child: const Text(
  //                     'Enhance',
  //                     style: TextStyle(color: Colors.black),
  //                   ),
  //                 ),

  //               const SizedBox(width: 8),

  //               // Video Button
  //               if (provider.isVideoLoading)
  //                 _buildShimmerButton()
  //               else if (provider.webImages.isEmpty &&
  //                   provider.mobileImages.isEmpty)
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     final text = controller.text.trim();
  //                     if (text.isEmpty) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text('Please enter a prompt'),
  //                         ),
  //                       );
  //                     } else if (!provider.isLoading) {
  //                       provider.addUserMessage(text);
  //                       provider.generateVideo(text);
  //                       controller.clear();
  //                     }
  //                   },
  //                   style: _buttonStyle(),
  //                   child: const Text(
  //                     'Video',
  //                     style: TextStyle(color: Colors.black),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     );
  //   },
  // ),
}

Widget _buildShimmerButton() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: 40,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

ButtonStyle _buttonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple.shade100,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}














// Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          //   color: Colors.white,
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: TextField(
          //           controller: controller,
          //           decoration: InputDecoration(
          //             hintText: 'Describe an image...',
          //             border: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(10),
          //             ),
          //             contentPadding: const EdgeInsets.symmetric(
          //               horizontal: 12,
          //               vertical: 8,
          //             ),
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 8),
          //       ElevatedButton(
          //         onPressed: () {
          //           final text = controller.text.trim();
          //           if (text.isNotEmpty) {
          //             final provider = Provider.of<ChatProvider>(
          //               context,
          //               listen: false,
          //             );
          //             provider.addUserMessage(text);
          //             provider.generateImage(text);
          //             controller.clear();
          //           }
          //         },
          //         style: ElevatedButton.styleFrom(
          //           padding: const EdgeInsets.symmetric(vertical: 0),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //         ),
          //         child: const Text('image'),
          //       ),
          //       const SizedBox(width: 8),
          //       ElevatedButton(
          //         onPressed: () {
          //           final text = controller.text.trim();
          //           if (text.isNotEmpty) {
          //             final provider = Provider.of<ChatProvider>(
          //               context,
          //               listen: false,
          //             );
          //             // provider.addUserMessage(text);
          //             // provider.generateImage(text);
          //             // controller.clear();
          //           }
          //         },
          //         style: ElevatedButton.styleFrom(
          //           padding: const EdgeInsets.symmetric(vertical: 0),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //         ),
          //         child: const Text('video'),
          //       ),
          //     ],
          //   ),
          // ),
       