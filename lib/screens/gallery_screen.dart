import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/services/get_data_api.dart';
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

  String getImageUrl(int tim, String ext) {
    String imageUrl = 'https://i.4cdn.org/a/' + tim.toString() + ext;
    return imageUrl;
  }

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
    debugPrint('----------------init index: $initialIndex---------');
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
            Consumer<ApiData>(builder: (context, value, child) {
              return Text('${value.imageIndex + 1} / ${value.images.length}');
            }),
            // Text(
            //   '${context.watch<ApiData>().imageIndex + 1} / ${context.watch<ApiData>().images.length}',
            //   //'${initialIndex + 1}/$imagesLength',
            //   style: const TextStyle(
            //     fontSize: 11,
            //   ),
            // ),
          ],
        ),
      ),
      body: Consumer<ApiData>(
        builder: (context, value, child) {
          return value.images.isEmpty && !value.error
              ? const Center(child: CircularProgressIndicator())
              : value.error
                  ? Text(value.errorMessage)
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
                              ),
                            ),
                          );
                        }
                      },
                    );
        },
      ),
    );
  }
}
