import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/utils/stack.dart' as stack;

class ApiData extends ChangeNotifier {
  // Persists only a single Board Catalog
  List<Catalog> catalog = [];

  //HashMap<String, List<Post>> threads = HashMap();
  // A map of concurrently open threads
  Map<int, List<Post>> threads = {};
  Map<int, bool> errors = {};
  Map<int, String> errorMessages = {};

  // current threadNo
  stack.Stack<int> threadNoStack = stack.Stack();

  // current Thread
  List<Post> thread = [];

  // Posts in the current Thread with media attachments
  List<Post> images = [];

  // Move this to another Class 
  bool isGalleryGridView = false;
  PageController pageController = PageController();
  late ScrollController scrollController;

  void updatePage(int index) {
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
      debugPrint('------ Jumping to page ${pageController.page!.floor()} in Gallery Screen ------');

    } else {
      debugPrint('------ PageController has no listeners ------');
    }

    notifyListeners();
  }

  void updateScrollposition(double index) {
    if (scrollController.hasClients) {
      debugPrint('------ Jumping to $index in GalleryGrid Screen ------');
      if (index >= scrollController.position.maxScrollExtent) {
        return;
      }
      scrollController.jumpTo(index);
    } else {
      debugPrint('------ SCrollController has no listeners ------');
    }
  
    notifyListeners();
  }

  void toggleGalleryGridView() {
    isGalleryGridView = !isGalleryGridView;
    notifyListeners();
  }

  int imageIndex = 0;

  // Tracks the current board, defaults to 'anime & manga'
  String board = 'a';

  // Invalid default Thread no
  int threadNo = 0;

  bool catalogError = false;
  bool error = false;
  bool currentThreadError = false;
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
    if (index == imageIndex) {
      return;
    } 
    imageIndex = index;
    // Comment this out
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
    try {
      final response =
          await http.get(Uri.parse('https://a.4cdn.org/$board/catalog.json'));

      if (response.statusCode == HttpStatus.ok) {
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
      } else {
        catalogError = true;
        errorMessage = 'Failed to load /$board/';
      }
    } on SocketException {
      catalogError = true;
      errorMessage = 'Check your Internet Connection';
    } on FormatException {
      catalogError = true;
      errorMessage = 'Error occured parsing Catalog format';
    } catch (e) {
      catalogError = true;
      errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> fetchThread(int no, String thisBoard) async {
    // final response =
    //     await http.get(Uri.parse('https://a.4cdn.org/$board/thread/$no.json'));
    threads[no] = [];
    errors[no] = false;
    errorMessages[no] = '';
    try {
      final response = await http
          .get(Uri.parse('https://a.4cdn.org/$thisBoard/thread/$no.json'));

      if (response.statusCode == HttpStatus.ok) {
        final parsed = jsonDecode(response.body);
        List<Post> newThread = [];
        for (var post in parsed['posts']) {
          newThread.add(Post.fromJson(post));
        }
        thread = newThread;

        // No need to push to stack on thread refresh
        // if (!threadNoStack.isEmpty() && threadNoStack.peek() != no) {
        //   threadNoStack.push(no);
        // }
        threadNoStack.push(no);

        // Add Map entry
        threads[no] = newThread;
      } else {
        error = true;
        errorMessages[no] = 'Too bad the thread was pruned';
        errors[no] = true;
        currentThreadError = true;
      }
    } on SocketException {
      error = true;
      errorMessages[no] = 'Check your Internet Connection';
      errors[no] = true;
      currentThreadError = true;
    } on FormatException {
      error = true;
      errorMessages[no] = 'Error occured parsing Thread format';
      errors[no] = true;
      currentThreadError = true;
    } catch (e) {
      error = true;
      errorMessages[no] = e.toString();
      errors[no] = true;
      currentThreadError = true;
    }

    notifyListeners();
  }

  Future<void> fetchImages(int no, String thisBoard) async {
    // Get all posts in a thread
    var threadNo = no;
    try {
      // Thread screen
      threadNo = threadNoStack.peek();
    } on StateError {
      // Catalog screen
      threadNo = no;
    } finally {
      if (threads[threadNo] == null) {
        await fetchThread(threadNo, thisBoard);
      }

      if (!error) {
        final ext = ['.jpg', '.png', '.gif', '.webm'];
        // Populate list of posts with attachments only
        images = threads[threadNo]!.where((post) {
          return ext.contains(post.ext);
        }).toList();
        // Get the current image index
        imageIndex = images.indexWhere((post) => post.no == no);
      }
    }
  }

  // TODO: refactor this
  void clearThread() {
    error = false;
    currentThreadError = false;
    thread = [];
    images = [];
    imageIndex = 0;
    notifyListeners();
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
