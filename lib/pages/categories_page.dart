import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/terms_and_policies_page.dart';
import 'package:readeus/pages/topics_page.dart';
import 'package:readeus/widgets/circular_button.dart';
import 'package:readeus/widgets/one_sided_circular_button.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;

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
            Positioned(
                left: 0,
                child: Image.asset("assets/images/right_disk_categories_screen.png")),
            Positioned(
              top: 11,
              right: 0,
              child: Image.asset("assets/images/top_right_disk_categories_screen.png"),
            ),
        Positioned(
          left: 7,
          child: Text("WHAT\nMATTERS\nTHE\nMOST",
          style: TextStyle(
            fontSize: size.width * .081,
            fontWeight: FontWeight.w700
          ),
          ),
        ),
            Positioned(
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 11,
                children: [
                  CircularButton(tag: " Personalised Feed", imageAddress: "assets/images/personalized_feed.png"),
                  OneSidedCircularButton(tag: " New Reading Style", image: "assets/images/new_reading_style.png"),
                  CircularButton(tag: " Reading Shorts (AI)", imageAddress: "assets/images/reading_shorts.png"),
                  OneSidedCircularButton(tag: " Trending", image: "assets/images/trending.png"),
                  CircularButton(tag: " Follow Local News", imageAddress: "assets/images/follow.png"),
                  OneSidedCircularButton(tag: " Choose Categories", image: "assets/images/choose_categories.png"),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                width: size.width,
                height: size.height * 1/3,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => const TopicsPage());
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
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                width: size.width,
                height: ((size.height * 1/3) * .5) - (appBarHeight * .85 * .5),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Get.to(() => TermsAndPolicies()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("By clicking you agree to our terms and policies ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * .025,
                          fontWeight: FontWeight.w700
                        ),
                        ),
                        Image.asset("assets/images/info.png"),
                      ],
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
