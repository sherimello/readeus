import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/news_portals.dart';

class CustomAppbarActions extends StatelessWidget {
  final RxBool isMenuClicked;

  const CustomAppbarActions({super.key, required this.isMenuClicked});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    return SizedBox(
      width: size.width,
      height: appBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 31.0),
            child: GestureDetector(
              onTap: () {
                isMenuClicked.value = true;
                if (isMenuClicked.value) {
                  Get.bottomSheet(
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      width: size.width,
                      height: size.width * .55,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(55),
                              topRight: Radius.circular(55)),
                          color: const Color(0xff272727)),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 11,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Get.to(() => NewsPortals());
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.room_preferences_outlined,
                                      color: Colors.blueAccent,
                                      size: size.width * .065,
                                    ),
                                    Text(
                                      " Change Preference(s)",
                                      style: TextStyle(
                                          fontSize: size.width * .045,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                    )
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    color: Colors.blueAccent,
                                    size: size.width * .065,
                                  ),
                                  Text(
                                    " All Bookmark(s)",
                                    style: TextStyle(
                                        fontSize: size.width * .045,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.favorite_border_rounded,
                                    color: Colors.blueAccent,
                                    size: size.width * .065,
                                  ),
                                  Text(
                                    " All Favorite(s)",
                                    style: TextStyle(
                                        fontSize: size.width * .045,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Icon(
                Icons.menu_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Image.asset(
            "assets/images/readeus_text.png",
            width: size.width * .25,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 31.0),
            child: Icon(
              CupertinoIcons.person_solid,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
