import 'dart:async';
import 'dart:convert';
import 'dart:developer'; // Use log instead of debugPrint for better traceability potentially
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ScraperController extends GetxController {
  final String url; // URL passed to the controller

  ScraperController({required this.url}); // Constructor to receive URL

  // --- State Variables (Reactive) ---
  var isLoading = true.obs;
  var newsData = <Map<String, String>>[].obs;

  // --- Internal Variables ---
  late WebViewController webViewController;
  Timer? _scrollTimeoutTimer;
  bool _pageLoadFinished = false;

  // --- Configuration (Constants can be moved outside if preferred) ---
  static const scrollTimeoutSeconds = 60;
  static const renderDelaySeconds = 3; // Adjusted delay
  static const maxScrollAttempts = 15;
  static const scrollCheckIntervalMs = 800;
  static const dartCheckIntervalMs = 1500;
  static const maxDartPositionCheckAttempts = 5;

  @override
  void onInit() {
    super.onInit();
    _initializeWebView();
    log('ScraperController initialized for URL: $url');
  }

  @override
  void onClose() {
    log('ScraperController closing...');
    _cancelScrollTimeout();
    // Attempt to remove channel cleanly, errors are expected if already removed/failed
    try {
      webViewController
          .removeJavaScriptChannel('ScrollChannel')
          .catchError((e) => log("Error removing ScrollChannel on close: $e"));
    } catch (e) {
      log("Exception removing ScrollChannel on close: $e");
    }
    super.onClose();
  }

  void _initializeWebView() {
    isLoading(true); // Start loading state
    newsData.clear(); // Clear previous data
    _pageLoadFinished = false;

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Optional: Update progress state if needed in UI
            // log('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            log('Page started loading: $url');
            // Reset internal flags on navigation/reload
            isLoading(true); // Show loading indicator on navigation start
            _pageLoadFinished = false;
            newsData.clear();
            _cancelScrollTimeout();
          },
          onPageFinished: (String url) async {
            log('Page finished loading: $url');
            // Trigger scroll/extract only once after the primary page load
            if (!_pageLoadFinished) {
              _pageLoadFinished = true;
              // Start the process
              await _scrollToAbsoluteBottomAndExtract();
            }
          },
          onWebResourceError: (WebResourceError error) {
            log('''Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}''',
                level: 2000); // Log as severe
            _failLoading("Web resource error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) {
            // Decide which navigations to allow (e.g., block ads, popups)
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url)); // Load the URL passed to the controller

    // Enable debugging only in debug mode for security
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      AndroidWebViewController.enableDebugging(true);
    }
  }

  void _cancelScrollTimeout() {
    _scrollTimeoutTimer?.cancel();
    _scrollTimeoutTimer = null;
  }

  void _failLoading(String message) {
    log("Scraping failed: $message", level: 1000); // Log as warning/error
    isLoading(false);
    newsData.clear(); // Clear data on failure
    _cancelScrollTimeout(); // Ensure timeout is stopped
  }

  // --- Main Logic Methods ---

  Future<void> refreshPage() async {
    if (!isLoading.value) { // Only refresh if not already loading
      log("Attempting to refresh page...");
      // Reset state and reload
      isLoading(true);
      newsData.clear();
      _pageLoadFinished = false;
      _cancelScrollTimeout();
      try {
        await webViewController.loadRequest(Uri.parse(url));
        // _initializeWebView(); // Or re-initialize completely
      } catch (e) {
        _failLoading("Error during refresh loadRequest: $e");
      }
    } else {
      log("Refresh requested while already loading.");
    }
  }


  Future<void> _scrollToAbsoluteBottomAndExtract() async {
    // Ensure controller is still alive (GetX manages this implicitly, but good practice)
    if (isClosed) return;

    log("Starting scroll and extract process...");
    isLoading(true); // Ensure loading state is active

    _cancelScrollTimeout();
    final completer = Completer<void>();

    int dartPositionCheckAttempts = 0;
    double previousPosition = -1;

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
                setTimeout(() => {
                    const newScrollY = window.scrollY;
                    const windowHeight = window.innerHeight;
                    const totalHeight = document.documentElement.scrollHeight;
                    if (newScrollY + windowHeight >= totalHeight - 50) {
                        console.log('JS Scroll: Reached bottom.');
                        ScrollChannel.postMessage('complete');
                        continueScrolling = false; return;
                    }
                    if (Math.abs(newScrollY - window.__lastScrollY) < 10) {
                        window.__scrollAttempts++;
                        console.log('JS Scroll: Position change small, attempt ' + window.__scrollAttempts);
                    } else {
                        window.__scrollAttempts = 0;
                    }
                    window.__lastScrollY = newScrollY;
                    if (window.__scrollAttempts >= maxAttempts) {
                         console.log('JS Scroll: Max attempts reached.');
                         ScrollChannel.postMessage('complete');
                         continueScrolling = false; return;
                    }
                    if (continueScrolling) { scrollDown(); }
                }, checkInterval);
            }
            scrollDown();
        })();
    ''';

    _scrollTimeoutTimer = Timer(Duration(seconds: scrollTimeoutSeconds), () {
      log("Scroll timed out!", level: 1000);
      if (!completer.isCompleted) {
        completer.completeError('Scroll timeout');
      }
    });

    try {
      // Remove existing channel first to prevent errors if run multiple times
      try { await webViewController.removeJavaScriptChannel('ScrollChannel'); } catch (_) {}
      // Add the channel
      await webViewController.addJavaScriptChannel(
        'ScrollChannel',
        onMessageReceived: (message) {
          log("ScrollChannel message: ${message.message}");
          if (message.message == 'complete' && !completer.isCompleted) {
            log("Completing scroll via ScrollChannel.");
            _cancelScrollTimeout();
            completer.complete();
          }
        },
      );
    } catch (e) {
      _failLoading("Error setting up ScrollChannel: $e");
      _cancelScrollTimeout();
      return;
    }

    try {
      log("Executing scroll script...");
      await webViewController.runJavaScript(scrollScript);

      // Dart watchdog timer remains useful
      final backupTimer = Timer.periodic(Duration(milliseconds: dartCheckIntervalMs), (timer) async {
        if (isClosed || completer.isCompleted) { timer.cancel(); return; }
        try {
          final posResult = await webViewController.runJavaScriptReturningResult('window.scrollY + window.innerHeight');
          final heightResult = await webViewController.runJavaScriptReturningResult('document.documentElement.scrollHeight');
          final currentPosition = double.tryParse(posResult?.toString() ?? '0') ?? 0;
          final scrollHeight = double.tryParse(heightResult?.toString() ?? '0') ?? double.maxFinite;
          log("Dart Watchdog: Pos=$currentPosition, Prev=$previousPosition, Height=$scrollHeight, Attempt=$dartPositionCheckAttempts");
          if (currentPosition >= scrollHeight - 100) {
            log("Dart Watchdog: Reached near bottom.");
            timer.cancel(); if (!completer.isCompleted) { _cancelScrollTimeout(); completer.complete(); }
          } else if (currentPosition < previousPosition + 20) {
            dartPositionCheckAttempts++;
            if (dartPositionCheckAttempts >= maxDartPositionCheckAttempts) {
              log("Dart Watchdog: Position stalled.");
              timer.cancel(); if (!completer.isCompleted) { _cancelScrollTimeout(); completer.complete(); }
            }
          } else {
            previousPosition = currentPosition; dartPositionCheckAttempts = 0;
          }
        } catch (e) { log("Dart Watchdog Error: $e"); }
      });

      await completer.future; // Wait for completion or timeout
      backupTimer.cancel();
      log("Scroll process finished.");

      log("Performing final instant scroll...");
      await webViewController.runJavaScript('window.scrollTo({ top: document.documentElement.scrollHeight, behavior: "instant" });');

      log("Waiting ${renderDelaySeconds}s for render...");
      await Future.delayed(Duration(seconds: renderDelaySeconds));

      log("Calling extraction...");
      await _extractImages();

    } catch (e, stackTrace) {
      _failLoading("Scroll/Extraction Error: $e\nStackTrace: $stackTrace");
    } finally {
      log("Scroll/Extract sequence finished (finally).");
      _cancelScrollTimeout(); // Ensure timer cancelled
      try {
        if(!isClosed) await webViewController.removeJavaScriptChannel('ScrollChannel');
        log("ScrollChannel removed.");
      } catch (e) { log("Error removing ScrollChannel finally: $e"); }

      // Final state check - isLoading should be false if successful extraction happened
      // If it's still true here, something went wrong before _failLoading or success path ran.
      if (isLoading.value && !isClosed) {
        log("isLoading still true in finally, forcing false.", level: 1000);
        isLoading(false);
      }
    }
  }


  Future<void> _extractImages() async {
    if (isClosed) return;

    log("Attempting news data extraction (including images)...");
    newsData.clear(); // Clear results before extraction

    try {
      // *** UPDATED JAVASCRIPT ***
      final jsResult = await webViewController.runJavaScriptReturningResult(r'''
            (function() {
                const results = [];
                const currentOrigin = window.location.origin; // e.g., "https://www.prothomalo.com"
                const currentScheme = window.location.protocol; // e.g., "https:"

                // Function to get the best image URL from an element
                function getBestImageUrl(imgElement, wrapperDiv) {
                    let imageUrl = null;

                    if (imgElement) {
                        // 1. Check srcset
                        if (imgElement.srcset) {
                            const sources = imgElement.srcset.split(',')
                                .map(s => s.trim().split(' ')[0]) // Get URL part
                                .find(s => s && s.startsWith('http')); // Find first http(s) URL
                            if (sources) {
                                imageUrl = sources;
                            }
                            // If no full URL in srcset, try for protocol-relative
                            if (!imageUrl) {
                                const relativeSource = imgElement.srcset.split(',')
                                    .map(s => s.trim().split(' ')[0])
                                    .find(s => s && s.startsWith('//'));
                                if (relativeSource) {
                                     imageUrl = currentScheme + relativeSource; // Add protocol
                                }
                            }
                        }

                        // 2. Check src (if srcset didn't yield a result)
                        if (!imageUrl && imgElement.src) {
                             if (imgElement.src.startsWith('http')) {
                                imageUrl = imgElement.src;
                             } else if (imgElement.src.startsWith('//')) {
                                imageUrl = currentScheme + imgElement.src; // Add protocol
                             } else if (imgElement.src.startsWith('/')) {
                                // Handle root-relative paths (less common for primary images, but possible)
                                // imageUrl = currentOrigin + imgElement.src;
                                // Ignore root-relative for now unless specifically needed
                             }
                             // Ignore data URLs or other protocols for now
                        }
                    }

                     // 3. Check background-image on wrapper (if still no URL)
                    if (!imageUrl && wrapperDiv && wrapperDiv.style.backgroundImage) {
                        const bgUrlMatch = wrapperDiv.style.backgroundImage.match(/url\(['"]?(.+?)['"]?\)/);
                        if (bgUrlMatch && bgUrlMatch[1]) {
                            let bgUrl = bgUrlMatch[1];
                             if (bgUrl.startsWith('http')) {
                                imageUrl = bgUrl;
                             } else if (bgUrl.startsWith('//')) {
                                imageUrl = currentScheme + bgUrl; // Add protocol
                             } else if (bgUrl.startsWith('/') && bgUrl !== '/media-placeholder.svg') {
                                // Handle root-relative, avoid placeholders
                                // imageUrl = currentOrigin + bgUrl;
                                // Ignoring root-relative for simplicity here
                             }
                        }
                    }

                    // Return the best URL found, or null
                    return imageUrl;
                }

                // --- Main Extraction Loop ---
                const cards = document.querySelectorAll('div.wide-story-card.xkXol, div.news_with_item.xkXol, div.left_image_right_news.news_item.wMFhj');
                console.log('JS: Found ' + cards.length + ' potential cards.');

                cards.forEach((card, index) => {
                    const imgElement = card.querySelector('picture.qt-image img[src], picture.qt-image img[srcset]');
                    const wrapperDiv = card.querySelector('div.card-image-wrapper'); // Used for background image fallback

                    // Get the best image URL using the helper function
                    const imageUrl = getBestImageUrl(imgElement, wrapperDiv);

                    if (imageUrl) { // Proceed only if we found a valid image URL
                        const titleElement = card.querySelector('h3.headline-title span.tilte-no-link-parent');
                        const timestampElement = card.querySelector('time.fw8bp');

                        if (titleElement && timestampElement) {
                            const titleText = titleElement.textContent?.trim() || '';
                            const timestampText = timestampElement.textContent?.trim() || '';
                            console.log(`JS Card ${index}: Found Image='${imageUrl}', Title='${titleText}', Timestamp='${timestampText}'`);
                            // *** Add imageUrl to the result object ***
                            results.push({
                                title: titleText,
                                timestamp: timestampText,
                                image: imageUrl // Add the image URL here
                            });
                        } else {
                           console.log(`JS Card ${index}: Found Image='${imageUrl}' but missing title (${!!titleElement}) or timestamp (${!!timestampElement}). Skipping.`);
                        }
                    } else {
                         console.log(`JS Card ${index}: No valid image URL found. Skipping.`);
                    }
                });
                console.log('JS: Returning ' + results.length + ' items with image, title, and timestamp.');
                return JSON.stringify(results);
            })();
            ''');

      log("Raw JS Result for news data: $jsResult");

      // --- Dart Parsing Logic (should handle the new 'image' key automatically) ---
      if (jsResult != null) {
        // ... (existing JS result processing to get finalJsonString) ...
        String finalJsonString;
        if (jsResult is String) {
          finalJsonString = jsResult;
          if (finalJsonString.startsWith('"') && finalJsonString.endsWith('"')) {
            try { finalJsonString = jsonDecode(finalJsonString); }
            catch (e) { finalJsonString = finalJsonString.substring(1, finalJsonString.length - 1).replaceAll(r'\"', '"').replaceAll(r"\\'", "'"); }
          }
          finalJsonString = finalJsonString.replaceAll(r'\"', '"');
        } else { finalJsonString = jsonEncode(jsResult); }


        try {
          final decodedResult = jsonDecode(finalJsonString);
          if (decodedResult is List) {
            // The existing mapping handles the new key automatically
            final List<Map<String, String>> extractedData = decodedResult.map((item) {
              if (item is Map) {
                // Ensure all values are strings, including the new 'image'
                return Map<String, String>.fromEntries(
                  item.entries.map((entry) => MapEntry(entry.key.toString(), entry.value?.toString() ?? '')),
                );
              } return null;
            }).whereType<Map<String, String>>().toList();

            // --- SUCCESS ---
            newsData.assignAll(extractedData);
            isLoading(false);
            log("Extraction Complete. Found ${newsData.length} news items (with images).");
            // You can log the data including images here if needed:
            // newsData.forEach((item) => log("Item: ${item['title']} - ${item['image']}"));
          } else {
            _failLoading("Parsed JS result not a List: Type was ${decodedResult.runtimeType}. JSON: '$finalJsonString'");
          }
        } catch (e, stackTrace) {
          _failLoading("JSON Decode Error: $e. JSON: '$finalJsonString'\nStackTrace: $stackTrace");
        }
      } else {
        _failLoading("JS execution for extraction returned null.");
      }
    } catch (e, stackTrace) {
      _failLoading("JS Extraction Error: $e\nStackTrace: $stackTrace");
    }
  }

// ... rest of the ScraperController ...
}