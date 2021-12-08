import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/screens/thread_screen.dart';
import 'package:neetchan/services/file_controller.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:provider/provider.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: const BuildHistory(),
    );
  }
}

class BuildHistory extends StatelessWidget {
  const BuildHistory({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    context.read<FileController>().readHistory();
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<FileController>().readHistory();
      },
      child: Center(
        child: Consumer<FileController>(
          builder: (context, value, child) {
            return value.historyLogs.isEmpty
                ? const Center(child: Text('Wow such empty'))
                : ListView.builder(
                    itemCount: value.historyLogs.length,
                    itemBuilder: (context, index) {
                      Catalog item = value
                          .historyLogs[value.historyLogs.length - index - 1];

                      // Todo: hot fix history OP on pressed: context.read<ApiData>().changeBoard(item.board ?? 'a');
                      // Catalog item = value.historyLogs[index];
                      //return CatalogItem(item: item);
                      return HistoryItem(item: item, index: value.historyLogs.length - index - 1);
                    },
                  );
          },
        ),
      ),
    );
  }
}

class HistoryItem extends StatelessWidget {
  const HistoryItem({
    Key? key,
    required this.item,
    required this.index,
  }) : super(key: key);

  final Catalog item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 60,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(
                  item: item,
                ),
              ),
            );
          },
          child: Hero(
            tag: item,
            child: Image.network(
              context
                  .read<ApiData>()
                  .getThumbnailUrl(item.tim!, item.board ?? 'a'),
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
          await context.read<FileController>().deleteHistoryItem(index);
        },
        icon: const Icon(Icons.delete_outline),
      ),
      onTap: () {
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
          context.read<ApiData>().clearCurrentThread(); 
          context.read<ApiData>().clearCurrentImages();
          // reset error to false
          // Clear repliesMap
        });
      },
    );
  }
}

class Details extends StatelessWidget {
  const Details({
    Key? key,
    required this.item,
  }) : super(key: key);

  final Catalog item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.filename.toString())),
      body: Hero(
        tag: item,
        child: Image.network(
          context.read<ApiData>().getThumbnailUrl(item.tim!, item.board ?? 'a'),
          errorBuilder: (context, exception, stackTrace) {
            return const SizedBox(
              height: 100,
              width: 90,
              child: Icon(Icons.image),
            );
          },
        ),
      ),
    );
  }
}
