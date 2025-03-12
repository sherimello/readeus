import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/all_topics_page.dart';

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;

    final double radius = size.width / 2; // radius of the outer container
    final double smallContainerSize = size.width * .25; // size of the inner rounded containers
    final double bigContainerSize = size.width * .29; // size of the inner rounded containers
    final double padding = 5; // padding for each inner container

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [const Color(0xff6DB0F6), const Color(0xffD3E6F2)],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size.width,
              height: size.width,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1000),
                  gradient: LinearGradient(
                      colors: [const Color(0xff50A8E7), const Color(0xff95D0FA)],
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white54, // Shadow color with transparency
                      spreadRadius: 11, // How much the shadow spreads
                      blurRadius: 21, // Blur effect
                      offset: Offset(2, 7), // Horizontal and vertical offset
                    ),
                  ]
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Stack(
                    children: List.generate(6, (index) {
                      // Calculate the angle for each inner container
                      // double angle = (2 * pi / 6) * index;
                      double angle = (2 * pi / 6) * index - pi / 2;
                      double x = index.isOdd ?
                      radius + (radius - smallContainerSize / 2 - padding) * cos(angle) :
                      radius + (radius - bigContainerSize / 2 - padding) * cos(angle);
                      double y = index.isOdd ? radius + (radius - smallContainerSize / 2 - padding) * sin(angle) :
                      radius + (radius - bigContainerSize / 2 - padding) * sin(angle);

                      return Positioned(
                        left: index.isOdd ? x - smallContainerSize / 2 : x - bigContainerSize / 2,
                        top: index.isOdd ? y - smallContainerSize / 2 : y - bigContainerSize / 2,
                        child: Container(
                          width: index.isOdd ? smallContainerSize : bigContainerSize,
                          height: index.isOdd ? smallContainerSize : bigContainerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index.isEven ? const Color (0xff083D61) : const Color(0xffC7E9FD), // color of the inner containers
                          ),
                          child: Center(
                            child: Text("#politics",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: index.isEven ? Colors.white : Colors.black,
                              fontSize: size.width * .041
                            ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => AllTopicsPage()),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "click to",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: size.width * .027,
                              height: 0
                            )
                        ),
                        Wrap(
                          direction: Axis.vertical,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                                "Extend",
                                style: TextStyle(
                                    fontSize: size.width * .065,
                                    fontWeight: FontWeight.w700,
                                    height: 0
                                )
                            ),
                            Text(
                                "more topics",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: size.width * .027,
                                    height: 0
                                )
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              top: 11,
              right: 0,
              child: Image.asset("assets/images/top_right_circle_topics_page.png"),
            ),
            Positioned(
              top: topPadding * 1.25,
              left: 21,
              child: Text(
                "Any Interest On\n#topics",
                style: TextStyle(
                  fontSize: size.width * .055,
                  height: 0,
                  fontWeight: FontWeight.w700
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: SizedBox(
                width: size.width,
                height: size.height * 1/3,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                    },
                    child: Container(
                      width: size.width * .5,
                      height: appBarHeight * .85,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        color: const Color(0xff083D61),
                      ),
                      child: Center(
                        child: Text(
                          "Lets Explore",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              height: 0,
                              fontSize: size.width * .045,
                              color: Colors.white
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
