import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ProthomAloNewsScrapper extends StatefulWidget {
  final String url;
  final VoidCallback resetImageUrl, clearNewsItems;
  final Function addNewsItems;
  final List imageUrls;
  final RxBool isProthomaloCategoricalNewsScrapingComplete;

  const ProthomAloNewsScrapper({super.key, required this.url, required this.resetImageUrl, required this.isProthomaloCategoricalNewsScrapingComplete, required this.clearNewsItems, required this.addNewsItems, required this.imageUrls});

  @override
  State<ProthomAloNewsScrapper> createState() => _ProthomAloNewsScrapperState();
}

class _ProthomAloNewsScrapperState extends State<ProthomAloNewsScrapper> {
  late WebViewController _controller;

  // List<String> imageUrls = [];
  var _titles = [], _timestamps = [];
  bool isLoading = true;
  bool _pageLoadFinished = false; // Track initial page load completion

  // --- Configuration ---
  final Duration initialWaitDuration =
  const Duration(seconds: 3); // Wait after onPageFinished before scrolling
  final Duration postScrollWaitDuration =
  const Duration(seconds: 8); // Wait after scrolling before extracting
  final Duration finalTimeoutDuration =
  const Duration(seconds: 5); // Overall timeout
  // ---------------------

  Timer? _timeoutTimer; // Timer for overall timeout

  @override
  void initState() {
    super.initState();

    print("+++++++++++++++++++++++++++++++++++++++++++++++++");

    // isProthomaloCategoricalNewsScrapingComplete.value = false;

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
              widget.resetImageUrl();
            });
          },
          onPageFinished: (String url) async {
            debugPrint('Page finished loading: $url');
            // Ensure this runs only once after the initial page load finishes
            // and only if the timeout hasn't already completed the process
            if (!_pageLoadFinished && !(_timeoutTimer?.isActive ?? false)) {
              setState(() {
                _pageLoadFinished = true;
              });
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
      if (mounted && isLoading && !_pageLoadFinished) {
        // Check if still mounted and loading
        debugPrint("Overall Timeout Reached - attempting extraction anyway");
        // Attempt extraction even on timeout, might get some initial images
        _extractImages(_controller); // Don't await here in timeout
        // Or simply fail:
        // _failLoading("Timeout reached before page finished loading");
      } else if (mounted && !_pageLoadFinished) {
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
        // imageUrls = []; // Ensure image list is empty on failure
      });
      _cancelTimeout(); // Stop the timeout if we failed early
    }
  }

  Future<void> _scrollToAbsoluteBottomAndExtract(
      WebViewController controller) async {
    widget.isProthomaloCategoricalNewsScrapingComplete.value = false;
    if (!mounted) return;
    setState(() => isLoading = true); // Start loading indicator

    _cancelTimeout(); // Cancel any previous timeout
    final completer = Completer<void>();
    const maxScrollAttempts =
    15; // Max attempts *without significant movement* in JS
    const scrollCheckIntervalMs = 1800; // How often JS checks its own progress
    const dartCheckIntervalMs =
    1500; // How often Dart checks as a backup/watchdog
    const scrollTimeoutSeconds = 60; // Total time allowed for scrolling

    int dartPositionCheckAttempts = 0;
    const maxDartPositionCheckAttempts =
    5; // Max times Dart sees no movement before giving up
    double previousPosition =
    -1; // Initialize to -1 to ensure first check works

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
      final backupTimer = Timer.periodic(
          Duration(milliseconds: dartCheckIntervalMs), (timer) async {
        if (completer.isCompleted) {
          timer.cancel();
          return;
        }
        try {
          final posResult = await controller.runJavaScriptReturningResult(
              'window.scrollY + window.innerHeight');
          final heightResult = await controller.runJavaScriptReturningResult(
              'document.documentElement.scrollHeight');
          final currentPosition =
              double.tryParse(posResult?.toString() ?? '0') ?? 0;
          final scrollHeight =
              double.tryParse(heightResult?.toString() ?? '0') ??
                  double.maxFinite;

          debugPrint(
              "Dart Watchdog: Pos=$currentPosition, Prev=$previousPosition, Height=$scrollHeight, Attempt=$dartPositionCheckAttempts");

          if (currentPosition >= scrollHeight - 100) {
            // Check if near bottom
            debugPrint("Dart Watchdog: Reached near bottom.");
            timer.cancel();
            if (!completer.isCompleted) {
              _cancelTimeout();
              completer.complete();
            }
          } else if (currentPosition < previousPosition + 20) {
            // Minimal movement check
            dartPositionCheckAttempts++;
            if (dartPositionCheckAttempts >= maxDartPositionCheckAttempts) {
              debugPrint(
                  "Dart Watchdog: Position stalled, assuming bottom/stuck.");
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

      debugPrint(
          "Scroll process completed or timed out. Proceeding to final steps.");

      // --- Final Scroll Adjustment & Wait ---
      // Even if deemed complete, do one final instant scroll to be sure
      debugPrint("Performing final instant scroll to bottom...");
      await controller.runJavaScript(
          'window.scrollTo({ top: document.documentElement.scrollHeight, behavior: "instant" });');

      // **CRUCIAL DELAY** for rendering after the final scroll
      const renderDelaySeconds = 0;
      debugPrint(
          "Waiting ${renderDelaySeconds}s for final content rendering...");
      await Future.delayed(Duration(milliseconds: 1200));

      // --- EXTRACTION ---
      // Now call the extraction function
      debugPrint("Calling extraction function...");
      await _extractImages(controller); // Call it HERE, within the try block
    } catch (e, stackTrace) {
      // This catch block now handles errors from scroll, JS channel, timeout, AND _extractImages
      _failLoading(
          "Error during scroll/extraction process: $e\nStackTrace: $stackTrace");
      // _failLoading already sets isLoading = false and cancels timer
    } finally {
      debugPrint("Scroll/Extract sequence finished (finally block).");
      // Clean up JS Channel (important!)
      try {
        await controller.removeJavaScriptChannel('ScrollChannel');
        debugPrint("ScrollChannel removed.");
      } catch (e) {
        debugPrint(
            "Error removing ScrollChannel (might have already been removed or failed setup): $e");
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
    widget.clearNewsItems();

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
                const currentOrigin = window.location.origin;
                const currentScheme = window.location.protocol;

                // Function to get the best image URL (using placeholder as default)
                function getBestImageUrl(imgElement, wrapperDiv) {
                    // Default to the placeholder URL for this specific site
                    let imageUrl = "https://media.prothomalo.com/prothomalo/import/default/2016/03/15/4d3620a7127d4a031a05a962fcc4b253-palo-logo.jpg";
                    let foundNonPlaceholder = false; // Flag to track if we found a real image

                    if (imgElement) {
                        if (imgElement.srcset) {
                            const sources = imgElement.srcset.split(',')
                                .map(s => s.trim().split(' ')[0])
                                .map(s => s.startsWith('//') ? currentScheme + s : s)
                                .find(s => s && s.startsWith('http'));
                            if (sources) {
                               imageUrl = sources;
                               foundNonPlaceholder = true;
                            }
                        }
                        // Check src only if srcset didn't provide a non-placeholder URL
                        if (!foundNonPlaceholder && imgElement.src) {
                             let srcUrl = null;
                             if (imgElement.src.startsWith('http')) {
                                srcUrl = imgElement.src;
                             } else if (imgElement.src.startsWith('//')) {
                                srcUrl = currentScheme + imgElement.src;
                             }
                             // Avoid data: URIs and ensure it's not the placeholder itself
                             if (srcUrl && !srcUrl.startsWith('data:') && !srcUrl.endsWith('media-placeholder.svg')) {
                                imageUrl = srcUrl;
                                foundNonPlaceholder = true;
                             }
                        }
                    }
                    // Check background only if we haven't found a non-placeholder image yet
                    if (!foundNonPlaceholder && wrapperDiv && wrapperDiv.style.backgroundImage) {
                        const bgUrlMatch = wrapperDiv.style.backgroundImage.match(/url\(['"]?(.+?)['"]?\)/);
                        if (bgUrlMatch && bgUrlMatch[1]) {
                            let bgUrl = bgUrlMatch[1];
                             let absoluteBgUrl = null;
                             if (bgUrl.startsWith('http')) {
                                absoluteBgUrl = bgUrl;
                             } else if (bgUrl.startsWith('//')) {
                                absoluteBgUrl = currentScheme + bgUrl;
                             }
                             // Avoid known placeholders in background
                             if (absoluteBgUrl && !absoluteBgUrl.includes('placeholder') && !absoluteBgUrl.includes('loading') && !absoluteBgUrl.endsWith('media-placeholder.svg')) {
                                imageUrl = absoluteBgUrl;
                                // foundNonPlaceholder = true; // No need to set flag here, it's the last check
                             }
                        }
                    }
                    // Return the found URL or the initial placeholder
                    return imageUrl;
                }

                // --- Target Selectors (ADJUST THESE FOR THE SPECIFIC WEBSITE) ---
                const cardSelectors = [
                    'div.wide-story-card.xkXol',
                    'div.news_with_item.xkXol',
                    'div.left_image_right_news.news_item.wMFhj',
                    // Add more potential card selectors if needed
                ];
                const cards = document.querySelectorAll(cardSelectors.join(', '));
                console.log('JS Extract: Found ' + cards.length + ' potential cards using selectors: ' + cardSelectors.join(', '));

                // --- MODIFIED Main Extraction Loop ---
                cards.forEach((card, index) => {
                    // --- Try to find elements within this card ---
                    const imgElement = card.querySelector('picture.qt-image img[src], picture.qt-image img[srcset]');
                    const wrapperDiv = card.querySelector('div.card-image-wrapper');
                    const titleElement = card.querySelector('h3.headline-title span.tilte-no-link-parent, h2 a, h3 a');
                    const timestampElement = card.querySelector('time.fw8bp, span.time-ago');
                    // --- Find the main link element for the card ---
                    // Prioritize link around headline, then first link in card
                    const linkElement = titleElement?.closest('a[href]') ?? card.querySelector('a[href]');


                    // --- Extract data, allowing for missing parts ---
                    const imageUrl = getBestImageUrl(imgElement, wrapperDiv); // Get image (URL string or placeholder)
                    const titleText = titleElement?.textContent?.trim() || '';
                    const timestampText = timestampElement?.textContent?.trim() || '';
                    // --- Extract the absolute link URL ---
                    // '.href' on an anchor element usually returns the absolute URL
                    const linkUrl = linkElement?.href || ''; // Get the absolute href, default to empty string if no link or element


                    // --- ALWAYS add an entry to the results array ---
                    // Include the extracted link URL
                    results.push({
                        title: titleText,
                        timestamp: timestampText,
                        image: imageUrl,
                        link: linkUrl // Add the link URL here
                    });

                    // Optional: Log whether an image and link were found for this specific card
                    const isPlaceholder = imageUrl === "https://www.prothomalo.com/media-placeholder.svg";
                    console.log(`JS Card ${index}: Added entry. ` +
                                `Image ${isPlaceholder ? 'is placeholder' : 'found'}, `+
                                `Title='${titleText}', ` +
                                `Link ${linkUrl ? 'found' : 'NOT found'} ('${linkUrl}')`);

                });

                console.log('JS Extract: Processed ' + cards.length + ' cards. Returning ' + results.length + ' items.');
                // Return the results array, which now includes the 'link' property
                return JSON.stringify(results);
            })();
            ''');

      // debugPrint("Raw JS Result for news data: $jsResult");

      if (!mounted) return;

      if (jsResult != null) {
        // --- JS Result Processing (Keep as is) ---
        String finalJsonString;
        if (jsResult is String) {
          finalJsonString = jsResult;
          if (finalJsonString.startsWith('"') &&
              finalJsonString.endsWith('"')) {
            try {
              finalJsonString = jsonDecode(finalJsonString);
            } catch (e) {
              finalJsonString = finalJsonString
                  .substring(1, finalJsonString.length - 1)
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

          decodedResult.forEach((v) {
            widget.addNewsItems(v);
          });
          // imageUrls = decodedResult[""]

          log(decodedResult.toString());

          if (decodedResult is List) {
            final List<Map<String, String>> extractedData = decodedResult
                .map((item) {
              if (item is Map) {
                return Map<String, String>.fromEntries(
                  item.entries.map(
                        (entry) => MapEntry(entry.key.toString(),
                        entry.value?.toString() ?? ''),
                  ),
                );
              } else {
                debugPrint(
                    "Warning: Found non-map item in decoded list: $item");
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
                // log(imageUrls.length.toString());
                // log(headlines.toSet().toList().length.toString());
                // log(timestamps.length.toString());
                // log(links.length.toString());
              });
            }
            debugPrint(
                "Extraction Complete. Found ${newsData.length} news items with images.");
            widget.isProthomaloCategoricalNewsScrapingComplete.value = true;
          } else {
            // Use _failLoading for consistency
            _failLoading(
                "Parsed result from JS is not a List: Type was ${decodedResult.runtimeType}. JSON String was: '$finalJsonString'");
          }
        } catch (e, stackTrace) {
          // Use _failLoading for consistency
          _failLoading(
              "JSON Decoding Error: $e. Processed JS result was: '$finalJsonString'\nStackTrace: $stackTrace");
        }
      } else {
        // Use _failLoading for consistency
        _failLoading("JavaScript execution for extraction returned null.");
      }
    } catch (e, stackTrace) {
      // Use _failLoading for consistency
      _failLoading(
          "Error during JavaScript news data extraction: $e\nStackTrace: $stackTrace");
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
              if (!isLoading) {
                // Only allow refresh if not currently loading
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
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (!isLoading && widget.imageUrls.isNotEmpty)
            Positioned(
              // Results overlay
                bottom: 0,
                left: 0,
                right: 0,
                height: 150,
                child: Container(
                    color: Colors.black54,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.imageUrls.length,
                        itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Tooltip(
                              // Show URL on hover/long-press
                              message: widget.imageUrls[index],
                              child: Image.network(
                                widget.imageUrls[index],
                                width: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.redAccent,
                                ),
                              ),
                            )))))
          else if (!isLoading && widget.imageUrls.isEmpty)
            const Positioned(
                bottom: 10,
                left: 10,
                child: Text("No images found",
                    style: TextStyle(
                        backgroundColor: Colors.red,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }
}