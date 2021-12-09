import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:neetchan/models/board.dart';
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/screens/gallery_screen.dart';
import 'package:neetchan/screens/thread_screen.dart';
import 'package:neetchan/services/app_settings.dart';
import 'package:neetchan/services/file_controller.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/utils/convert_units.dart';
import 'package:neetchan/widgets/post_text.dart';
import 'package:provider/provider.dart';

class Boards extends StatefulWidget {
  const Boards({Key? key}) : super(key: key);
  @override
  _BoardsState createState() => _BoardsState();
}

class _BoardsState extends State<Boards> {
  @override
  Widget build(BuildContext context) {
    //final appState = Provider.of<ApiData>(context);
    context.read<ApiData>().fetchCatalog();
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ApiData>(
          builder: (context, value, child) {
            return Text(AllBoards.boardMap[value.currentBoard]!.title);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () async {
              await context.read<ApiData>().fetchCatalog();
            },
            icon: const Icon(Icons.autorenew),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ApiData>().fetchCatalog();
        },
        child: Center(
          child: Consumer<ApiData>(
            builder: (context, value, child) {
              return value.currentCatalog.isEmpty && !value.error
                  ? const CircularProgressIndicator()
                  : value.error
                      ? Text(value.errorMessage)
                      : ListView.builder(
                          itemCount: value.currentCatalog.length,
                          itemBuilder: (context, index) {
                            Catalog item = value.currentCatalog[index];
                            return CatalogItem(item: item);
                          },
                        );
            },
          ),
        ),
      ),
    );
  }
}

class BuildCatlog extends StatelessWidget {
  const BuildCatlog({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    context.read<ApiData>().fetchCatalog();
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ApiData>().fetchCatalog();
      },
      child: Center(
        child: Consumer<ApiData>(
          builder: (context, value, child) {
            return value.currentCatalog.isEmpty && !value.error
                ? const CircularProgressIndicator()
                : value.error
                    ? Text(value.errorMessage)
                    : ListView.builder(
                        itemCount: value.currentCatalog.length,
                        itemBuilder: (context, index) {
                          Catalog item = value.currentCatalog[index];
                          return CatalogItem(item: item);
                        },
                      );
          },
        ),
      ),
    );
  }
}

class CatalogItem extends StatelessWidget {
  const CatalogItem({
    Key? key,
    required this.item,
  }) : super(key: key);

  final Catalog item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
      constraints: const BoxConstraints(
          //minHeight: 260,
          ),
      child: Card(
        elevation: 2.0,
        child: InkWell(
          onTap: () {
            // pause logging history
            if (!context.read<AppSettings>().isCognitoMode) {
              item.accessedOn = DateTime.now().millisecondsSinceEpoch;
              context.read<FileController>().writeHistory(item.toJson());
            }

            var json = jsonEncode(item.toJson());
            debugPrint('\n');
            debugPrint(json);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Thread(
                  no: item.no,
                  board: item.board!,
                  op: item, // uncessary but waah
                ),
              ),
            ).then((value) {
              context.read<ApiData>().clearCurrentThread();
              context.read<ApiData>().clearCurrentImages();
              // Clear repliesMap
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name ?? item.trip!),
                    const VerticalDivider(),
                    Expanded(child: Text(item.no.toString())),
                    Text(getDateTimeSince(item.time))
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.tim != 0) ...[
                      // unecessary but crashes debug session
                      InkWell(
                        child: Image.network(
                          context
                              .read<ApiData>()
                              .getThumbnailUrl(item.tim!, item.board ?? 'a'),
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
                              builder: (context) =>
                                  Gallery(no: item.no, board: item.board!),
                            ),
                          ).then((value) {
                            context.read<ApiData>().clearCurrentThread();
                            context.read<ApiData>().clearCurrentImages();
                            debugPrint(
                                '----POP index: ${context.read<ApiData>().currentImageIndex}---------');
                          });
                        },
                      ),
                    ],
                    PostDescription(sub: item.sub, com: item.com),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('${item.replies.toString().toUpperCase()} REPLIES'),
                    const SizedBox(width: 16),
                    Text('${item.images.toString().toUpperCase()} IMAGES'),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
