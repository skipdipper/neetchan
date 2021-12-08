class Board {
  final String board;
  final String title;

  const Board({required this.board, required this.title});
}

class AllBoards {
  static const List<Board> boards = [
    Board(board: 'a', title: 'Anime & Manga'),
    Board(board: 'b', title: 'Random'),
    Board(board: 'c', title: 'Anime/Cute'),
    Board(board: 'jp', title: 'Otaku Culture'),
    Board(board: 'vt', title: 'Virtual Youtubers'),
  ];

  static const Map<String, Board> boardMap = {
    'a': Board(board: 'a', title: 'Anime & Manga'),
    'b': Board(board: 'b', title: 'Random'),
    'c': Board(board: 'c', title: 'Anime/Cute'),
    'jp': Board(board: 'jp', title: 'Otaku Culture'),
    'vt': Board(board: 'vt', title: 'Virtual Youtubers'),
  };
}
