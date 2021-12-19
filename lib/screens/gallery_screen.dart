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

    // Jump to the selected thumbnail image
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      context.read<ApiData>().updatePage(initialIndex);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    //context.read<ApiData>().pageController.dispose();
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
    Widget galleryPage = Scaffold(
      backgroundColor: Colors.black54, //Colors.transparent,
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
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
      body: 
      Consumer<ApiData>( // Change to selector
        builder: (context, value, child) {
          debugPrint('------ Built Gallery Screen inside Consumer ------');
          return value.images.isEmpty && !value.error
              ? const Center(child: CircularProgressIndicator())
              : value.error
                  ? Center(
                      child: Text(value.errorMessage),
                    )
                  : PageView.builder(
                      allowImplicitScrolling: true,
                      controller: context.read<ApiData>().pageController, // pageController, PageController(initialPage: value.currentImageIndex),
                      onPageChanged: (index) {
                        value.updateImageIndex(index);
                      },
                      itemCount: value.images.length,
                      itemBuilder: (context, index) {
                        debugPrint('------ Built Gallery Page ${index + 1} ------');
                        Post item = value.images[index];
                        return GalleryItem(
                          item: item,
                        );
                      },
                    );
        },
      ),

      bottomNavigationBar: Container(
        color: Colors.black,
        child: Row(
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
                                    value.images[value.imageIndex].filesize!,
                                    1),
                              ),
                            ],
                          ),
                        );
                },
              ),
            ),
            IconButton(
              onPressed: () {
                context.read<ApiData>().toggleGalleryGridView();

                final screenWidth = MediaQuery.of(context).size.width;
                double position = (screenWidth / 2) *
                    (context.read<ApiData>().currentImageIndex / 2).floor();
                context.read<ApiData>().updateScrollposition(position);
              },
              icon: const Icon(Icons.view_module),
            ),
          ],
        ),
      ),
    );

    return Selector<ApiData, bool>(
      selector: (_, apiData) {
        return apiData.isGalleryGridView;
      },
      builder: (context, value, child) {
        // return value
        //     ? GalleryGridView(
        //         no: context.read<ApiData>().currentImageIndex,
        //         images: context.read<ApiData>().images,
        //       )
        //     : galleryPage;
        debugPrint('------ Built Stacked Index -------');
        return IndexedStack(
          index: value ? 1 : 0,
          children: [
            galleryPage,
            GalleryGridView(
              // no: context.read<ApiData>().currentImageIndex,
              images: context.read<ApiData>().images,
            )
          ],
        );
      },
    );
  }
}

class GalleryItem extends StatelessWidget {
  const GalleryItem({
    required this.item,
    Key? key,
  }) : super(key: key);
  final Post item;

  @override
  Widget build(BuildContext context) {
    final Widget galleryItem = item.ext == '.webm'
        ? ChewieVideoPlayer(
            videoPlayerController: VideoPlayerController.network(
              context.read<ApiData>().getImageUrl(item.tim!, item.ext!),
            ),
            looping: true,
            autoplay: true,
            showControls: true,
            aspectRatio: item.width! /
                item.height!, // hot-fix hack, no need to await vid init
          )
        : Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.8,
              maxScale: 4,
              panEnabled: true,
              child: Image.network(
                context.read<ApiData>().getImageUrl(item.tim!, item.ext!),
                loadingBuilder: (context, child, loadingProgress) {
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
    return GestureDetector(
      child: galleryItem,
      onTap: () {},
    );
  }
}

class GalleryGridView extends StatelessWidget {
  const GalleryGridView({
    // required this.no,
    required this.images,
    Key? key,
  }) : super(key: key);

  // final int no;
  final List<Post> images;

  @override
  Widget build(BuildContext context) {
    debugPrint('------ Built Gallery Gridview Screen ------');

    final screenWidth = MediaQuery.of(context).size.width;
    double position = (screenWidth / 2) *
        (context.read<ApiData>().currentImageIndex / 2).floor();

    final scrollController = context.read<ApiData>().scrollController =
        ScrollController(initialScrollOffset: position);
    //final scrollController = ScrollController();

    // Empty constructor
    //final apiData = context.read<ApiData>();
    //apiData.fetchImages(apiData.currenThreadNo, apiData.currentBoard);
    //final images = context.read<ApiData>().images;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<ApiData>().toggleGalleryGridView();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Gallery'),
        actions: [
          IconButton(
            onPressed: () {
              scrollController.jumpTo(0);
            },
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            onPressed: () {
              scrollController
                  .jumpTo(scrollController.position.maxScrollExtent);
            },
            icon: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
      body: GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1 / 1,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return GridImageItem(
            image: image,
            index: index,
          );
        },
      ),
    );
  }
}

class GridImageItem extends StatelessWidget {
  const GridImageItem({
    required this.image,
    required this.index,
    Key? key,
  }) : super(key: key);

  final Post image;
  final int index;
  @override
  Widget build(BuildContext context) {
    debugPrint('------ Built Gallery Grid Item $index ------');
    final Widget item = Image.network(
      image.ext != '.webm'
          ? context.read<ApiData>().getImageUrl(image.tim!, image.ext!)
          : context.read<ApiData>().getThumbnailUrl(
              image.tim!, context.read<ApiData>().currentBoard),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: LinearProgressIndicator(),
        );
      },
      errorBuilder: (context, exception, stackTrace) {
        return const Icon(Icons.image);
      },
    );

    return InkWell(
      child: GridTile(
        child: item,
        header: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text('${index + 1}'),
        ),
        footer: Container(
          padding: const EdgeInsets.all(2.0),
          color: Colors.black45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatBytes(image.filesize!, 1)),
              Text(image.ext!.toUpperCase().substring(1)),
            ],
          ),
        ),
      ),
      onTap: () {
        // Open the selected image from gridview in Gallery
        context.read<ApiData>().updateImageIndex(index);
        context.read<ApiData>().toggleGalleryGridView();
        context.read<ApiData>().updatePage(context.read<ApiData>().currentImageIndex);
      },
    );
  }
}
