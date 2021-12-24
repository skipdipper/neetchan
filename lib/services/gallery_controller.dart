import 'package:flutter/material.dart';

class GalleryController extends ChangeNotifier {
  PageController galleryController = PageController();
  ScrollController scrollController = ScrollController();
  PageController pageController = PageController();

  int selectedGalleryIndex = 0;

  void toggleGalleryView(int index) {
    if (galleryController.hasClients) {
      galleryController.jumpToPage(index);
    } else {
      debugPrint('------ Gallery Controller has no listeners ------');
    }
    notifyListeners();
  }

  // Scroll position of Gallery grid view
  void updateScrollposition(double index) {
    if (scrollController.hasClients) {
      debugPrint('------ Jumping to ${index + 1} in GalleryGrid Screen ------');
      if (index >= scrollController.position.maxScrollExtent) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      } else {
        scrollController.jumpTo(index);
      }
    } else {
      debugPrint('------ ScrollController has no listeners ------');
    }
    notifyListeners();
  }

  void updatePage(int index) {
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
      debugPrint(
          '------ Jumping to page ${pageController.page!.floor() + 1} in Gallery Screen ------');
    } else {
      debugPrint('------ PageController has no listeners ------');
    }

    notifyListeners();
  }
}
