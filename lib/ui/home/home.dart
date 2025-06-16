import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:textapp/provider/auth_provider.dart';
import 'package:textapp/provider/home_provider.dart';
import 'package:textapp/ui/home/profile_screen.dart';
import 'package:textapp/widgets/shimmer_widget.dart';
import 'package:textapp/widgets/vedio_widget.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ImageGeneratorProvider>(
        context,
        listen: false,
      ).fetchImgModels();
      Provider.of<ImageGeneratorProvider>(
        context,
        listen: false,
      ).fetchVideoModels();
      Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
    });
  }

  int _calculateCurrentStep(ImageGeneratorProvider provider) {
    if (provider.originalImageUrl == null) return 1;

    if (provider.isSelected) {
      if (provider.vedioUrl == null ||
          provider.vedioUrl!.isEmpty ||
          provider.vedioUrl ==
              'The input or output was flagged as sensitive. Please try again with different inputs') {
        return 2;
      }
      return 2;
    } else {
      if (provider.processedImageUrl == null) return 2;
      if (provider.vedioUrl == null ||
          provider.vedioUrl!.isEmpty ||
          provider.vedioUrl ==
              'The input or output was flagged as sensitive. Please try again with different inputs') {
        return 3;
      }
      return 3;
    }
  }

  Widget _buildCustomProgressIndicator(ImageGeneratorProvider provider) {
    final currentStep = _calculateCurrentStep(provider);
    final totalSteps = provider.isSelected ? 2 : 3;

    /// Determine shimmer per-step based on the actual loading state
    bool shouldShimmerStep(int stepIndex) {
      if (stepIndex == 1 && provider.isTextToImageLoading) return true;
      if (stepIndex == 2 && provider.isEnhanceImageLoading) return true;
      if (stepIndex == 3 && provider.isVideoGenerating) return true;
      return false;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0, left: 20, right: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepProgressIndicator(
            totalSteps: totalSteps,
            currentStep: currentStep,
            size: 36,
            selectedColor: Colors.grey.shade300,
            unselectedColor: Colors.grey.shade300,
            customStep: (index, color, _) {
              int stepIndex;
              if (provider.isSelected) {
                stepIndex = index == 0
                    ? 1
                    : 3; // For 2 steps: Text-to-Image, Video
              } else {
                stepIndex =
                    index + 1; // For 3 steps: Text-to-Image, Enhance, Video
              }

              bool isStepComplete = false;
              if (stepIndex == 1 && provider.originalImageUrl != null) {
                isStepComplete = true;
              } else if (stepIndex == 2 && provider.processedImageUrl != null) {
                isStepComplete = true;
              } else if (stepIndex == 3 &&
                  provider.vedioUrl != null &&
                  provider.vedioUrl!.isNotEmpty &&
                  provider.vedioUrl !=
                      'The input or output was flagged as sensitive. Please try again with different inputs') {
                isStepComplete = true;
              }

              final shimmer = shouldShimmerStep(stepIndex);

              Widget stepContent;

              if (isStepComplete) {
                stepContent = Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 28),
                  ),
                );
              } else if (stepIndex == currentStep) {
                stepContent = Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.remove, color: Colors.black54, size: 28),
                  ),
                );
              } else {
                stepContent = Container(color: Colors.grey.shade300);
              }

              if (shimmer) {
                stepContent = Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.white,
                  child: stepContent,
                );
              }

              return GestureDetector(
                onTap: () {
                  debugPrint('Tapped step $stepIndex');
                  final prompt = provider.textController.text.trim();
                  if (prompt.isNotEmpty) {
                    provider.generateImageFlow(prompt, stepIndex);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a prompt")),
                    );
                  }
                },
                child: stepContent,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context, {
    required String title,
    required String imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return shimmerPlaceholder();
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                height: 150,
                child: Center(child: Icon(Icons.broken_image, size: 60)),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildImageModelSelector(ImageGeneratorProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: provider.imgmodelsMap.keys.map((modelName) {
          final isRemoved = provider.removedimgModels.contains(modelName);
          return ListTile(
            title: Text(modelName),
            // trailing: IconButton(
            //   icon: Icon(
            //     isRemoved ? Icons.add : Icons.remove,
            //     color: isRemoved ? Colors.green : Colors.red,
            //   ),
            //   onPressed: () {
            //     provider.toggleModel(modelName);
            //     Navigator.pop(context);
            //   },
            // ),
            onTap: isRemoved
                ? null
                : () {
                    provider.setSelectedModel(modelName);
                    Navigator.pop(context);
                  },
          );
        }).toList(),
      ),
    );
  }

  Widget buildVideoModelSelector(ImageGeneratorProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: provider.videomodelsMap.keys.map((modelName) {
          final isRemoved = provider.removedvideoModels.contains(modelName);
          return ListTile(
            title: Text(modelName),
            // trailing: IconButton(
            //   icon: Icon(
            //     isRemoved ? Icons.add : Icons.remove,
            //     color: isRemoved ? Colors.green : Colors.red,
            //   ),
            //   onPressed: () {
            //     provider.toggleModel1(modelName);
            //     Navigator.pop(context);
            //   },
            // ),
            onTap: isRemoved
                ? null
                : () {
                    provider.setSelectedModel1(modelName);
                    Navigator.pop(context);
                  },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Replicate Image Generator',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ImageGeneratorProvider>(
        builder: (context, provider, _) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.imgmodelsMap.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Select Image Model",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  provider.clearAll();
                                  // provider.loginWithEmail();
                                },
                                icon: Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) =>
                                    buildImageModelSelector(provider),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.selectedimgModel ??
                                        'Select Image Model',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "If you don't want to enhance the image, check this option.",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            provider.isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () {
                            setState(() {
                              provider.isSelected = !provider.isSelected;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (provider.videomodelsMap.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Video Model",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) =>
                                    buildVideoModelSelector(provider),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.selectedvideoModel ??
                                        'Select Video Model',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    TextField(
                      controller: provider.textController,
                      decoration: InputDecoration(
                        labelText: 'Enter your prompt',
                        labelStyle: const TextStyle(fontSize: 15),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                    if (provider.originalImageUrl == null &&
                            provider.processedImageUrl == null &&
                            provider.vedioUrl == null ||
                        provider.textController.text.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade100,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: provider.isLoading
                              ? null
                              : () {
                                  final prompt = provider.textController.text
                                      .trim();
                                  if (prompt.isNotEmpty) {
                                    provider.generateImageFlow(prompt, 0);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please enter a prompt"),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.image_outlined),
                          label: const Text("Generate"),
                        ),
                      ),
                    _buildCustomProgressIndicator(provider),

                    if (provider.originalImageUrl != null)
                      Column(
                        children: [
                          _buildImageCard(
                            context,
                            title: "Original Image",
                            imageUrl: provider.originalImageUrl!,
                          ),
                          if (provider.processedImageUrl == null &&
                              provider.step != 0)
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: provider.isLoading
                                    ? null
                                    : () {
                                        final prompt = provider
                                            .textController
                                            .text
                                            .trim();
                                        if (prompt.isNotEmpty) {
                                          provider.generateImageFlow(prompt, 2);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Please enter a prompt",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Next step',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    if (!provider.isSelected &&
                        provider.processedImageUrl != null)
                      Column(
                        children: [
                          _buildImageCard(
                            context,
                            title: "Processed Image",
                            imageUrl: provider.processedImageUrl!,
                          ),
                          if (provider.vedioUrl == null && provider.step != 0)
                            InkWell(
                              onTap: () {
                                final prompt = provider.textController.text
                                    .trim();
                                if (prompt.isNotEmpty) {
                                  provider.generateImageFlow(prompt, 3);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please enter a prompt"),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Next step',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    if (provider.vedioUrl != null &&
                        provider.vedioUrl!.isNotEmpty &&
                        provider.vedioUrl !=
                            'The input or output was flagged as sensitive. Please try again with different inputs')
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Video",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 270,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: VideoPlayerWidget(
                                videoUrl: provider.vedioUrl!,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
