import 'package:flutter/cupertino.dart';
import 'views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReelDownloaderApp());
}

class ReelDownloaderApp extends StatelessWidget {
  const ReelDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'ReelFlow - Reel Downloader',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
        barBackgroundColor: CupertinoColors.white,
        textTheme: CupertinoTextThemeData(
          navLargeTitleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 32,
            letterSpacing: -0.8,
            color: CupertinoColors.black,
          ),
          textStyle: TextStyle(
            letterSpacing: -0.2,
            color: CupertinoColors.black,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeView(),
    );
  }
}
