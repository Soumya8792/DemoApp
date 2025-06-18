import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:textapp/provider/chat_provider.dart';
import 'package:textapp/provider/home_provider.dart';
import 'package:textapp/widgets/drawer_widget.dart';
import 'package:textapp/widgets/vedio_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FocusNode textField = FocusNode();
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

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

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId != null) {
      debugPrint("✅ Firebase User ID: $userId");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ChatProvider>(
          context,
          listen: false,
        ).fetchMessagesByUser(userId);
      });
    } else {
      debugPrint("❌ No Firebase user is currently signed in.");
    }
  }

  @override
  void dispose() {
    textField.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        drawer: mobile ? const AppDrawer() : null,
        appBar: kIsWeb && !isMobile(context)
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
        body: Row(
          children: [
            if (!mobile)
              Container(
                width: 350,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[100],
                child: Consumer<ChatProvider>(
                  builder: (context, provider, _) {
                    final userMessages = provider.messages
                        .where((msg) => msg.isUser!)
                        .toList()
                        .reversed
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'User Searched Messages',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: userMessages.isEmpty
                              ? Center(
                                  child: Text(
                                    "No searched messages found.",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  itemCount: userMessages.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final msg = userMessages[index];
                                    return ListTile(
                                      leading: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Message',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this message?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('No'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    provider.deleteMessage(
                                                      msg.sId!,
                                                    );
                                                    Navigator.pop(
                                                      context,
                                                      true,
                                                    );
                                                  },
                                                  child: const Text('Yes'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            provider.deleteMessage(msg.sId!);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Message deleted',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      title: Text(
                                        msg.text!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      onTap: () {
                                        debugPrint('Tapped on: ${msg.text}');
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            /// Main Chat Layout
            Expanded(
              child: Column(
                children: [
                  if (!mobile)
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
                  Expanded(child: _buildMobileLayout(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, provider, _) {
              _scrollToBottom(provider);

              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;

              return ListView.builder(
                controller: _scrollController,
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final msg = provider.messages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (msg.text != null && msg.text!.isNotEmpty)
                          Align(
                            alignment: msg.isUser == true
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: msg.isUser == true
                                    ? (isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue[100])
                                    : (isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg.text!,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                              ),
                            ),
                          ),

                        if (msg.imgUrl != null)
                          ...msg.imgUrl!
                              .where(
                                (img) =>
                                    img.type == 'original image' ||
                                    img.type == 'enhancedImageUrl' ||
                                    img.type == 'multiImageUrl',
                              )
                              .map((img) {
                                final label =
                                    {
                                      'original image': 'Original Image',
                                      'enhancedImageUrl': 'Enhanced Image',
                                      'multiImageUrl': 'Multi Image',
                                    }[img.type] ??
                                    'Image';

                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            img.url ?? '',
                                            width: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList(),

                        if (msg.imgUrl != null)
                          ...msg.imgUrl!
                              .where((img) => img.type == 'videoUrl')
                              .map((img) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Video',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: SizedBox(
                                            width: 250,
                                            height: 150,
                                            child: AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: img.url != null
                                                  ? VideoPlayerWidget(
                                                      videoUrl: img.url!,
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                      ],
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
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe an image....',
                          hintStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.black54,
                          ),
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
                                      provider.sendMessage(text);
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
                                  provider.sendMessage(text);
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
                                  provider.sendMessage(text);
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
                                        provider.sendMessage(text);
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
