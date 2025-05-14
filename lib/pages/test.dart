import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:readeus/pages/news_details.dart';
import 'package:readeus/pages/news_portals.dart';
import 'package:readeus/view%20models/category_view_model.dart';
import 'package:readeus/widgets/categories_list.dart';
import 'package:readeus/widgets/custom_appbar.dart';
import 'package:readeus/widgets/news_card_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../models/news_card.dart';
import '../widgets/prothom_alo_news_scrapper.dart';

part '../utils/constants.dart';

RxList newsData = [].obs;
late WebViewController _controller;
List<String> images = [];
var _titles = [], _timestamps = [];
bool isLoading = true;
RxBool isProthomaloCategoricalNewsScrapingComplete = false.obs,
    isMenuClicked = false.obs;
bool _pageLoadFinished = false; // Track initial page load completion

Timer? _timeoutTimer; // Timer for overall timeout
var headlines = [], links = [], imageUrls = [], timestamps = [];

class Test extends StatelessWidget {
  final hl, lk, iu, ts;

  const Test({super.key, this.hl, this.lk, this.iu, this.ts});

  @override
  Widget build(BuildContext context) {
    resetImageUrls() {
      imageUrls = [];
    }

    clearNewsItems() {
      imageUrls.clear();
      headlines.clear();
      timestamps.clear();
      links.clear();
    }

    addNewsItems(v) {
      headlines.add(v["title"]);
      imageUrls.add(v["image"]);
      timestamps.add(v["timestamp"]);
      links.add(v["link"]);
    }

    // parseNewsCards("htmlString");
    CategoryViewModel categoryViewModel = Get.put(CategoryViewModel());
    Constants constants = Constants();

    RxList<String> s = [""].obs;
    List<Map<String, dynamic>> categories = [
      {"categories": "All"}
    ];

    setAppState() async {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      sharedPreferences.setBool("isFirstTimer", false);
    }

    String _getProthomAloUrl(String banglaCategory) {
      switch (banglaCategory) {
        case "বাংলাদেশ":
          return constants.p_alo_bangladesh;
        case "বাণিজ্য":
          return constants.p_alo_business;
        case "জীবনযাপন":
          return constants.p_alo_lifestyle;
        case "চাকরি":
          return constants.p_alo_chakri;
        case "অপরাধ":
          return constants.p_alo_crime;
        case "খেলা":
          return constants.p_alo_sports;
        case "বিনোদন":
          return constants.p_alo_entertainment;
        case "বিশ্ব":
          return constants.p_alo_world;
        case "মতামত":
          return constants.p_alo_opinion;
        default:
          return constants.p_alo_politices;
      }
    }

    RxBool isBasicEnglishIterative(String? text) {
      if (text == null || text.isEmpty) {
        return true.obs;
      }

      for (final int rune in text.runes) {
        // Check if the rune value is outside the basic ASCII range (0-127)
        if (rune > 127) {
          // Found a non-basic-ASCII character
          return false.obs;
        }
      }

      return true.obs;
    }

    scrapeCnnNews() async {
      final response = await http.get(Uri.parse('https://edition.cnn.com/'));
      final document = dom.Document.html(response.body);

      List<Map<String, String>> newsItems = [];
      const baseUrl = 'https://edition.cnn.com';

      // Find all article containers - adjust selectors based on current page structure
      List<dom.Element> articles = document.querySelectorAll(
        '.container__item, .cd--article, [data-uri*="_article"]',
      );

      for (var article in articles) {
        try {
          // Extract headline
          final headlineElement = article.querySelector(
            '.container__headline, .cd__headline-text, [data-editable="headline"]',
          );
          final headline = headlineElement?.text.trim() ?? '';
          if (headline.isEmpty) continue;

          headlines.add(headline);

          // Extract link
          final linkElement = headlineElement?.parent?.localName == 'a'
              ? headlineElement?.parent
              : article.querySelector('a[href^="/"]');

          String relativeLink = linkElement?.attributes['href']?.trim() ?? '';
          String fullLink = relativeLink.isNotEmpty
              ? baseUrl +
                  (relativeLink.startsWith('/')
                      ? relativeLink
                      : '/$relativeLink')
              : '';

          links.add(fullLink);

          // Extract image URL (check both src and data-src for lazy loading)
          final imgElement = article.querySelector('img');
          String imageUrl = imgElement?.attributes['src'] ??
              imgElement?.attributes['data-src'] ??
              'https://edition.cnn.com/media/sites/cnn/cnn-fallback-image.jpg';
          if (imageUrl.startsWith('data:') || imageUrl.isEmpty)
            imageUrl =
                'https://edition.cnn.com/media/sites/cnn/cnn-fallback-image.jpg';

          imageUrls.add(imageUrl);

          // Extract timestamp
          final timestamp = article
                  .querySelector(
                      '.timestamp, .cd__timestamp, [data-editable="timestamp"]')
                  ?.text
                  .trim() ??
              '';

          timestamps.add(timestamp);
          Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          print('Error parsing article: $e');
        }
      }
    }

    Future<Map<String, List<dynamic>>> scrapeCNNStyle(String section) async {
      try {
        final response =
            await http.get(Uri.parse('https://edition.cnn.com/$section'));
        if (response.statusCode != 200) {
          throw Exception('Failed to load page: ${response.statusCode}');
        }

        final document = dom.Document.html(response.body);
        final localHeadlines = <String>[];
        final localImageUrls = <String>[];
        final localTimestamps = <String>[];
        final localLinks = <String>[];

        // Updated card selector for CNN's common layout patterns
        final articleContainers = document.querySelectorAll('''
      div.card,
      div.container__item,
      article.article
    ''');

        for (var container in articleContainers) {
          // Headline extraction with fallback selectors
          final headlineElement = container.querySelector('''
        h3.cd__headline-text,
        h2.container__headline-text,
        span.container__headline-text,
        .article__title
      ''') ?? container.querySelector('a');

          final headline = headlineElement?.text.trim() ?? 'No headline';

          // Link handling with URL validation
          final linkElement = container.querySelector('a[href]');
          String url = 'https://edition.cnn.com';
          if (linkElement != null) {
            final relativeUrl = linkElement.attributes['href'] ?? '';
            url = Uri.parse('https://edition.cnn.com')
                .resolve(relativeUrl)
                .toString();
          }

          // Image handling with srcset priority and fallback
          String imageUrl =
              'https://edition.cnn.com/media/sites/cnn/cnn-fallback-image.jpg';
          final imgElement = container.querySelector('''
        img.image__container,
        img.media__image,
        img[src]
      ''');

          if (imgElement != null) {
            final srcset = imgElement.attributes['srcset'];
            if (srcset != null) {
              final sources = srcset.split(',').last.trim().split(' ');
              imageUrl = sources.first;
            } else {
              imageUrl = imgElement.attributes['src'] ?? imageUrl;
            }
          }

          // Timestamp extraction with modern selectors
          final timestampElement = container.querySelector('''
        div.timestamp,
        time.article__time,
        .update-time
      ''');
          final timestamp = timestampElement?.text.trim() ?? '';

          localHeadlines.add(headline);
          localLinks.add(url);
          localImageUrls.add(imageUrl);
          localTimestamps.add(timestamp);
        }

        // Remove duplicates while preserving order
        final uniqueIndices = <String>{};
        final filteredData = {
          'headlines': <String>[],
          'images': <String>[],
          'timestamps': <String>[],
          'articleUrls': <String>[],
        };

        for (int i = 0; i < localHeadlines.length; i++) {
          if (!uniqueIndices.contains(localLinks[i])) {
            uniqueIndices.add(localLinks[i]!);
            filteredData['headlines']!.add(localHeadlines[i]);
            filteredData['images']!.add(localImageUrls[i]);
            filteredData['timestamps']!.add(localTimestamps[i]);
            filteredData['articleUrls']!.add(localLinks[i]);
          }
        }

        return filteredData;
      } catch (e) {
        print('Error scraping CNN $section: $e');
        return {
          'headlines': [],
          'images': [],
          'timestamps': [],
          'articleUrls': [],
        };
      }
    }

    Future<Map<String, List<dynamic>>> fetchNewsCategoryData(String s) async {
      if (s == "style" || s == "science" || s == "climate" || s == "weather") {
        final news = await scrapeCNNStyle(s);
        return news;
      } else {
        var cardSelectors = '''
      [data-testid="dundee-card"],
      [data-testid="manchester-card"],
      [data-testid="westminster-card"],
    ''',
            headlineSelector = '''h2[data-testid="card-headline"]''',
            placeholderImage =
                "https://edition.cnn.com/media/sites/cnn/cnn-fallback-image.jpg",
            imageSelector = '''div[data-testid="card-media"]''',
            newsLinkSelector = '''
        a[data-testid="internal-link"],
        a[data-testid="external-anchor"]
      ''';
        var url = 'https://www.bbc.com/';
        if (s == "sport" ||
            s == "innovation" ||
            s == "culture" ||
            s == "arts" ||
            s == "travel" ||
            s == "business") {
          url = "https://www.bbc.com/";
          placeholderImage = "https://www.bbc.com/bbcx/grey-placeholder.png";
        } else {
          url = "https://www.edition.cnn.com/";
          if (s == "ukraine-russia war") s = "world/europe/ukraine";
          if (s == "business-recursion") s = "business";
          if (s != "sport" ||
              s != "innovation" ||
              s != "culture" ||
              s != "arts" ||
              s != "travel" ||
              s != "business") {
            cardSelectors =
                '''div.layout__content-wrapper.layout-no-rail__content-wrapper > section.layout__wrapper.layout-no-rail__wrapper > section.layout__main.layout-no-rail__main > div > section > div > div > div > div > div > div.zone__items.layout--wide-left-balanced-2 > div > div > div > div > div.container_lead-plus-headlines__cards-wrapper > div > div > div''';
            headlineSelector = '''span.container__headline-text''';
            imageSelector = '''div.image__container , img''';
            newsLinkSelector =
                '''div.layout__content-wrapper.layout-no-rail__content-wrapper > section.layout__wrapper.layout-no-rail__wrapper > section.layout__main.layout-no-rail__main > div > section > div > div > div > div > div > div.zone__items.layout--wide-left-balanced-2 > div > div > div > div > div.container_lead-plus-headlines__cards-wrapper > div > div > div > a''';
          }
        }

        // final response =
        // await http.get(Uri.parse("https://www.edition.cnn.com"));
        final response = await http.get(Uri.parse(s == "home" ? url : url + s));
        final headlines = <String>[];
        final images = <String>[];
        final urls = <String>[];
        final timestamps = <String?>[];
        var articleUrls = <String?>[];

        if (response.statusCode == 200) {
          final document = dom.Document.html(response.body);
          final newsCards = document.querySelectorAll(cardSelectors);

          for (final card in newsCards) {
            // Extract headline
            final headlineElement = card.querySelector(headlineSelector);
            headlines.add(headlineElement?.text.trim() ?? 'No headline');

            // Extract timestamp
            final timestampElement = card
                .querySelector('span[data-testid="card-metadata-lastupdated"]');
            timestamps.add(timestampElement?.text.trim() ?? "");

            final linkElement = card.querySelector(newsLinkSelector);
            // div.layout__content-wrapper.layout-no-rail__content-wrapper > section.layout__wrapper.layout-no-rail__wrapper > section.layout__main.layout-no-rail__main > div > section > div > div > div > div > div > div.zone__items.layout--wide-left-balanced-2 > div > div > div > div > div.container_lead-plus-headlines__cards-wrapper > div > div > div > a
            final relativeUrl = linkElement?.attributes['href'];
            articleUrls.add(relativeUrl != null
                ? Uri.parse(url).resolve(relativeUrl).toString()
                : null);

            articleUrls = articleUrls.toSet().toList();

            // Target images within the card-media container
            final mediaContainer = card.querySelector(imageSelector);
            if (mediaContainer != null) {
              final imgs = mediaContainer.querySelectorAll('img');
              for (final img in imgs) {
                // Prioritize srcset for higher quality images
                final srcset = img.attributes['srcset'];
                if (srcset != null) {
                  // Get largest image from srcset (last entry)
                  final parts = srcset.split(',');
                  if (parts.isNotEmpty) {
                    final largest = parts.last.trim().split(' ')[0];
                    urls.add(largest);
                  } else {
                    urls.add("No image URL");
                  }
                } else {
                  // Fallback to src attribute
                  final src = img.attributes['src'];
                  if (src != null && src.isNotEmpty) {
                    urls.add(src);
                  } else {
                    urls.add("No image URL");
                  }
                }
              }
            } else {
              urls.add("value");
            }
          }
        } else {
          throw Exception('Failed to load BBC homepage');
        }

        List<String> filteredUrls = [];

        for (String url in urls) {
          filteredUrls.addIf(
              (url == "value" && url == "/bbcx/grey-placeholder.png") ||
                  !filteredUrls.contains(url) && !url.contains("placeholder"),
              url == "value" ? placeholderImage : url);
        }

        return {
          'headlines': headlines.toSet().toList(),
          'images': filteredUrls,
          'timestamps': timestamps,
          'articleUrls': articleUrls
        };
      }
    }

    Future<Map<String, List<dynamic>>> fetchHeadlinesForCategory(String s) async {
      final url = 'https://www.bbc.com/';
      final response = await http.get(Uri.parse(s == "home" ? url : url + s));
      final headlines = <String>[];
      final urls = <String>[]; // Renamed 'images' to 'urls' for clarity
      final timestamps = <String?>[];
      final articleUrls = <String?>[];

      if (response.statusCode == 200) {
        final document = dom.Document.html(response.body);

        // Target news cards specifically
        final newsCards = document
            .querySelectorAll('li[class*="ListItem"] div[data-testid="promo"]');
        print('Number of news cards: ${newsCards.length}');

        for (final card in newsCards) {
          // Extract headline from <h3> inside the promo
          final h3 = card.querySelector('h3');
          final headlineText = h3?.text.trim() ?? 'No headline';
          headlines.add(headlineText);

          // Extract link from <a> inside the <h3>
          final link = h3?.querySelector('a');
          final relativeUrl = link?.attributes['href'];
          articleUrls.add(relativeUrl != null
              ? Uri.parse('https://www.bbc.com').resolve(relativeUrl).toString()
              : null);

          // Extract image from the promo's media container
          final mediaContainer =
              card.querySelector('div.ssrcss-z60stg-PromoImageContainer');
          if (mediaContainer != null) {
            final img = mediaContainer.querySelector('img');
            final srcset = img?.attributes['srcset'];
            String? imageUrl;

            if (srcset != null && srcset.isNotEmpty) {
              // Get largest image from srcset (last entry)
              final parts = srcset.split(',');
              final largest = parts.last.trim().split(' ')[0];
              imageUrl = largest;
            } else {
              // Fallback to src attribute
              imageUrl = img?.attributes['src'];
            }
            urls.add(imageUrl ?? "No image URL");
          } else {
            urls.add("https://www.bbc.com/bbcx/grey-placeholder.png");
          }

          // Extract timestamp from metadata
          final metadataItem = card.querySelector('li[role="listitem"]');
          String? timestamp;
          if (metadataItem != null) {
            final timeElement =
                metadataItem.querySelector('span[aria-hidden="true"]');
            timestamp = timeElement?.text.trim();
          }
          timestamps.add(timestamp);
        }

        // Print lengths to verify consistency
        print('Found ${headlines.length} headlines, ${urls.length} images, '
            '${timestamps.length} timestamps, ${articleUrls.length} article URLs');

        // Return all lists without filtering
        return {
          'headlines': headlines,
          'images': urls, // Use full urls list, including placeholders
          'timestamps': timestamps,
          'articleUrls': articleUrls
        };
      } else {
        throw Exception('Failed to load BBC homepage');
      }
    }

    Future<List<Map<String, dynamic>>> getCategories() async {
      await setAppState();
      try {
        categories.addAll(await categoryViewModel.fetchCategories());
        for (var v in categories) {
          if (v['categories'] != "Audio" &&
              v['categories'] != "Video" &&
              v['categories'] != "All" &&
              v['categories'] != "Live") {
            s.add(v['categories']);
          }
        }
        if (s.length > 1) {
          s.removeAt(0);
        }
      } catch (e) {
        print(e.toString());
        return [
          {"categories": "Latest"}
        ];
      }
      print(s.toString() + s.length.toString());
      // fetchAllCaategories(["Earth"]);
      // if(s.contains("Business")) {
      //   s.add("business-recursion");
      // }
      return categories;
    }

    Future<Map<String, List<dynamic>>> parseNewsCards(String htmlString) async {
      final response =
          await http.get(Uri.parse("https://edition.cnn.com/business"));
      final document = dom.Document.html(response.body);
      if (response.statusCode != 200) {
        throw Exception('Failed to load page');
      }

      // Document document = parse(response.body);
      List<NewsCard> newsCards = [];

      // Example CNN-specific selectors (adjust based on actual HTML structure)
      List<dom.Element> cards =
          document.querySelectorAll('div.container__item');

      for (var card in cards) {
        final headlineElement =
            card.querySelector('span.container__headline-text');
        final linkElement = card.querySelector('a');
        // final summaryElement = card.querySelector('div.container__description');
        final imageElement = card.querySelector('img');

        String headline = headlineElement?.text.trim() ?? '';
        String link = linkElement?.attributes['href'] ?? '';
        String imageUrl = imageElement?.attributes['src'] ??
            'https://edition.cnn.com/media/sites/cnn/cnn-fallback-image.jpg';

        // Convert relative URLs to absolute
        if (link.isNotEmpty && !link.startsWith('http')) {
          link = Uri.parse("https://edition.cnn.com/").resolve(link).toString();
        }

        headlines.add(headline);
        links.add(link);
        imageUrls.add(imageUrl);
        timestamps.add("");

        newsCards.add(NewsCard(
          headline: headline,
          link: link,
          imageUrl: imageUrl,
        ));
      }

      for (var action in newsCards) {
        log("${action.headline} - ${action.link}\n${action.imageUrl}\n\n");
      }

      return {
        "headlines": headlines,
        "articleUrls": links,
        "images": imageUrls,
        "timestamps": timestamps
      };
    }

    Future<Map<String, List<dynamic>>> fetchAllCaategories(List<String> categories) async {
      isProthomaloCategoricalNewsScrapingComplete.value = false;
      headlines.clear();
      imageUrls.clear();
      links.clear();
      timestamps.clear();

      headlines.removeRange(0, headlines.length);
      imageUrls.removeRange(0, imageUrls.length);
      links.removeRange(0, links.length);
      timestamps.removeRange(0, timestamps.length);

      headlines = [];
      links = [];
      imageUrls = [];
      timestamps = [];

      for (var cat in categories) {
        if (cat == "Sport") {
          Map<String, List<dynamic>> response =
              await fetchHeadlinesForCategory(cat.toLowerCase());
          headlines.addAll(response['headlines']! as List<String>);
          imageUrls.addAll(response['images']! as List<String>);
          timestamps.addAll(response['timestamps']! as List<String?>);
          links.addAll(response['articleUrls']! as List<String?>);
          print(cat + ": " + headlines.length.toString());
        } else if (cat == "Business") {
          print("objecttttttt");
          Map<String, List<dynamic>> response =
              await fetchNewsCategoryData(cat.toLowerCase());
          headlines.addAll(response['headlines']! as List<String>);
          imageUrls.addAll(response['images']! as List<String>);
          timestamps.addAll(response['timestamps']! as List<String?>);
          links.addAll(response['articleUrls']! as List<String?>);
          print("$cat: ${headlines.length}");
          print("objecttttttt");
          await parseNewsCards("htmlString");
        } else {
          Map<String, List<dynamic>> response =
              await fetchNewsCategoryData(cat.toLowerCase());
          headlines.addAll(response['headlines']! as List<String>);
          imageUrls.addAll(response['images']! as List<String>);
          timestamps.addAll(response['timestamps']! as List<String?>);
          links.addAll(response['articleUrls']! as List<String?>);
          print("$cat: ${imageUrls.length}");
        }
      }

      for (int i = 0; i < imageUrls.length; i++) {
        print("${(i + 1).toString()}: ${headlines[i]}");
      }
      // images.forEach((v) => print("jeff: " + v));

      print(headlines.length.toString());
      print(imageUrls.length.toString());

      // await parseNewsCards("htmlString");

      return {
        "headlines": headlines,
        "images": imageUrls,
        "timestamps": timestamps,
        "articleUrls": links,
      };
    }

    Future<Map<String, List<dynamic>>> fetchHeadlines(String s) async {
      isProthomaloCategoricalNewsScrapingComplete.value = false;
      log("----------------------------------------------------------------------------${hl}");
      headlines.clear();
      imageUrls.clear();
      links.clear();
      timestamps.clear();

      headlines.addAll(hl);
      imageUrls.addAll(iu);
      timestamps.addAll(ts);
      links.addAll(lk);

      final url = 'https://www.bbc.com/';
      final response = await http.get(Uri.parse(s == "home" ? url : url + s));
      // final headlines = <String>[];
      // final images = <String>[];
      final urls = <String>[];
      // final timestamps = <String?>[];
      // var articleUrls = <String?>[];

      if (response.statusCode == 200) {
        final document = dom.Document.html(response.body);
        final newsCards = document.querySelectorAll('''
      [data-testid="dundee-card"],
      [data-testid="manchester-card"],
      [data-testid="westminster-card"]
    ''');

        print('Number of news cards: ${newsCards.length}');

        for (final card in newsCards) {
          // Extract headline
          final headlineElement =
              card.querySelector('h2[data-testid="card-headline"]');
          headlines.add(headlineElement?.text.trim() ?? 'No headline');

          // Extract timestamp
          final timestampElement = card
              .querySelector('span[data-testid="card-metadata-lastupdated"]');
          timestamps.add(timestampElement?.text.trim());

          final linkElement = card.querySelector('''
        a[data-testid="internal-link"],
        a[data-testid="external-anchor"]
      ''');
          final relativeUrl = linkElement?.attributes['href'];
          links.add(relativeUrl != null
              ? Uri.parse('https://www.bbc.com').resolve(relativeUrl).toString()
              : null);

          links = links.toSet().toList();

          print('Headline: ${headlines.last}');
          // Target images within the card-media container
          final mediaContainer =
              card.querySelector('div[data-testid="card-media"]');
          if (mediaContainer != null) {
            final imgs = mediaContainer.querySelectorAll('img');
            for (final img in imgs) {
              // Prioritize srcset for higher quality images
              final srcset = img.attributes['srcset'];
              if (srcset != null) {
                // Get largest image from srcset (last entry)
                final parts = srcset.split(',');
                if (parts.isNotEmpty) {
                  final largest = parts.last.trim().split(' ')[0];
                  urls.add(largest);
                } else {
                  urls.add("No image URL");
                }
              } else {
                // Fallback to src attribute
                final src = img.attributes['src'];
                if (src != null && src.isNotEmpty) {
                  urls.add(src);
                } else {
                  urls.add("No image URL");
                }
              }
            }
          } else {
            urls.add("value");
          }
        }
      } else {
        throw Exception('Failed to load BBC homepage');
      }

      print(urls.length);

      List<String> filteredUrls = [];

      for (String url in urls) {
        filteredUrls.addIf(
            (url == "value" && url == "/bbcx/grey-placeholder.png") ||
                !filteredUrls.contains(url) && !url.contains("placeholder"),
            url == "value"
                ? "https://www.bbc.com/bbcx/grey-placeholder.png"
                : url);
      }

      print('Found ${filteredUrls.length} news card images:');
      filteredUrls.forEach((url) => print("News card image: $url"));
      links.forEach((v) => print(v));
      imageUrls.addAll(filteredUrls);

      await scrapeCnnNews();

      return {
        'headlines': headlines.toSet().toList(),
        'images': imageUrls,
        'timestamps': timestamps,
        'articleUrls': links
      };
    }

    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;

    RxInt selectedCategoryIndex = 0.obs;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black,
            actions: [CustomAppbarActions(isMenuClicked: isMenuClicked)],),
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 555),
              curve: Curves.ease,
              child: Stack(
                children: [
                  Obx(() {
                    final category =
                        categories[selectedCategoryIndex.value]["categories"];
                    return !isBasicEnglishIterative(category).value
                        ? ProthomAloNewsScrapper(
                            url: _getProthomAloUrl(category),
                            key: ValueKey(category),
                            resetImageUrl: resetImageUrls,
                            isProthomaloCategoricalNewsScrapingComplete:
                                isProthomaloCategoricalNewsScrapingComplete,
                            clearNewsItems: clearNewsItems,
                            addNewsItems: addNewsItems,
                            imageUrls:
                                imageUrls, // Important for widget recreation
                          )
                        : const SizedBox();
                  }),
                  Container(
                    width: size.width,
                    height: size.height,
                    color: Colors.black,
                    child: Column(
                      children: [
                        CategoriesList(getCategories: getCategories, selectedCategoryIndex: selectedCategoryIndex, imageUrls: imageUrls, headlines: headlines, timestamps: timestamps, links: links, isProthomaloCategoricalNewsScrapingComplete: isProthomaloCategoricalNewsScrapingComplete),
                        Obx(() => Expanded(
                          child: !isBasicEnglishIterative(categories[
                          selectedCategoryIndex.value]
                          ["categories"])
                              .value
                              ? isProthomaloCategoricalNewsScrapingComplete
                              .value
                              ? ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                                31, s.isEmpty ? 31 : 11, 31, 31),
                            itemCount: [
                              headlines.length,
                              imageUrls.length,
                              timestamps.length,
                              links.length
                            ].reduce(min),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (builder) =>
                                              NewsDetails(
                                                imageURL:
                                                imageUrls[
                                                index],
                                                title: headlines[
                                                index],
                                                link:
                                                links[index],
                                                timestamp:
                                                timestamps[
                                                index] ??
                                                    "",
                                              )));
                                  log(links[index]);
                                  // selectedNews.value = index;
                                  // newsCardClicked.value = true;
                                },
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: size.width,
                                      height: size.width * .49,
                                      margin: EdgeInsets.only(
                                          bottom: 11),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                          BorderRadius
                                              .circular(27)),
                                      child: ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(
                                            27),
                                        child: Image.network(
                                          imageUrls[index],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context,
                                              error, stackTrace) {
                                            return Container(
                                              color: Colors
                                                  .grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons
                                                      .broken_image,
                                                  color:
                                                  Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context,
                                              child,
                                              loadingProgress) {
                                            if (loadingProgress ==
                                                null)
                                              return child;
                                            return Container(
                                              color: Colors
                                                  .grey[200],
                                              child: Center(
                                                child:
                                                CircularProgressIndicator(
                                                  value: loadingProgress
                                                      .expectedTotalBytes !=
                                                      null
                                                      ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 11.0),
                                      child: Text(
                                        headlines[index],
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.w700,
                                            fontSize: 19,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                        padding:
                                        const EdgeInsets.only(
                                            left: 10.0,
                                            bottom: 21),
                                        child: timestamps[
                                        index] ==
                                            null ||
                                            timestamps[index]
                                                .toString()
                                                .isEmpty
                                            ? const SizedBox()
                                            : Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius
                                                  .circular(
                                                  7),
                                              color: Colors
                                                  .grey),
                                          child: Padding(
                                            padding:
                                            const EdgeInsets
                                                .all(
                                                3.0),
                                            child: Text(
                                              " ${timestamps[index]} ",
                                              style: TextStyle(
                                                  fontWeight:
                                                  FontWeight
                                                      .w700,
                                                  color: Colors
                                                      .white,
                                                  fontSize:
                                                  12,
                                                  height:
                                                  0),
                                            ),
                                          ),
                                        ))
                                  ],
                                ),
                              );
                            },
                          )
                              : Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                              : FutureBuilder<Map<String, List<dynamic>>>(
                            // future: parseNewsCards("htmlString"),
                            future: selectedCategoryIndex.value == 0
                                ? fetchHeadlines("home")
                            // ? fetchAllCaategories(s)
                                : fetchAllCaategories([
                              s[selectedCategoryIndex.value - 1]
                            ]),
                            // future: fetchHeadlines("home"),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ));
                              }

                              if (snapshot.hasError) {
                                return Center(
                                    child: Text(
                                      'Error: ${snapshot.error}',
                                      style:
                                      TextStyle(color: Colors.white),
                                    ));
                              }

                              if (!snapshot.hasData ||
                                  snapshot
                                      .data!['headlines']!.isEmpty) {
                                return const Center(
                                    child: Text(
                                      'No data found',
                                      style:
                                      TextStyle(color: Colors.white),
                                    ));
                              }

                              final headlines =
                              snapshot.data!['headlines']!;
                              final images =
                              snapshot.data!['images']!;
                              final timestamps =
                              snapshot.data!['timestamps'];
                              final links =
                              snapshot.data!['articleUrls'];

                              return ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                    31, s.isEmpty ? 31 : 11, 31, 31),
                                itemCount: headlines.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (builder) =>
                                                  NewsDetails(
                                                    imageURL:
                                                    images[index],
                                                    title: headlines[
                                                    index],
                                                    link:
                                                    links![index],
                                                    timestamp:
                                                    timestamps[
                                                    index] ??
                                                        "",
                                                  )));
                                      print(links![index]);
                                      // selectedNews.value = index;
                                      // newsCardClicked.value = true;
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: size.width,
                                          height: size.width * .49,
                                          margin: EdgeInsets.only(
                                              bottom: 11),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(27)),
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(
                                                27),
                                            child: Image.network(
                                              images[index],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context,
                                                  error, stackTrace) {
                                                return Container(
                                                  color: Colors
                                                      .grey[200],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image,
                                                      color:
                                                      Colors.grey,
                                                      size: 40,
                                                    ),
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (context,
                                                  child,
                                                  loadingProgress) {
                                                if (loadingProgress ==
                                                    null)
                                                  return child;
                                                return Container(
                                                  color: Colors
                                                      .grey[200],
                                                  child: Center(
                                                    child:
                                                    CircularProgressIndicator(
                                                      value: loadingProgress
                                                          .expectedTotalBytes !=
                                                          null
                                                          ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 11.0),
                                          child: Text(
                                            headlines[index],
                                            style: TextStyle(
                                                fontWeight:
                                                FontWeight.w700,
                                                fontSize: 19,
                                                color: Colors.white),
                                          ),
                                        ),
                                        Padding(
                                            padding:
                                            const EdgeInsets.only(
                                                left: 10.0,
                                                bottom: 21),
                                            child: timestamps![
                                            index] ==
                                                null ||
                                                timestamps[index]
                                                    .toString()
                                                    .isEmpty
                                                ? const SizedBox()
                                                : Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      7),
                                                  color: Colors
                                                      .grey),
                                              child: Padding(
                                                padding:
                                                const EdgeInsets
                                                    .all(
                                                    3.0),
                                                child: Text(
                                                  " ${timestamps[index]} ",
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight
                                                          .w700,
                                                      color: Colors
                                                          .white,
                                                      fontSize:
                                                      12,
                                                      height:
                                                      0),
                                                ),
                                              ),
                                            ))
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ))
                        // NewsCardBody(isBasicEnglishIterative: isBasicEnglishIterative, categories: categories, selectedCategoryIndex: selectedCategoryIndex, s: s, isProthomaloCategoricalNewsScrapingComplete: isProthomaloCategoricalNewsScrapingComplete, headlines: headlines, imageUrls: imageUrls, timestamps: timestamps, links: links, fetchHeadlines: fetchHeadlines, fetchAllCaategories: fetchAllCaategories),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
