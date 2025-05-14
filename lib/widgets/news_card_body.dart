import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/news_details.dart';

class NewsCardBody extends StatelessWidget {
  final Function isBasicEnglishIterative;
  final List<Map<String, dynamic>> categories;
  final RxInt selectedCategoryIndex;
  final RxList<String> s;
  final RxBool isProthomaloCategoricalNewsScrapingComplete;
  final List headlines, imageUrls, timestamps, links;
  final Function fetchHeadlines, fetchAllCaategories;

  const NewsCardBody({super.key, required this.isBasicEnglishIterative, required this.categories, required this.selectedCategoryIndex, required this.s, required this.isProthomaloCategoricalNewsScrapingComplete, required this.headlines, required this.imageUrls, required this.timestamps, required this.links, required this.fetchHeadlines, required this.fetchAllCaategories});

  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;

    return Obx(() => Expanded(
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
    ));
  }
}
