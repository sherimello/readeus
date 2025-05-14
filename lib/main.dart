import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/news_feed.dart';
import 'package:readeus/pages/news_portals.dart';
import 'package:readeus/pages/bangla_news_fetcher.dart';
import 'package:readeus/pages/splash.dart';
import 'package:readeus/pages/test.dart';
import 'package:readeus/pages/welcome_page.dart';
import 'package:readeus/widgets/garbage.dart';
import 'package:readeus/widgets/image_scrapper.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WebViewPlatform.instance = WebViewPlatform.instance; // Ensure platform initialization
  // Set the system UI styles BEFORE runApp
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    // Make the status bar transparent
    statusBarColor: Colors.transparent,

    // === IMPORTANT ===
    // Choose the icon brightness based on the background BEHIND the status bar
    // Use Brightness.light for dark backgrounds
    // Use Brightness.dark for light backgrounds
    statusBarIconBrightness: Brightness.dark, // Or Brightness.light

    // Optional: You can also control the bottom navigation bar appearance
    // systemNavigationBarColor: Colors.transparent, // Make nav bar transparent
    // systemNavigationBarIconBrightness: Brightness.dark, // Or Brightness.light
    // systemNavigationBarDividerColor: Colors.transparent, // Optional: Hide divider
  ));

  // Ensure the app respects the edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // home: DockAnimationDemoScreen(),
      // home: NewsPortals(),
      // home: Test(),
      // home: WelcomePage(),
      home: Splash(),
      // home: Test(),
      // home: Splash(url: "https://www.prothomalo.com/politics"),
      // home: ImageScraper(url: "https://www.prothomalo.com/collection/latest"),
    );
  }
}

