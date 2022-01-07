import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/screens/thread_screen.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/utils/convert_units.dart';
import 'package:neetchan/utils/file_manager.dart';
import 'package:neetchan/widgets/chewie_video_player.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class Gallery extends StatefulWidget {
  const Gallery({Key? key, required this.no, required this.board})
      : super(key: key);

  final int no;
  final String board;

  static _GalleryState? of(BuildContext context) =>
      context.findAncestorStateOfType<_GalleryState>();

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  late List<Widget> pages;
  late PageController pageController;
  late PageController galleryPageController;
  int selectedPage = 0;

  final GlobalKey<_GalleryGridViewState> galleryGridViewKey =
      GlobalKey<_GalleryGridViewState>();

  // Only so that GalleryGrid sibling GridPage can access its scrollController
  void updateGalleryGridScrollPosition(double position) {
    galleryGridViewKey.currentState?.updateScrollposition(position);
  }

  void updateGalleryPagePosition(int index) {
    galleryPageController.jumpToPage(index);
  }

  void toggleGalleryView(int index) {
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
    } else {
      debugPrint('------ Gallery Controller has no listeners ------');
    }
  }

  @override
  void initState() {
    super.initState();

    context.read<ApiData>().fetchImages(widget.no, widget.board);
    final initialIndex = context.read<ApiData>().currentImageIndex;
    debugPrint('------ Gallery image index: $initialIndex ------');
    galleryPageController = PageController(initialPage: initialIndex);

    pages = [
      GalleryPage(
        no: widget.no,
        board: widget.board,
        galleryPageController: galleryPageController,
      ),
      GalleryGridView(key: galleryGridViewKey),
    ];

    pageController = PageController(initialPage: selectedPage);
  }

  @override
  void dispose() {
    super.dispose();
    galleryPageController.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: pages,
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage(
      {Key? key,
      required this.no,
      required this.board,
      required this.galleryPageController})
      : super(key: key);

  final int no;
  final String board;
  final PageController galleryPageController;
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with AutomaticKeepAliveClientMixin<GalleryPage> {
  bool keepAlive = false;

  @override
  get wantKeepAlive => keepAlive;

  @override
  void initState() {
    super.initState();

    keepAlive = true;
    updateKeepAlive();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    debugPrint('------ Built Gallery screen ------');
    Widget galleryPage = Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            keepAlive = false;
            updateKeepAlive();
          },
          icon: const Icon(Icons.arrow_back),
        ),
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
            icon: const Icon(Icons.save),
          ),
          const GalleryPopupMenu(),
        ],
      ),
      body: Consumer<ApiData>(
        // Change to selector
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
                      controller: widget.galleryPageController,
                      onPageChanged: (index) async {
                        value.updateImageIndex(index);

                        // TODO: fix this inefficient method
                        final scrollIndex = value.getThreadIndex(index);
                        Thread.of(context)?.updateScrollPosition(scrollIndex);
                      },
                      itemCount: value.images.length,
                      itemBuilder: (context, index) {
                        debugPrint('------ Built Gallery Page ${index + 1} ------');
                        Post item = value.images[index];
                        return GalleryPageItem(
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
                final screenWidth = MediaQuery.of(context).size.width;
                double position = (screenWidth / 2) *
                    (context.read<ApiData>().currentImageIndex / 2).floor();
                // Has not listerns and does nothing on first build
                Gallery.of(context)?.updateGalleryGridScrollPosition(position);
                Gallery.of(context)?.toggleGalleryView(1);
              },
              icon: const Icon(Icons.view_module),
            ),
          ],
        ),
      ),
    );
    return galleryPage;
  }
}

class GalleryPageItem extends StatelessWidget {
  const GalleryPageItem({
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

class GalleryGridView extends StatefulWidget {
  const GalleryGridView({
    Key? key,
  }) : super(key: key);

  @override
  State<GalleryGridView> createState() => _GalleryGridViewState();
}

class _GalleryGridViewState extends State<GalleryGridView>
    with AutomaticKeepAliveClientMixin<GalleryGridView> {
  late ScrollController scrollController;
  bool keepAlive = false;

  void updateScrollposition(double position) {
    if (scrollController.hasClients) {
      debugPrint('------ Jumping to $position in GalleryGrid Screen ------');
      if (position >= scrollController.position.maxScrollExtent) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      } else {
        scrollController.jumpTo(position);
      }
    } else {
      debugPrint('------ ScrollController has no listeners ------');
    }
  }

  @override
  get wantKeepAlive => keepAlive;
  late double position;

  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    //   // Can only get screenWidth after init build
    //   final screenWidth = MediaQuery.of(context).size.width;
    //   position = (screenWidth / 2) *
    //       (context.read<ApiData>().currentImageIndex / 2).floor();
    //   context.read<GalleryController>().updateScrollposition(position);
    // });

    keepAlive = true;
    updateKeepAlive();
  }

  @override
  void didChangeDependencies() {
    final screenWidth = MediaQuery.of(context).size.width;
    position = (screenWidth / 2) *
        (context.read<ApiData>().currentImageIndex / 2).floor();
    // TODO: fix initial offset outOfRange    
    scrollController = ScrollController(initialScrollOffset: position);
  
    debugPrint('------ didChangeDependencies ------');
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint('------ Built Gallery Gridview Screen ------');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            //context.read<ApiData>().toggleGalleryGridView();
            keepAlive = false;
            updateKeepAlive();
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
        itemCount: context.read<ApiData>().images.length, 
        itemBuilder: (context, index) {
          final image = context.read<ApiData>().images[index]; 
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
        Gallery.of(context)?.toggleGalleryView(0);
        Gallery.of(context)?.updateGalleryPagePosition(index);
      },
    );
  }
}

class GalleryPopupMenu extends StatelessWidget {
  const GalleryPopupMenu({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MenuOptions>(
      onSelected: (value) {
        value.action(context);
      },
      itemBuilder: (context) => <PopupMenuEntry<MenuOptions>>[
        ...MenuOptions.values.map(
          (item) => PopupMenuItem<MenuOptions>(
            value: item,
            child: Text(item.description),
          ),
        ),
      ],
    );
  }
}

enum MenuOptions {
  openBrowser,
  imageSearch,
  imageInfo,
}

extension MenuOptionsExtension on MenuOptions {
  String get description {
    switch (this) {
      case MenuOptions.imageSearch:
        return 'Image search';
      case MenuOptions.imageInfo:
        return 'Image info';
      case MenuOptions.openBrowser:
        return 'Open in a browser';
    }
  }

  void action(context) {
    switch (this) {
      case MenuOptions.imageSearch:
        _showSearchMenu(context);
        break;
      case MenuOptions.imageInfo:
        _showMyDialog(context);
        break;
      case MenuOptions.openBrowser:
        break;
    }
  }

  Future<void> _showSearchMenu(BuildContext context) async {
    return showMenu(
        context: context,
        position: const RelativeRect.fromLTRB(double.maxFinite, 0, 0, 0),
        items: [
          ...SearchOptions.values.map((item) => PopupMenuItem<SearchOptions>(
              child: Text(item.description),
              onTap: () {
                item.action(context);
              }))
        ]);
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Info'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Posted: '),
                Text('File Name: '),
                Text('Dimensions: '),
                Text('Size: '),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Exit'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

enum SearchOptions { google, sauceNao, yandex }

extension SearchOptionsExtension on SearchOptions {
  static const googleImgUrl = 'https://www.google.com/searchbyimage?image_url=';
  static const sauceNaoImgUrl = 'https://www.saucenao.com/search.php?url=';
  static const yandexImgUrl = 'https://yandex.ru/images/search?rpt=imageview&url=';

  String get description {
    switch (this) {
      case SearchOptions.google:
        return 'Google';
      case SearchOptions.sauceNao:
        return 'SauceNao';
      case SearchOptions.yandex:
        return 'Yandex';
    }
  }

  void action(BuildContext context) {
    String searchEngine;
    switch (this) {
      case SearchOptions.google:
        searchEngine = googleImgUrl;
        break;
      case SearchOptions.sauceNao:
        searchEngine = sauceNaoImgUrl;
        break;
      case SearchOptions.yandex:
        searchEngine = yandexImgUrl;
        break;
    }
    launchInBrowser(searchEngine + imageUrl(context));
  }

  String imageUrl(BuildContext context) {
    final img = Provider.of<ApiData>(context, listen: false).currentImage;
    final imgUrl = Provider.of<ApiData>(context, listen: false).getImageUrl(img.tim!, img.ext!);
    return imgUrl;
  }

  Future<void> launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
