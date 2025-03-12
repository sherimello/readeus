import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_icons/line_icons.dart';

class NewsFeedPageTabOptions extends StatelessWidget {
  const NewsFeedPageTabOptions({super.key});

  @override
  Widget build(BuildContext context) {

    RxInt selectedTab = 1.obs;

    double calculateTextWidth(String text, TextStyle style) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout(); // Lays out the text to calculate its size
      return textPainter.size.width; // Returns the width
    }

    return Obx(() => Row(
      children: [
        GestureDetector(
          onTap: () {
            selectedTab.value = 1;
          },
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 355),
              curve: Curves.easeOut,
              width: selectedTab.value == 1
                  ? calculateTextWidth(
                  "  Your feed",
                  TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 0)) +
                  53
                  : 53,
              margin: EdgeInsets.only(left: 21),
              decoration: BoxDecoration(
                  color: selectedTab.value == 1 ? const Color(0xff083d61) : Colors.white,
                  borderRadius: BorderRadius.circular(100)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 7.0, horizontal: 11),
                child: Center(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(
                            LineIcons.pager,
                            color: selectedTab.value == 1 ? Colors.white : Colors.black54,
                            size: 21,
                          ),
                          Text(
                              selectedTab.value == 1
                                  ? "  Your feed"
                                  : "",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 0))
                        ],
                      )),
                ),
              )),
        ),
        GestureDetector(
          onTap: () {
            selectedTab.value = 2;
          },
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 355),
              curve: Curves.easeOut,
              width: selectedTab.value == 2
                  ? calculateTextWidth(
                  "  Open world",
                  TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 0)) +
                  53
                  : 53,
              margin: EdgeInsets.only(left: selectedTab.value == 2 ? 7 : 0),
              decoration: BoxDecoration(
                  color: selectedTab.value == 2 ? const Color(0xff083d61) : Colors.white,
                  borderRadius: BorderRadius.circular(100)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 7.0, horizontal: 11),
                child: Center(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(
                            LineIcons.globe,
                            color: selectedTab.value == 2 ? Colors.white : Colors.black54,
                            size: 21,
                          ),
                          Text(
                              selectedTab.value == 2
                                  ? "  Open world"
                                  : "",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 0))
                        ],
                      )),
                ),
              )),
        ),
        GestureDetector(
          onTap: () {
            selectedTab.value = 3;
          },
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 355),
              curve: Curves.easeOut,
              width: selectedTab.value == 3
                  ? calculateTextWidth(
                  "  Add to list",
                  TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 0)) +
                  53
                  : 53,
              margin: EdgeInsets.only(left: selectedTab.value == 3 ? 7 : 0),
              decoration: BoxDecoration(
                  color: selectedTab.value == 3 ? const Color(0xff083d61) : Colors.white,
                  borderRadius: BorderRadius.circular(100)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 7.0, horizontal: 11),
                child: Center(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(
                            LineIcons.listUl,
                            color: selectedTab.value == 3 ? Colors.white : Colors.black54,
                            size: 21,
                          ),
                          Text(
                              selectedTab.value == 3
                                  ? "  Add to list"
                                  : "",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 0))
                        ],
                      )),
                ),
              )),
        ),
      ],
    ));
  }
}
