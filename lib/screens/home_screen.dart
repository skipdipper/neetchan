import 'package:flutter/material.dart';
import 'package:neetchan/models/board.dart';
import 'package:neetchan/screens/catalog_screen.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:provider/provider.dart';

class Home extends StatelessWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          body: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    const SliverAppBar(
                      pinned: true,
                      floating: true,
                      title: Text('NeetChan'),
                      bottom: TabBar(
                        tabs: [
                          Tab(text: 'Boards'),
                          Tab(text: 'Popular'),
                        ],
                      ),
                    ),
                  ],
              body: TabBarView(
                children: [
                  Column(
                    children: const [
                      Expanded(child: BoardMenu()),
                    ],
                  ),
                  const BuildCatlog(),
                ],
              )),
        ),
      ),
    );
  }
}

class BoardMenu extends StatelessWidget {
  const BoardMenu({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        //padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          Board board = AllBoards.boards[index];
          return ListTile(
            title: Text('/${board.board}/ - ${board.title}'),
            onTap: () {
              context.read<ApiData>().clearCurrentCatalog();
              context.read<ApiData>().changeBoard(board.board);
              //context.read<ApiData>().fetchCatalog();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Boards(),
                ),
              );
            },
            onLongPress: () {},
          );
        },
        separatorBuilder: (context, index) =>
            const Divider(thickness: 1.0, height: 0),
        itemCount: AllBoards.boards.length);
  }
}
