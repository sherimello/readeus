// // webview_scraper_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// // Adjust import path to your controller file
// import '../controllers/scrapper_controller.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'dart:developer'; // for log
//
// class WebViewScraperView extends StatelessWidget {
//   final String url;
//   final String? tag;
//
//   const WebViewScraperView({
//     super.key,
//     required this.url,
//     this.tag,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // Get.put ensures the controller is created if not already present with this tag
//     final WebViewScraperController controller = Get.put(
//       WebViewScraperController(initialUrl: url),
//       tag: tag,
//     );
//
//     log("WebViewScraperView build called. URL: $url, Tag: $tag. Controller initialized/found.");
//
//     // Keep it running but offscreen
//     return WebViewWidget(controller: controller.webViewController);
//   }
// }