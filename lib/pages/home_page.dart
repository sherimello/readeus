import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:readeus/view%20models/verse_view_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Rx<NewsViewModel> newsViewModel = Get.put(NewsViewModel()).obs;

    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;
    var bottomPadding = MediaQuery.of(context).padding.bottom;

    RxInt currentTabIndex = 0.obs;

    return Obx(() => Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.asset("assets/images/readeus_text.png",
          height: appBarHeight * .85,
          width: size.width * .21,
          fit: BoxFit.contain,),
        centerTitle: true,
      ),
          body: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(color: Colors.black
                // gradient: LinearGradient(
                //     colors: [const Color(0xff6DB0F6), const Color(0xffD3E6F2)],
                //     begin: Alignment.bottomRight,
                //     end: Alignment.topLeft),
                ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 0, left: 11, right: 11),
                      child: SizedBox(
                        width: size.width,
                        height: appBarHeight,
                        child: Center(
                          child: Stack(
                            children: [
                              GNav(
                                  rippleColor: Colors.grey[800]!, // tab button ripple color when pressed
                                  hoverColor: Colors.grey[700]!, // tab button hover color
                                  haptic: true, // haptic feedback
                                  tabBorderRadius: 15,
                                  tabActiveBorder: Border.all(color: Color(0xff083d61), width: 1), // tab button border
                                  tabBorder: Border.all(color: Colors.black, width: 1), // tab button border
                                  // tabShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 8)], // tab button shadow
                                  curve: Curves.easeOutExpo, // tab animation curves
                                  duration: Duration(milliseconds: 900), // tab animation duration
                                  gap: 8, // the tab button gap between icon and text
                                  color: Colors.white, // unselected icon color
                                  activeColor: Colors.white, // selected icon and text color
                                  iconSize: 24, // tab button icon size
                                  tabBackgroundColor: Colors.white, // selected tab background color
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), // navigation bar padding
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  tabs: [
                                    GButton(
                                      icon: LineIcons.pager,
                                      text: 'Your feed',
                                      backgroundColor: const Color(0xff083d61),
                                    ),
                                    GButton(
                                      icon: LineIcons.globe,
                                      text: 'Open world',
                                      backgroundColor: const Color(0xff083d61),
                                    ),
                                    GButton(
                                      icon: LineIcons.list,
                                      text: 'Add to list',
                                      backgroundColor: const Color(0xff083d61),
                                    ),
                                    // GButton(
                                    //   icon: LineIcons.user,
                                    //   text: 'Profile',
                                    // )
                                  ]
                              )







                              // AnimatedPositioned(
                              //     bottom: 0,
                              //     left: currentTabIndex.value == 0
                              //         ? (size.width / 3) * .5 -
                              //             (size.width * .025 * .5)
                              //         : currentTabIndex.value == 1
                              //             ? ((size.width / 3) * .5) * 3 -
                              //                 (size.width * .025 * .5)
                              //             : ((size.width / 3) * .5) * 5 -
                              //                 (size.width * .025 * .5),
                              //     curve: Curves.easeOut,
                              //     duration: const Duration(milliseconds: 355),
                              //     child: Container(
                              //       width: size.width * .025,
                              //       height: size.width * .025,
                              //       decoration: BoxDecoration(
                              //           color: Colors.white,
                              //           borderRadius:
                              //               BorderRadius.circular(1000)),
                              //     ))
                            ],
                          ),
                        ),
                      ),
                    ),
                    // const SizedBox(
                    //   height: 19,
                    // ),
                    // // ... rest of your imports and code

                    Expanded(
                      child: ListView.builder(
                        itemCount: newsViewModel
                            .value.newsDataModel.value.image.length,
                        itemBuilder: (context, index) {
                          String imageUrl = newsViewModel
                              .value.newsDataModel.value.image[index]
                              .toString()
                              .removeAllWhitespace
                              .replaceAll("{Image:", "")
                              .replaceAll("}", "");

                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index ==
                                        newsViewModel.value.newsDataModel.value
                                                .image.length -
                                            1
                                    ? appBarHeight + bottomPadding + 5.5
                                    : 0,
                            top: index == 0 ? 5.5 : 0,
                            left: 5.5, right: 5.5),
                            child: Container(
                              width: size.width,
                              height: appBarHeight * 3,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 5.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(39),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(39),
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
                          );
                        },
                        padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
                      ),
                    )
                  ],
                ),
                IgnorePointer(
                  child: Container(
                    width: size.width,
                    height: size.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.black, Colors.black38, Colors.transparent, Colors.transparent],begin: Alignment.bottomCenter, end: Alignment.topCenter)
                    ),
                  ),
                ),
                Positioned(
                  bottom: bottomPadding + 11,
                  left: 35,
                  right: 35,
                  child: Container(
                    width: size.width,
                    height: appBarHeight,
                    decoration: BoxDecoration(
                        color: const Color(0xff083D61),
                        borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                            onTap: () => Get.bottomSheet(
                                  Column(
                                    children: [],
                                  ),
                                ),
                            child: Icon(
                              Icons.menu,
                              color: Colors.white,
                            )),
                        Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                        Image.asset(
                          "assets/images/icon.png",
                          width: size.width * .087,
                          height: size.width * .087,
                        ),
                        Icon(
                          Icons.bookmark_border,
                          color: Colors.white,
                        ),
                        Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
