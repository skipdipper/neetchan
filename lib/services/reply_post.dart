import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:neetchan/models/post.dart';

class ReplyPost extends ChangeNotifier {
  // Change to List<int> to Set<int>
  // key: post in a thread; value: replies to the post 
  HashMap<int, Set<int>> repliesMap = HashMap();
  //HashMap<int, List<int>> repliesMap = HashMap();

  // HashMap<int, List<int>> get getRepliesMap => repliesMap;
  HashMap<int, Set<int>> get getRepliesMap => repliesMap;

  void clearRepliesMap() {
    repliesMap = HashMap();
    notifyListeners();
  }

  // Helper method that add or updates replies to a repliesMap
  void addReplies(int no, List<int> replies) {
    // For each post's reply[s] to <<#post
    for (int reply in replies) {
      // repliesMap.putIfAbsent(no, () => []);
      if (!repliesMap.containsKey(reply)) {
        // replies to one post
        // repliesMap[reply] = [no];
        repliesMap[reply] = {no};
      } else {
        repliesMap.update(reply, (list) {
          // replies to more than one post
          list.add(no);

          return list;
        });
      }
    }
    //notifyListeners();
  }

  void populateRepliesMap(List<Post> thread) {
    //final posts = thread;
    for (Post post in thread) {
      if (post.com != null) {
        List<int> replyNos = parseRepliesHtml(post.com!);
        // populates the existing empty HashMap repliesMap
        addReplies(post.no, replyNos);
      }
    }
  }

  // Returns a list of replies no for given html string of comment
  List<int> parseRepliesHtml(String com) {
    var document = parseFragment(com);
    // Get list of elements that contain anchor tag with class quotelink
    // href does contain 'thread' link to another thread 
    final replies = document.querySelectorAll('a:not([href*="thread"]).quotelink');

    final replyNos = replies.map((element) {
      final no = element.attributes['href']!.split('#p').last;
      //String no = element.innerHtml.split(';').last; // element.innerText
      var value = int.tryParse(no);
      if (value == null) {
        debugPrint('------ Invalid Post No: $no ------');
        return 404;
      }
      return value;
    }).toList();

    // if (replyNos.isEmpty) {
    //   debugPrint('EMPTY LIST OF REPLIES');
    // }
    return replyNos;
  }
}
