import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoriesList extends StatelessWidget {
  final Function getCategories;
  final RxInt selectedCategoryIndex;
  final List imageUrls;
  final List headlines;
  final List timestamps;
  final List links;
  final RxBool isProthomaloCategoricalNewsScrapingComplete;

  const CategoriesList({super.key, required this.getCategories, required this.selectedCategoryIndex, required this.imageUrls, required this.headlines, required this.timestamps, required this.links, required this.isProthomaloCategoricalNewsScrapingComplete});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;

    return FutureBuilder<List<Map<String, dynamic>>>(
        future: getCategories(),
        builder: (context, snapshot) {
          return snapshot.data?.length == 1
              ? SizedBox()
              : SizedBox(
            width: size.width,
            height: appBarHeight * 1.25,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 31.0),
                  child: snapshot.data != null
                      ? Obx(() => Row(
                    spacing: 7,
                    children: [
                      for (int i = 0;
                      i <
                          snapshot.data!
                              .length;
                      i++)
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                    11),
                                color: selectedCategoryIndex
                                    .value ==
                                    i
                                    ? Colors
                                    .white
                                    : Colors
                                    .white12),
                            child: Padding(
                              padding: const EdgeInsets
                                  .symmetric(
                                  vertical:
                                  7.0,
                                  horizontal:
                                  9),
                              child: Text(
                                snapshot.data![
                                i][
                                "categories"],
                                style: TextStyle(
                                    color: selectedCategoryIndex.value == i
                                        ? Colors
                                        .black
                                        : Colors
                                        .white,
                                    height: 0,
                                    fontWeight:
                                    FontWeight
                                        .w700),
                              ),
                            ),
                          ),
                          onTap: () {
                            isProthomaloCategoricalNewsScrapingComplete
                                .value =
                            false;
                            imageUrls.clear();
                            headlines.clear();
                            timestamps
                                .clear();
                            links.clear();
                            selectedCategoryIndex
                                .value = i;
                            print(selectedCategoryIndex
                                .toString());
                          },
                        )
                    ],
                  ))
                      : const SizedBox(),
                ),
              ),
            ),
          );
        });
  }
}
