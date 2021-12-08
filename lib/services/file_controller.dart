import 'package:flutter/foundation.dart';
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/utils/file_manager.dart';

class FileController extends ChangeNotifier {
  List<Catalog> historyLogs = [];
  Map<String, Map<String, dynamic>> bookmarks = {};


  readHistory() async {
    final result = await FileUtil.readFromFile();

    if (result.isNotEmpty) {
      List<Catalog> logs = [];

      for (final log in result) {
        logs.add(Catalog.fromJson(log)); 
        // logs.insert(0, Catalog.fromJson(log)); // insert at start
      }
      historyLogs = logs;
    }
    notifyListeners();
  }


  writeHistory(item) async {
    await FileUtil.writeToFile(item);
    readHistory();
  }


  deleteHistoryItem(int index) async {
    historyLogs.removeAt(index);
    await FileUtil.deleteHistory(historyLogs);

    notifyListeners();
  }


  writeBookMark(int no, op, replies) async {
    await FileUtil.writeBookmarkToFile(no, op, replies);
    readBookMark();
  }


  readBookMark() async {
    final result = await FileUtil.readBookmarkFromFile();

    if (result.isNotEmpty) {
      Map<String, Map<String, dynamic>> posts = {};

      for (MapEntry e in result.entries) {
        final op = Catalog.fromJson(e.value['op']);
        List<Post> replies = [];
        for (final item in e.value['replies']) {
          replies.add(Post.fromJson(item));
        }
        posts[e.key] = {"op": op, "replies": replies};
      }
      bookmarks = posts;
    }

    notifyListeners();
  }


  deleteBookmarkItem(String key) async {
    bookmarks.remove(key);
    await FileUtil.deleteBookmark(bookmarks);

    notifyListeners();
  }
}
