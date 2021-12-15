import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/utils/convert_units.dart';
import 'package:neetchan/utils/file_manager.dart';
import 'package:neetchan/widgets/chewie_video_player.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class Gallery extends StatefulWidget {
  const Gallery({Key? key, required this.no, required this.board})
      : super(key: key);

  final int no;
  final String board;

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  List<Post> images = [];

  int initialIndex = 0;
  int imagesLength = 0;

  late PageController pageController;

  @override
  void initState() {
    super.initState();
    //pageController = PageController(initialPage: initialIndex);

    context.read<ApiData>().fetchImages(widget.no, widget.board);
    // images = context.read<ApiData>().images;
    // imagesLength = images.length;

    initialIndex = context.read<ApiData>().currentImageIndex;
    debugPrint('------ Gallery image index: $initialIndex ------');
    pageController = PageController(initialPage: initialIndex);

    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    //   setState(() {
    //     initialIndex = context.read<ApiData>().currentImageIndex;
    //     pageController = PageController(initialPage: initialIndex);
    //   });
    // });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // context.read<ApiData>().fetchImages(widget.no);
    // images = context.read<ApiData>().images;
    // initialIndex = context.read<ApiData>().currentImageIndex;
    // imagesLength = images.length;

    // pageController = PageController(initialPage: initialIndex);
    debugPrint('------ Built Gallery screen ------');
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gallery',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Consumer<ApiData>(
              builder: (context, value, child) {
                return value.images.isEmpty || value.error
                    ? const Text('')
                    : Text('${value.imageIndex + 1} / ${value.images.length}');
              },
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
          IconButton(
              onPressed: () async {
                final imageIndex = context.read<ApiData>().currentImageIndex;
                final image = context.read<ApiData>().images[imageIndex];
                final fileName = image.filename;
                final ext = image.ext;
                final tim = image.tim;
                final url = context.read<ApiData>().getImageUrl(tim!, ext!);

                // TODO: check live image cache
                //var dl = Image.network(url).image.resolve(createLocalImageConfiguration(context));

                // TODO: snackbar on success or failure
                if (await FileUtil.saveImageToStorage(fileName!, ext, url)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Saved as "$fileName$ext"',
                        textAlign: TextAlign.left,
                      ),
                      duration: const Duration(milliseconds: 2000),
                      elevation: 2,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save)),
        ],
      ),
      body: Consumer<ApiData>(
        builder: (context, value, child) {
          return value.images.isEmpty && !value.error
              ? const Center(child: CircularProgressIndicator())
              : value.error
                  ? Center(
                      child: Text(value.errorMessage),
                    )
                  : PageView.builder(
                      controller: pageController,
                      onPageChanged: (index) {
                        value.updateImageIndex(index);
                      },
                      itemCount: value.images.length,
                      itemBuilder: (context, index) {
                        Post item = value.images[index];
                        if (item.ext == '.webm') {
                          return ChewieVideoPlayer(
                            videoPlayerController:
                                VideoPlayerController.network(
                              context
                                  .read<ApiData>()
                                  .getImageUrl(item.tim!, item.ext!),
                            ),
                            looping: true,
                            autoplay: true,
                            showControls: true,
                            aspectRatio: item.width! /
                                item.height!, // hot-fix hack, no need to await vid init
                          );
                        } else {
                          return Center(
                            child: InteractiveViewer(
                              clipBehavior: Clip.none,
                              minScale: 0.8,
                              maxScale: 4,
                              panEnabled: true,
                              child: Image.network(
                                context
                                    .read<ApiData>()
                                    .getImageUrl(item.tim!, item.ext!),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  // TODO: return thumbnai as loading indicator instead
                                  return const LinearProgressIndicator();
                                },
                                errorBuilder: (context, exception, stackTrace) {
                                  return const Icon(Icons.image);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    );
        },
      ),
      bottomNavigationBar: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Consumer<ApiData>(
              builder: (context, value, child) {
                return value.images.isEmpty || value.error
                    ? const Text('')
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${value.images[value.imageIndex].filename}',
                              style: const TextStyle(
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              formatBytes(
                                  value.images[value.imageIndex].filesize!, 1),
                            ),
                          ],
                        ),
                      );
              },
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.view_module),
          ),
        ],
      ),
    );
  }
}
