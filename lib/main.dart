import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/news_feed.dart';
import 'package:readeus/pages/test.dart';
import 'package:readeus/pages/welcome_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WebViewPlatform.instance = WebViewPlatform.instance; // Ensure platform initialization

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Test(),
      // home: WelcomePage(),
    );
  }
}

