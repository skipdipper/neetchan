import 'package:flutter/material.dart';
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/screens/gallery_screen.dart';
import 'package:neetchan/services/file_controller.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/services/reply_post.dart';
import 'package:neetchan/utils/convert_units.dart';
import 'package:neetchan/widgets/post_text.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Thread extends StatefulWidget {
  const Thread({
    required this.no,
    required this.board,
    required this.op,
    Key? key,
  }) : super(key: key);

  final int no;
  final String board;
  final Catalog op; // only used for logging

  static _ThreadState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ThreadState>();

  @override
  _ThreadState createState() => _ThreadState();
}

class _ThreadState extends State<Thread> {

  final itemScrollController = ItemScrollController();
  final itemPositionListener = ItemPositionsListener.create();

  final nestedThreadKey = GlobalKey<NavigatorState>();

  bool bookMarked = false;

  @override
  void initState() {
    super.initState();
    itemPositionListener.itemPositions.addListener(() {
      //itemScrollListener();
      visibileItemIndexs();
      //visibileItemPositions();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('------ Built Thread Screen ------');

    context.read<ApiData>().fetchThread(widget.no, widget.board).then((_) {
      final thread = context.read<ApiData>().currentThread;

      context.read<ReplyPost>().populateRepliesMap(thread);
    });

    // return Scaffold
    Widget threadWidget = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.no.toString(),
        ),
        actions: [
          IconButton(onPressed: () async {
            final file = context.read<FileController>();

            if (!file.bookmarks.containsKey(widget.op.no.toString())) {
              final replies = context.read<ApiData>().currentThread;
              final res = replies.map((reply) {
                return reply.toJson();
              }).toList();

              file.writeBookMark(widget.no, widget.op.toJson(), res);
            } else {
              file.deleteBookmarkItem(widget.op.no.toString());
            }
          }, icon: Consumer<FileController>(builder: (context, value, child) {
            return value.bookmarks.containsKey(widget.op.no.toString())
                ? const Icon(Icons.bookmark)
                : const Icon(Icons.bookmark_border);
          })),
          IconButton(
            onPressed: () => scrollToTop(),
            icon: const Icon(
              Icons.arrow_upward,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => scrollToBottom(),
            icon: const Icon(
              Icons.arrow_downward,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ApiData>().fetchThread(widget.no, widget.board);
        },
        child: Center(
          child: Selector<ApiData, Map<String, dynamic>>(
            selector: (_, apiData) {
              return {
                'thread': apiData.threads[widget.no],
                'error': apiData.errors[widget.no],
                'errorMessage': apiData.errorMessages[widget.no],
              };
            },
            builder: (context, value, child) {
              return value['thread'].isEmpty && !value['error']
                  ? const CircularProgressIndicator()
                  : value['error']
                      ? Center(
                          child: Text(
                            value['errorMessage'],
                          ),
                        )
                      : Scrollbar(
                          child: ScrollablePositionedList.separated(
                            padding: const EdgeInsets.all(8),
                            itemScrollController: itemScrollController,
                            itemPositionsListener: itemPositionListener,
                            itemCount: value['thread'].length + 1,
                            //physics: const ClampingScrollPhysics(),
                            separatorBuilder: (context, index) {
                              // Hack to prevent jumpTo bounce effect
                              if (index == value['thread'].length - 1) {
                                return const SizedBox.shrink();
                              }
                              return const Divider(thickness: 1.0, height: 1.0);
                            },
                            itemBuilder: (context, index) {
                              // Hack to prevent jumpTo bounce effect
                              if (index == value['thread'].length) {
                                return const SizedBox.shrink();
                              }
                              Post item = value['thread'][index];
                              debugPrint(
                                  '------ Built Thread item $index ------');
                              return ThreadItem(item: item);
                            },
                          ),
                        );
            },
          ),
        ),
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        return !await nestedThreadKey.currentState!.maybePop();
      },
      child: Navigator(
        key: nestedThreadKey,
        onGenerateRoute: (settings) {
          if (settings.name == '/gallery') {
            final args = settings.arguments as Gallery;
            return PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, _, __) =>
                  Gallery(no: args.no, board: args.board),
            );
          }
          return MaterialPageRoute(builder: (context) => threadWidget);
        },
      ),
    );
  }

  void scrollToTop() {
    if (visibileItemIndexs().contains(0)) {
      debugPrint('------ Already at top! ------');
      return;
    }

    // Jump to has zero lag, however it rebuilds all items regardless, whereas scrollTo is opposite
    itemScrollController.jumpTo(index: 0, alignment: 0);
    //itemScrollController.scrollTo(index: 0, duration: const Duration(microseconds: 1), curve: Curves.easeIn);

    // const double offset = 0;
    // scrollController.jumpTo(offset);
    // // scrollController.animateTo(offset,
    // //     duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
  }

  void scrollToBottom() {
    final lastIndex = context.read<ApiData>().currentThread.length - 1;
    if (visibileItemIndexs().contains(lastIndex)) {
      debugPrint('------ Already at bottom! ------');
      return;
    }

    // Do nothing
    // if (fullyVisibleItemIndexes().contains(lastIndex)) {
    //   return;
    // } else if (partVisibleItemIndexes().contains(lastIndex)) {
    //   itemScrollController.scrollTo(index: lastIndex, duration: const Duration(microseconds: 1), curve: Curves.easeIn);
    // } else {
    //   itemScrollController.jumpTo(index: lastIndex, alignment: 0);
    // }

    //itemScrollController.jumpTo(index: lastIndex, alignment: 0);
    itemScrollController.jumpTo(index: lastIndex + 1, alignment: 1);
    //itemScrollController.scrollTo(index: lastIndex, duration: const Duration(microseconds: 1), curve: Curves.easeIn);

    // final double offset = scrollController.position.maxScrollExtent;
    // scrollController.jumpTo(offset);
    // // scrollController.animateTo(offset,
    // //     duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
  }

  void itemScrollListener() {
    final visibileItems =
        itemPositionListener.itemPositions.value.map((item) => item.index);
    debugPrint(visibileItems.toString());
  }

  List<int> visibileItemIndexs() {
    //final visibileItemIndexs = itemPositionListener.itemPositions.value.map((item) => item.index).toList();
    final visibileItemIndexs = itemPositionListener.itemPositions.value
        .where((item) {
          final topVisible = item.itemLeadingEdge >= 0;
          final bottomVisible = item.itemTrailingEdge <= 1;
          return topVisible && bottomVisible;
        })
        .map((item) => item.index)
        .toList();
    return visibileItemIndexs;
  }

  List<ItemPosition> visibileItemPositions() {
    final visibileItemIndexs =
        itemPositionListener.itemPositions.value.toList();
    return visibileItemIndexs;
  }

  List<int> partVisibleItemIndexes() {
    final positions = visibileItemPositions();

    final indexes = positions.map((item) => item.index).toList();
    return indexes;
  }

  List<int> fullyVisibleItemIndexes() {
    final positions = visibileItemPositions();

    final indexes = positions
        .where((item) {
          final topVisible = item.itemLeadingEdge >= 0;
          final bottomVisible = item.itemTrailingEdge <= 1;
          return topVisible && bottomVisible;
        })
        .map((item) => item.index)
        .toList();
    return indexes;
  }

  void updateScollPosition(int position) {
    debugPrint('------ Updating Scroll Position: $position ------');
    itemScrollController.scrollTo(
        index: position, duration: const Duration(milliseconds: 200));

    // final images = context.read<ApiData>().imagesMap;
    // final index = images.keys.elementAt(position);
    // debugPrint('----- Image Index: $index ------');

    // if (fullyVisibleItemIndexes().contains(index)) {
    //   return;
    // }
    // if (partVisibleItemIndexes().contains(index)) {
    //   itemScrollController.scrollTo(index: index, duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
    // } else {
    //   itemScrollController.jumpTo(index: index, alignment: 0);
    // }
  }
}

class ThreadItem extends StatelessWidget {
  const ThreadItem({
    Key? key,
    required this.item,
  }) : super(key: key);

  final Post item;
  @override
  Widget build(BuildContext context) {
    //debugPrint('------ Built Thread item ------');
    // final thread = context.read<ApiData>().currentThread;
    // context.read<ReplyPost>().populateRepliesMap(thread);

    return Container(
      //color: Colors.black45,
      width: double.maxFinite, // takes up all dialog box width
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      // constraints: const BoxConstraints(
      //     //minHeight: 260,
      //     ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.name ??
                    item.trip!), // TODO: handle possible overflow if name is super long, use text span
                const VerticalDivider(),
                Expanded(child: Text(item.no.toString())),
                Text(getDateTimeSince(item.time))
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (item.tim != null) ...[
                  InkWell(
                    child: Image.network(
                      // TODO: pass post.board instead of currenboard??
                      // this does not work if thread is different from last visited board from main
                      context.read<ApiData>().getThumbnailUrl(
                          item.tim!, context.read<ApiData>().currentBoard),
                      height: 100,
                      width: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, exception, stackTrace) {
                        return const SizedBox(
                          height: 100,
                          width: 90,
                          child: Icon(Icons.image),
                        );
                      },
                    ),
                    onTap: () {
                      final threadKey = Thread.of(context)!.nestedThreadKey;
                      threadKey.currentState!.pushNamed(
                        '/gallery',
                        arguments: Gallery(
                            no: item.no,
                            board: context.read<ApiData>().currentBoard),
                      );

                      // Navigator.push(
                      //   context,
                      //   PageRouteBuilder(
                      //     opaque: false,
                      //     pageBuilder: (context, _, __) => Gallery(
                      //         no: item.no,
                      //         board: context.read<ApiData>().currentBoard),
                      //   ),
                      // );
                    },
                  ),
                  const SizedBox(width: 8.0),
                ],
                SelectablePostDescription(sub: item.sub, com: item.com),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (context.read<ReplyPost>().repliesMap[item.no] != null) ...[
                  TextButton(
                    child: Text(
                        '${context.read<ReplyPost>().repliesMap[item.no]?.length} REPLIES'),
                    onPressed: () {
                      Set<int> replies =
                          context.read<ReplyPost>().repliesMap[item.no]!;
                      repliesDialog(context, replies);
                    },
                  )
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}

enum ThreadMenuOptions { reply, quote, imageInfo, openLink, copyLink }
