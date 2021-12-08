import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/models/post.dart';

class ApiData extends ChangeNotifier {
  // Persists only a single Board Catalog
  List<Catalog> catalog = [];

  //HashMap<String, List<Post>> threads = HashMap();
  // A map of concurrently open threads
  Map<int, List<Post>> threads = {};

  // current Thread
  List<Post> thread = [];

  // Posts in the current Thread with media attachments
  List<Post> images = [];

  int imageIndex = 0;

  // Tracks the current board, defaults to 'anime & manga'
  String board = 'a';

  // Invalid default Thread no
  int threadNo = 0;

  bool error = false;
  String errorMessage = '';

  // Tapping on a Catalog card or open tab thread updates current thread no
  // Could use a setter but this looks more clear
  void changeThread(int no) {
    threadNo = no;
    notifyListeners();
  }

  void changeBoard(String newBoard) {
    board = newBoard;
    //notifyListeners();
  }

  // navigator pop or switch tabs, so that progress indicator shows
  void clearCurrentThread() {
    thread = [];
    notifyListeners();
  }

  void clearCurrentCatalog() {
    catalog = [];
    error = false;
    notifyListeners();
  }

  // update image index
  void updateImageIndex(int index) {
    imageIndex = index;
    notifyListeners();
  }

  // navigator pop from catalog
  void clearCurrentImages() {
    images = [];
    imageIndex = 0;

    //thread = [];
    notifyListeners();
  }

  List<Post> getThread(int no) {
    return threads[no]!;
  }

  String get currentBoard => board;
  int get currenThreadNo => threadNo;
  List<Catalog> get currentCatalog => catalog;
  List<Post> get currentThread => thread;
  Map<int, List<Post>> get mapThreads => threads;
  int get currentImageIndex => imageIndex;

  // Fetches all OPs for every page on a single board catalog
  Future<void> fetchCatalog() async {
    final response =
        await http.get(Uri.parse('https://a.4cdn.org/$board/catalog.json'));

    if (response.statusCode == 200) {
      try {
        final parsed = jsonDecode(response.body);

        // Iterate through each page
        // This should be done in Models instead
        List<Catalog> catalogList = [];
        parsed.forEach((page) {
          Map obj = page;
          List threadsList = obj['threads'];
          // Update the catalog list instance

          // catalogList
          //     .addAll(threadsList.map((e) => Catalog.fromJson(e)).toList());

          catalogList.addAll(threadsList.map((e) {
            Catalog catalog = Catalog.fromJson(e);
            // Manually add board to Catalog model
            catalog.board = currentBoard;
            return catalog;
          }).toList());
        });
        catalog = catalogList;
      } catch (e) {
        error = true;
        errorMessage = e.toString();
        //throw Exception('Error occured parsing Catalog format');
        debugPrint('Error occured parsing Catalog format');
        throw Exception(e);
      }
    } else {
      error = true;
      throw Exception('Failed to load Catalog');
    }

    notifyListeners();
  }

  Future<void> fetchThread(int no, String thisBoard) async {
    // final response =
    //     await http.get(Uri.parse('https://a.4cdn.org/$board/thread/$no.json'));

    final response = await http
        .get(Uri.parse('https://a.4cdn.org/$thisBoard/thread/$no.json'));

    if (response.statusCode == 200) {
      try {
        final parsed = jsonDecode(response.body);
        List<Post> newThread = [];
        for (var post in parsed['posts']) {
          newThread.add(Post.fromJson(post));
        }
        thread = newThread;

        // Add Map entry
        threads[no] = newThread;
      } catch (e) {
        error = true;
        errorMessage = e.toString();
        throw Exception(e);
        //throw Exception('Error occured parsing Thread format');
      }
    } else {
      error = true;
      throw Exception('Failed to load Thread');
    }

    notifyListeners();
  }

  // TODO: changed this add thisBoard
  Future<void> fetchImages(int no, String thisBoard) async {
    // Get all posts in a thread

    if (thread.isEmpty) {
      // only fetchthread if launch gallery from Catalog screen
      await fetchThread(no, thisBoard);
    }
    //await fetchThread(no); // this breaks shit

    // Get a list of posts with images
    if (!error) {
      final ext = ['.jpg', '.png', '.gif', '.webm'];
      // Populate list of posts with attachments only
      images = thread.where((post) {
        return ext.contains(post.ext);
      }).toList();
      // Get the current image index
      imageIndex = images.indexWhere((post) => post.no == no);
    }
  }

  // String getThumbnailUrl(int tim) {
  //   String imageUrl = 'https://i.4cdn.org/$board/' + tim.toString() + 's.jpg';
  //   return imageUrl;
  // }

  String getThumbnailUrl(int tim, String thisBoard) {
    String imageUrl =
        'https://i.4cdn.org/$thisBoard/' + tim.toString() + 's.jpg';
    return imageUrl;
  }

  String getImageUrl(int tim, String ext) {
    String imageUrl =
        'https://i.4cdn.org/$board/' + tim.toString() + ext.toString();
    return imageUrl;
  }
}
