import 'package:flutter/material.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/screens/gallery_screen.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/services/reply_post.dart';
import 'package:neetchan/services/file_controller.dart';
import 'package:neetchan/utils/convert_units.dart';
import 'package:neetchan/widgets/post_text.dart';
import 'package:provider/provider.dart';

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

  @override
  _ThreadState createState() => _ThreadState();
}

class _ThreadState extends State<Thread> {
  final scrollController = ScrollController();
  bool bookMarked = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<ApiData>().fetchThread(widget.no, widget.board).then((_) {
      final thread = context.read<ApiData>().currentThread;

      context.read<ReplyPost>().populateRepliesMap(thread);
    });
    return Scaffold(
      appBar: AppBar(
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
          child: Consumer<ApiData>(
            builder: (context, value, child) {
              return value.currentThread.isEmpty && !value.error
                  ? const CircularProgressIndicator()
                  : value.error
                      ? Text(value.errorMessage)
                      : ListView.separated(
                          //shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          controller: scrollController,
                          itemCount: value.currentThread.length,
                          separatorBuilder: (context, index) =>
                              const Divider(thickness: 1.0, height: 0),
                          itemBuilder: (context, index) {
                            Post item = value.currentThread[index];
                            return ThreadItem(item: item);
                          },
                        );
            },
          ),
        ),
      ),
    );
  }

  void scrollToTop() {
    const double offset = 0;
    //scrollController.jumpTo(offset);
    scrollController.animateTo(offset,
        duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
  }

  void scrollToBottom() {
    final double offset = scrollController.position.maxScrollExtent;
    //scrollController.jumpTo(offset);
    scrollController.animateTo(offset,
        duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // TODO: change current Board via ApiData to storing in Post model
                          // May not cos you can only view one gallery at once
                          builder: (context) => Gallery(
                              no: item.no,
                              board: context.read<ApiData>().currentBoard),
                        ),
                      );
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
                        '${context.read<ReplyPost>().repliesMap[item.no]!.length} REPLIES'),
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
