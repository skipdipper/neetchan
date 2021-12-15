import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/screens/thread_screen.dart';
import 'package:neetchan/services/file_controller.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:provider/provider.dart';

class BookMarks extends StatefulWidget {
  const BookMarks({Key? key}) : super(key: key);
  @override
  _BookMarksState createState() => _BookMarksState();
}

class _BookMarksState extends State<BookMarks> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: const BuildBookmark(),
    );
  }
}

class BuildBookmark extends StatelessWidget {
  const BuildBookmark({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    debugPrint('------ Built Bookmark screen ------');
    context.read<FileController>().readBookMark();
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<FileController>().readBookMark();
      },
      child: Center(
        child: Consumer<FileController>(
          builder: (context, value, child) {
            return value.bookmarks.isEmpty
                ? const Center(child: Text('Wow such empty'))
                : ListView.builder(
                    itemCount: value.bookmarks.length,
                    itemBuilder: (context, index) {
                      Catalog item =
                          value.bookmarks.values.elementAt(value.bookmarks.length - index - 1)['op'];
                      String itemKey = value.bookmarks.keys.elementAt(value.bookmarks.length - index - 1);
                      return BookMarkItem(item: item, itemKey: itemKey);
                    },
                  );
          },
        ),
      ),
    );
  }
}

class BookMarkItem extends StatelessWidget {
  const BookMarkItem({
    Key? key,
    required this.item,
    required this.itemKey,
  }) : super(key: key);

  final Catalog item;
  final String itemKey;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 60,
        child: Image.network(
          context.read<ApiData>().getThumbnailUrl(item.tim!, item.board ?? 'a'),
          width: 60,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, exception, stackTrace) {
            return const SizedBox(
              height: 100,
              width: 90,
              child: Icon(Icons.image),
            );
          },
        ),
      ),
      title: Html(
        data: item.sub ?? item.com ?? '',
        style: {
          '#': Style(
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
          's': Style(
            backgroundColor: Colors.black,
            color: Colors.black,
            textDecoration: TextDecoration.none,
          ),
        },
      ),
      subtitle: Text('/${item.board}/${item.no}'),
      trailing: IconButton(
        onPressed: () async {
          await context.read<FileController>().deleteBookmarkItem(itemKey);
        },
        icon: const Icon(Icons.delete_outline),
      ),
      onTap: () {
        // TODO: load from local storage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Thread(
              no: item.no,
              board: item.board ?? 'a',
              op: item, // uncessary but waah
            ),
          ),
        ).then((value) {
          context.read<ApiData>().clearThread();
          // Clear repliesMap
        });
      },
    );
  }
}
