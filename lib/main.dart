import 'package:flutter/material.dart';
import 'package:neetchan/screens/bottom_navigation.dart';
import 'package:neetchan/services/file_controller.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/services/reply_post.dart';
import 'package:neetchan/services/app_settings.dart';
import 'package:neetchan/services/gallery_controller.dart';
import 'package:neetchan/services/api_change_notifier.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const NeetChan());
}

class NeetChan extends StatelessWidget {
  const NeetChan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ApiData(),
        ),
        ChangeNotifierProvider(
          create: (context) => ReplyPost(),
        ),
        ChangeNotifierProvider(
          create: (context) => AppSettings(),
        ),
        ChangeNotifierProvider(
          create: (context) => FileController(),
        ),
        ChangeNotifierProvider(
          create: (context) => GalleryController(),
        ),
      ],
      builder: (context, _) {
        final themeProvider = Provider.of<AppSettings>(context);
        return MaterialApp(
          title: 'NeetChan',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Root(),
        );
      },
    );
  }
}
