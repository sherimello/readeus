import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_icons/line_icons.dart';
import 'package:readeus/widgets/news_feed_page_tab_options.dart';

import '../view models/verse_view_model.dart';

class NewsFeed extends StatelessWidget {
  const NewsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    RxInt selectedTab = 1.obs, selectedNews = 0.obs;
    RxBool newsCardClicked = false.obs;
    Rx<NewsViewModel> newsViewModel = Get.put(NewsViewModel()).obs;

    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;
    var bottomPadding = MediaQuery.of(context).padding.bottom;

    double calculateTextWidth(String text, TextStyle style) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout(); // Lays out the text to calculate its size
      return textPainter.size.width; // Returns the width
    }

    return PopScope(
      onPopInvokedWithResult: (b, d) {
        newsCardClicked.value = false;
      },
      canPop: false,
      child: Obx(() => Material(
        color: Colors.white,
        child: Stack(
          children: [
            Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    titleSpacing: 21,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13.0),
                        child: Icon(
                          LineIcons.bell,
                          opticalSize: 31,
                          size: 31,
                        ),
                      )
                    ],
                    backgroundColor: Colors.white,
                    title: Image.asset(
                      "assets/images/readeus_text.png",
                      height: appBarHeight * .85,
                      width: size.width * .21,
                      fit: BoxFit.contain,
                    ),
                    centerTitle: false,
                  ),
                  body: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(21.0),
                            child: Text(
                              "Hello,\nshahriar rahman",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 31,
                                height: 0,
                                fontFamily: "antipasto.regular",
                              ),
                            ),
                          ),
                          NewsFeedPageTabOptions(),
                          const SizedBox(
                            height: 21,
                          ),
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                // Disable overscroll glow effect
                                return true;
                              },
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(
                                  overscroll: false, // Disable iOS bounce effect
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                  },
                                ),
                              child: ListView.builder(
                                cacheExtent: 9999,
                                  itemCount: newsViewModel.value.newsDataModel.value.image.isNotEmpty
                                      ? newsViewModel.value.newsDataModel.value.image.length
                                      : 0,
                                  padding: EdgeInsets.only(
                                      left: 21, right: 21, bottom: 21, top: 0),
                                  itemBuilder: (context, index) {
                                    String imageUrl = newsViewModel
                                        .value.newsDataModel.value.image[index]
                                        .toString()
                                        .removeAllWhitespace
                                        .replaceAll("{Image:", "")
                                        .replaceAll("}", "");
                                    String title = newsViewModel
                                        .value.newsDataModel.value.title[index]
                                        .toString()
                                        .replaceAll("{Title: ", "")
                                        .replaceAll("}", "");
                                    String category = newsViewModel
                                        .value.newsDataModel.value.category[index]
                                        .toString()
                                        .replaceAll("{Category: ", "")
                                        .replaceAll("}", "");
                                    return GestureDetector(
                                      onTap: () {
                                        selectedNews.value = index;
                                        newsCardClicked.value = true;
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: size.width,
                                            height: size.width * .49,
                                            margin: EdgeInsets.only(bottom: 11),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(27)),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(27),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                loadingBuilder:
                                                    (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: Center(
                                                      child: CircularProgressIndicator(
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 11.0),
                                            child: Text(
                                              title,
                                              style: TextStyle(fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10.0, bottom: 21),
                                            child: Text.rich(TextSpan(children: [
                                              WidgetSpan(
                                                  child: Icon(
                                                    Icons.category,
                                                    color: Colors.grey,
                                                    size: 19,
                                                  ),
                                                  alignment: PlaceholderAlignment.middle),
                                              TextSpan(
                                                text: " $category",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                    height: 0),
                                              )
                                            ])),
                                          )
                                        ],
                                      ),
                                    );
                                  }),
                            ),
                          )
                          )
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: size.width,
                          height: appBarHeight + bottomPadding,
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(Icons.menu_rounded),
                              Icon(CupertinoIcons.person),
                              Icon(CupertinoIcons.bookmark),
                              Icon(CupertinoIcons.search),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 555),
              curve: Curves.easeOut,
              top: newsCardClicked.value ? 0 : -(size.height * .61),
              child: Container(
                width: size.width,
                height: size.height * .61,
                decoration: BoxDecoration(
                    color: Colors.white
                ),
                child: newsViewModel
                    .value.newsDataModel.value.image.isEmpty ?
                const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                ) :
                Image.network(newsViewModel
                    .value.newsDataModel.value.image[selectedNews.value]
                    .toString()
                    .removeAllWhitespace
                    .replaceAll("{Image:", "")
                    .replaceAll("}", ""),
                fit: BoxFit.cover,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 555),
                curve: Curves.easeOut,
                bottom: newsCardClicked.value ? 0 : -(size.height * .55),
                child: Container(width: size.width,
                height: size.height * .55,
            decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.only(topRight: Radius.circular(41), topLeft: Radius.circular(41))),
                  child: Padding(
                    padding: const EdgeInsets.all(37.0),
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 21,
                        children: [
                          Text(newsViewModel
                          .value.newsDataModel.value.title.isEmpty ? "" :
                            newsViewModel
                              .value.newsDataModel.value.title[selectedNews.value]
                              .toString()
                              .replaceAll("{Title: ", "")
                              .replaceAll("}", ""),
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 27,
                            height: 0
                          ),
                          ),
                          Text(newsViewModel
                              .value.newsDataModel.value.summary.isEmpty ? "" :
                            newsViewModel
                              .value.newsDataModel.value.summary[selectedNews.value]
                              .toString()
                              .replaceAll("{Summary: ", "")
                              .replaceAll("}", ""),
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            // fontWeight: FontWeight.w900,
                            // fontSize: 27,
                            height: 0
                          ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ))
          ],
        ),
      )),
    );
  }
}
