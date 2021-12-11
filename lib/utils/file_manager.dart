import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
//import 'package:gallery_saver/gallery_saver.dart';
import 'package:gallery_saver_webm/gallery_saver.dart';

class FileUtil {
  static String fileName = "history_log.json";
  static String bookmarks = "bookmarks.json";

  static Future<String> get getDirectoryPath async {
    final directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  static Future<File> get getFile async {
    final path = await getDirectoryPath;
    return File('$path/$fileName');
  }

  static Future<File> get getBookmarkFile async {
    final path = await getDirectoryPath;
    return File('$path/$bookmarks');
  }

  static Future readFromFile() async {
    final file = await getFile;

    if (await file.exists()) {
      try {
        final fileContent = await file.readAsString();
        return jsonDecode(fileContent);
      } catch (e) {
        throw Exception(e);
      }
    } else {
      debugPrint('File does not exist');
      return [];
    }
  }

  static Future<void> writeToFile(item) async {
    File file = await getFile;
    RandomAccessFile raf = await file.open(mode: FileMode.append);
    int len = await file.length();
    final entry = jsonEncode(item);

    if (len > 0) {
      var newFile = await raf.setPosition(len - 1);
      await newFile.writeString(",$entry]");
      debugPrint(file.readAsStringSync());
      await newFile.close();
    } else {
      await raf.writeString("[$entry]");
      debugPrint('\n');
      debugPrint(file.readAsStringSync());
      await raf.close();
    }
  }

  // int start = indexof pattern: {"no":item.no, [int start = 0]
  // if index != -1 (not match)
  // if index <= 2 (not the first entry)
  //    int end = index of pattern: {"}", [int start = start]}
  //  replaceRange(start, end, ''); with empty string

  static Future<void> deleteHistory(history) async {
    File file = await getFile;
    if (await file.exists()) {
      final his = jsonEncode(history);
      await file.writeAsString(his);
    }
  }

  static Future<void> writeBookmarkToFile(int no, op, replies) async {
    File file = await getBookmarkFile;
    RandomAccessFile raf = await file.open(mode: FileMode.append);
    int len = await file.length();
    final jop = jsonEncode(op);
    final jreplies = jsonEncode(replies);

    if (len > 0) {
      var newFile = await raf.setPosition(len - 1);
      await newFile
          .writeString(",\"$no\":{\"op\":$jop,\"replies\":$jreplies}}");
      debugPrint(file.readAsStringSync());
      await newFile.close();
    } else {
      await raf.writeString("{\"$no\":{\"op\":$jop,\"replies\":$jreplies}}");
      debugPrint('\n');
      debugPrint(file.readAsStringSync());
      await raf.close();
    }
  }

  static Future<Map<String, dynamic>> readBookmarkFromFile() async {
    final file = await getBookmarkFile;

    if (await file.exists()) {
      try {
        final fileContent = await file.readAsString();
        return jsonDecode(fileContent);
      } catch (e) {
        throw Exception(e);
      }
    } else {
      debugPrint('File does not exist');
      return {};
    }
  }

  static Future<void> deleteBookmark(bookmark) async {
    File file = await getBookmarkFile;
    if (await file.exists()) {
      final book = jsonEncode(bookmark);
      await file.writeAsString(book);
    }
  }

  // Make single permission request
  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result.isGranted) {
        return true;
      } else {
        return false;
      }
    }
  }

  static Future<bool> saveImageToStorage(
      String fileName, String ext, String url) async {
    try {
      if (await requestPermission(Permission.storage)) {
        debugPrint('-------------------PERMISSION GRANTED ------------------');
        const folder = "NeetChan";
        final directory = Directory('storage/emulated/0/$folder');

        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        if (await directory.exists()) {
          debugPrint('-------------------DIRECTORY EXISTS ------------------');
          final path = '${directory.path}/$fileName$ext';
          File image = File(path);
          //TODO: check if image cached
          //final response = await http.get(Uri.parse(url));
          //await image.writeAsBytes(response.bodyBytes);

          if (ext == '.webm') { 
            final res = await GallerySaver.saveVideo(url, albumName: folder, fileName: fileName);
            debugPrint('$res');
          } else {
            final res = await GallerySaver.saveImage(url, albumName: folder, fileName: fileName);
            debugPrint('$res');
          }
          return true;
        }
      } else {
        // permission not granted
        return false;
      }
    } catch (e) {
      throw Exception(e);
    }

    return false;
  }

  static Future<String> get getCacheDirectoryPath async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }
}
