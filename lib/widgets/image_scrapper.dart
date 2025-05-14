import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
// WKWebView is automatically used on iOS if available, no explicit import needed for basic use

class ImageScraper extends StatefulWidget {
  final String url;

  const ImageScraper({super.key, required this.url});

  @override
  State<ImageScraper> createState() => _ImageScraperState();
}

class _ImageScraperState extends State<ImageScraper> {
  late WebViewController _controller;
  List<String> imageUrls = [];
  var _titles = [], _timestamps = [];
  bool isLoading = true;
  bool _pageLoadFinished = false; // Track initial page load completion

  // --- Configuration ---
  final Duration initialWaitDuration = const Duration(seconds: 3); // Wait after onPageFinished before scrolling
  final Duration postScrollWaitDuration = const Duration(seconds: 8); // Wait after scrolling before extracting
  final Duration finalTimeoutDuration = const Duration(seconds: 5); // Overall timeout
  // ---------------------

  Timer? _timeoutTimer; // Timer for overall timeout

  @override
  void initState() {
    super.initState();

    late final WebViewController controller;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            // Reset state for a new load/refresh
            _cancelTimeout(); // Cancel any existing timeout
            setState(() {
              isLoading = true;
              _pageLoadFinished = false;
              imageUrls = [];
            });
          },
          onPageFinished: (String url) async {
            debugPrint('Page finished loading: $url');
            // Ensure this runs only once after the initial page load finishes
            // and only if the timeout hasn't already completed the process
            if (!_pageLoadFinished && !( _timeoutTimer?.isActive ?? false)) {
              setState(() { _pageLoadFinished = true; });
              await _scrollToAbsoluteBottomAndExtract(controller);
              // await _scrollOnceAndExtract(controller);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}''');
            _failLoading("Web resource error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Platform specific WebView configuration
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Requires importing 'package:webview_flutter_android/webview_flutter_android.dart';
      AndroidWebViewController.enableDebugging(true);
    }

    _controller = controller;
    _startTimeout(); // Start the overall timeout
  }

  @override
  void dispose() {
    _cancelTimeout(); // Clean up timer on dispose
    super.dispose();
  }

  void _startTimeout() {
    _cancelTimeout(); // Ensure no previous timer is running
    _timeoutTimer = Timer(finalTimeoutDuration, () {
      if (mounted && isLoading && !_pageLoadFinished) { // Check if still mounted and loading
        debugPrint("Overall Timeout Reached - attempting extraction anyway");
        // Attempt extraction even on timeout, might get some initial images
        _extractImages(_controller); // Don't await here in timeout
        // Or simply fail:
        // _failLoading("Timeout reached before page finished loading");
      } else if(mounted && !_pageLoadFinished) {
        // If loading finished but extraction didn't complete somehow
        _failLoading("Timeout reached after load, extraction incomplete");
      }
    });
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _failLoading(String message) {
    if (mounted) {
      debugPrint("Loading failed: $message");
      setState(() {
        isLoading = false;
        imageUrls = []; // Ensure image list is empty on failure
      });
      _cancelTimeout(); // Stop the timeout if we failed early
    }
  }
  Future<void> _scrollToAbsoluteBottomAndExtract(WebViewController controller) async {
    if (!mounted) return;
    setState(() => isLoading = true); // Start loading indicator

    _cancelTimeout(); // Cancel any previous timeout
    final completer = Completer<void>();
    const maxScrollAttempts = 15; // Max attempts *without significant movement* in JS
    const scrollCheckIntervalMs = 800; // How often JS checks its own progress
    const dartCheckIntervalMs = 1500; // How often Dart checks as a backup/watchdog
    const scrollTimeoutSeconds = 60; // Total time allowed for scrolling

    int dartPositionCheckAttempts = 0;
    const maxDartPositionCheckAttempts = 5; // Max times Dart sees no movement before giving up
    double previousPosition = -1; // Initialize to -1 to ensure first check works

    // More robust JS scroll logic: uses requestAnimationFrame for smoother scrolling
    // and checks position change more reliably.
    final scrollScript = '''
        (function() {
            window.__scrollAttempts = 0;
            window.__lastScrollY = -1;
            let continueScrolling = true;
            const maxAttempts = $maxScrollAttempts;
            const checkInterval = $scrollCheckIntervalMs;

            function scrollDown() {
                if (!continueScrolling) return;

                const currentScrollHeight = document.documentElement.scrollHeight;
                window.scrollTo({ top: currentScrollHeight, behavior: 'smooth' });

                // Check position after a delay to allow smooth scroll to progress
                setTimeout(() => {
                    const newScrollY = window.scrollY;
                    const windowHeight = window.innerHeight;
                    const totalHeight = document.documentElement.scrollHeight;

                    // Check if near bottom
                    if (newScrollY + windowHeight >= totalHeight - 50) {
                        console.log('JS Scroll: Reached bottom.');
                        ScrollChannel.postMessage('complete');
                        continueScrolling = false;
                        return;
                    }

                    // Check if scroll position stopped changing
                    if (Math.abs(newScrollY - window.__lastScrollY) < 10) { // Less than 10px change
                        window.__scrollAttempts++;
                        console.log('JS Scroll: Position change small, attempt ' + window.__scrollAttempts);
                    } else {
                        window.__scrollAttempts = 0; // Reset attempts if movement detected
                    }
                    window.__lastScrollY = newScrollY;


                    if (window.__scrollAttempts >= maxAttempts) {
                         console.log('JS Scroll: Max attempts reached without significant movement.');
                         ScrollChannel.postMessage('complete'); // Assume stuck or finished
                         continueScrolling = false;
                         return;
                    }

                    // Continue scrolling if not complete
                    if (continueScrolling) {
                        scrollDown(); // Call next step
                    }

                }, checkInterval); // Wait for scroll to potentially happen and check
            }

            // Start the process
            scrollDown();
        })();
    ''';


    // Setup timeout timer BEFORE starting async operations
    _timeoutTimer = Timer(Duration(seconds: scrollTimeoutSeconds), () {
      debugPrint("Scroll timed out after $scrollTimeoutSeconds seconds!");
      if (!completer.isCompleted) {
        // Complete with error or specific state if needed
        completer.completeError('Scroll timeout');
      }
      // No need to call _failLoading here, the catch block will handle it
    });

    // Add JS Channel
    // Do this *before* running the script that uses it
    try {
      await controller.addJavaScriptChannel(
        'ScrollChannel',
        onMessageReceived: (message) {
          debugPrint("Received message from ScrollChannel: ${message.message}");
          if (message.message == 'complete' && !completer.isCompleted) {
            debugPrint("Completing scroll via ScrollChannel message.");
            _cancelTimeout(); // Success, cancel the timeout timer
            completer.complete();
          }
        },
      );
    } catch (e) {
      _failLoading("Error setting up ScrollChannel: $e");
      _cancelTimeout(); // Ensure timeout is cancelled on setup error
      return; // Cannot proceed without the channel
    }


    try {
      debugPrint("Starting scroll process...");
      await controller.runJavaScript(scrollScript);

      // --- Optional: Dart-side watchdog timer (can be removed if JS is reliable) ---
      // This timer acts as a backup in case the JS channel fails or gets stuck
      final backupTimer = Timer.periodic(Duration(milliseconds: dartCheckIntervalMs), (timer) async {
        if (completer.isCompleted) {
          timer.cancel();
          return;
        }
        try {
          final posResult = await controller.runJavaScriptReturningResult('window.scrollY + window.innerHeight');
          final heightResult = await controller.runJavaScriptReturningResult('document.documentElement.scrollHeight');
          final currentPosition = double.tryParse(posResult?.toString() ?? '0') ?? 0;
          final scrollHeight = double.tryParse(heightResult?.toString() ?? '0') ?? double.maxFinite;

          debugPrint("Dart Watchdog: Pos=$currentPosition, Prev=$previousPosition, Height=$scrollHeight, Attempt=$dartPositionCheckAttempts");

          if (currentPosition >= scrollHeight - 100) { // Check if near bottom
            debugPrint("Dart Watchdog: Reached near bottom.");
            timer.cancel();
            if (!completer.isCompleted) {
              _cancelTimeout();
              completer.complete();
            }
          } else if (currentPosition < previousPosition + 20) { // Minimal movement check
            dartPositionCheckAttempts++;
            if (dartPositionCheckAttempts >= maxDartPositionCheckAttempts) {
              debugPrint("Dart Watchdog: Position stalled, assuming bottom/stuck.");
              timer.cancel();
              if (!completer.isCompleted) {
                _cancelTimeout();
                completer.complete(); // Assume finished even if stalled
              }
            }
          } else {
            previousPosition = currentPosition;
            dartPositionCheckAttempts = 0; // Reset attempts on movement
          }
        } catch (e) {
          debugPrint("Dart Watchdog Error checking position: $e");
          // Decide if you want to stop or continue on error
        }
      });
      // --- End Dart Watchdog ---


      // Wait for the completer (triggered by JS channel, watchdog, or timeout)
      await completer.future;
      backupTimer.cancel(); // Ensure watchdog timer is cancelled

      debugPrint("Scroll process completed or timed out. Proceeding to final steps.");

      // --- Final Scroll Adjustment & Wait ---
      // Even if deemed complete, do one final instant scroll to be sure
      debugPrint("Performing final instant scroll to bottom...");
      await controller.runJavaScript(
          'window.scrollTo({ top: document.documentElement.scrollHeight, behavior: "instant" });'
      );

      // **CRUCIAL DELAY** for rendering after the final scroll
      const renderDelaySeconds = 2;
      debugPrint("Waiting ${renderDelaySeconds}s for final content rendering...");
      await Future.delayed(Duration(seconds: renderDelaySeconds));

      // --- EXTRACTION ---
      // Now call the extraction function
      debugPrint("Calling extraction function...");
      await _extractImages(controller); // Call it HERE, within the try block

    } catch (e, stackTrace) {
      // This catch block now handles errors from scroll, JS channel, timeout, AND _extractImages
      _failLoading("Error during scroll/extraction process: $e\nStackTrace: $stackTrace");
      // _failLoading already sets isLoading = false and cancels timer
    } finally {
      debugPrint("Scroll/Extract sequence finished (finally block).");
      // Clean up JS Channel (important!)
      try {
        await controller.removeJavaScriptChannel('ScrollChannel');
        debugPrint("ScrollChannel removed.");
      } catch (e) {
        debugPrint("Error removing ScrollChannel (might have already been removed or failed setup): $e");
      }
      _cancelTimeout(); // Final check to ensure timer is cancelled

      // Only set loading to false if it hasn't been handled by _failLoading or _extractImages' success path
      // This check might be slightly redundant but safe.
      if (mounted && isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => isLoading = false);
        });
      }
    }
  }
  List<Map<String, String>> newsData = [];
  Future<void> _extractImages(WebViewController controller) async {
    debugPrint("Attempting news data extraction...");

    // Clear previous results ONLY when starting a fresh extraction
    if (mounted) {
      setState(() {
        newsData = [];
      });
    }

    try {
      final jsResult = await controller.runJavaScriptReturningResult(r'''
            (function() {
                const results = [];
                // Using the specific selectors provided
                const cards = document.querySelectorAll('div.wide-story-card.xkXol, div.news_with_item.xkXol, div.left_image_right_news.news_item.wMFhj');
                console.log('Found ' + cards.length + ' potential cards for extraction.'); // Add JS logging

                cards.forEach((card, index) => {
                    // Check for an image with src or srcset within this card
                    const imgElement = card.querySelector('picture.qt-image img[src], picture.qt-image img[srcset]');
                    // Also check the background-image style on the wrapper div as a fallback
                    const wrapperDiv = card.querySelector('div.card-image-wrapper');
                    const hasBgImage = wrapperDiv && wrapperDiv.style.backgroundImage && wrapperDiv.style.backgroundImage !== 'url("/media-placeholder.svg")' && wrapperDiv.style.backgroundImage !== 'none';

                    if (imgElement || hasBgImage) { // Check if EITHER image tag exists OR bg image is set
                        const titleElement = card.querySelector('h3.headline-title span.tilte-no-link-parent');
                        const timestampElement = card.querySelector('time.fw8bp'); // Selects both published-at and published-time

                        if (titleElement && timestampElement) {
                            const titleText = titleElement.textContent?.trim() || '';
                            const timestampText = timestampElement.textContent?.trim() || '';
                             console.log(`Card ${index}: Found Image, Title='${titleText}', Timestamp='${timestampText}'`);
                            results.push({
                                title: titleText,
                                timestamp: timestampText
                            });
                        } else {
                           console.log(`Card ${index}: Found Image but missing title or timestamp.`);
                        }
                    } else {
                        // console.log(`Card ${index}: No valid image found.`); // Optional: log cards skipped
                    }
                });
                return JSON.stringify(results);
            })();
            ''');

      debugPrint("Raw JS Result for news data: $jsResult");

      if (!mounted) return;

      if (jsResult != null) {
        // --- JS Result Processing (Keep as is) ---
        String finalJsonString;
        if (jsResult is String) {
          finalJsonString = jsResult;
          if (finalJsonString.startsWith('"') && finalJsonString.endsWith('"')) {
            try {
              finalJsonString = jsonDecode(finalJsonString);
            } catch (e) {
              finalJsonString = finalJsonString.substring(1, finalJsonString.length - 1)
                  .replaceAll(r'\"', '"')
                  .replaceAll(r"\\'", "'");
            }
          }
          finalJsonString = finalJsonString.replaceAll(r'\"', '"');
        } else if (jsResult is List || jsResult is Map) {
          finalJsonString = jsonEncode(jsResult);
        } else {
          finalJsonString = jsResult.toString();
        }
        // --- End JS Result Processing ---

        try {
          final decodedResult = jsonDecode(finalJsonString);

          if (decodedResult is List) {
            final List<Map<String, String>> extractedData = decodedResult
                .map((item) {
              if (item is Map) {
                return Map<String, String>.fromEntries(
                  item.entries.map(
                        (entry) => MapEntry(entry.key.toString(), entry.value?.toString() ?? ''),
                  ),
                );
              } else {
                debugPrint("Warning: Found non-map item in decoded list: $item");
                return null;
              }
            })
                .where((item) => item != null)
                .cast<Map<String, String>>()
                .toList();

            // *** SUCCESS PATH ***
            if (mounted) {
              setState(() {
                newsData = extractedData;
                isLoading = false; // Stop loading indicator *on success*
              });
            }
            debugPrint("Extraction Complete. Found ${newsData.length} news items with images.");

          } else {
            // Use _failLoading for consistency
            _failLoading("Parsed result from JS is not a List: Type was ${decodedResult.runtimeType}. JSON String was: '$finalJsonString'");
          }
        } catch (e, stackTrace) {
          // Use _failLoading for consistency
          _failLoading("JSON Decoding Error: $e. Processed JS result was: '$finalJsonString'\nStackTrace: $stackTrace");
        }

      } else {
        // Use _failLoading for consistency
        _failLoading("JavaScript execution for extraction returned null.");
      }
    } catch (e, stackTrace) {
      // Use _failLoading for consistency
      _failLoading("Error during JavaScript news data extraction: $e\nStackTrace: $stackTrace");
    }
    // Removed the finally block here - isLoading is handled by success/failure paths above
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Scraper (Single Scroll)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!isLoading) { // Only allow refresh if not currently loading
                _controller.loadRequest(Uri.parse(widget.url));
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Keep WebView visible for debugging
          SizedBox(
              // width: 1,
              // height: 1,
              child: WebViewWidget(controller: _controller)),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          if (!isLoading && imageUrls.isNotEmpty)
            Positioned( // Results overlay
                bottom: 0, left: 0, right: 0, height: 150,
                child: Container(
                    color: Colors.black54,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Tooltip( // Show URL on hover/long-press
                              message: imageUrls[index],
                              child: Image.network(
                                imageUrls[index],
                                width: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.redAccent,),
                              ),
                            )
                        )
                    )
                )
            )
          else if (!isLoading && imageUrls.isEmpty)
            const Positioned(bottom: 10, left: 10, child: Text("No images found", style: TextStyle(backgroundColor: Colors.red, color: Colors.white, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart'; // Import GetX
// import 'package:webview_flutter/webview_flutter.dart';
//
// // Import your controller
// import '../controllers/scrapper_controller.dart';
//
// class ImageScraperView extends StatelessWidget {
//   final String url;
//
//   const ImageScraperView({super.key, required this.url});
//
//   @override
//   Widget build(BuildContext context) {
//     // Instantiate the controller using Get.put()
//     // This makes the controller available to this widget and its children
//     // tag can be useful if you have multiple scrapers
//     final ScraperController controller = Get.put(ScraperController(url: url), tag: url);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Obx(() => Text( // Title can show loading state
//             controller.isLoading.value ? 'Scraping...' : 'Scraper Results (${controller.newsData.length})'
//         )),
//         actions: [
//           // Refresh button - Obx ensures it's disabled while loading
//           Obx(() => IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: "Refresh",
//             // Disable button while loading
//             onPressed: controller.isLoading.value ? null : () => controller.refreshPage(),
//           ))
//         ],
//       ),
//       // Use Obx to reactively rebuild the body based on controller state
//       body: Obx(() {
//         return Column( // Use Column for layout
//           children: [
//             // Optionally hide WebView when not loading/debugging
//             if (controller.isLoading.value) // Show WebView larger while loading/scrolling
//               Expanded(
//                 flex: 1, // Adjust flex as needed
//                 child: WebViewWidget(controller: controller.webViewController),
//               )
//             else // Keep WebView minimal or hidden when results are shown
//               SizedBox(
//                   height: double.infinity, // Minimal height to keep it alive if needed
//                   width: double.infinity,
//                   child: WebViewWidget(controller: controller.webViewController)
//               ),
//
//
//             // --- Loading Indicator ---
//             if (controller.isLoading.value)
//               const Expanded( // Takes space if webview is also expanded
//                   child: Center(child: CircularProgressIndicator())
//               )
//             // --- Results List ---
//             else if (controller.newsData.isNotEmpty)
//               Expanded( // Take remaining space for the list
//                 child: ListView.builder(
//                   itemCount: controller.newsData.length,
//                   itemBuilder: (context, index) {
//                     final item = controller.newsData[index];
//                     final title = item['title'] ?? 'No Title';
//                     final timestamp = item['timestamp'] ?? 'No Timestamp';
//                     // Find a potential image URL within the data for display?
//                     // final imageUrl = item['image'] ?? ''; // If you extracted images too
//
//                     return Card( // Use Card for better visual separation
//                       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       child: ListTile(
//                         title: Text(title),
//                         subtitle: Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
//                         // Optional leading image if extracted:
//                         // leading: imageUrl.isNotEmpty
//                         //          ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported))
//                         //          : null,
//                         dense: true,
//                       ),
//                     );
//                   },
//                 ),
//               )
//             // --- No Results Message ---
//             else // Not loading and list is empty
//               const Expanded(
//                   child: Center(child: Text("No news items found or extraction failed."))
//               )
//           ],
//         );
//       }),
//     );
//   }
// }