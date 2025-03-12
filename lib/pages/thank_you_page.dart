import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/home_page.dart';

class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

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
            top: 11,
            right: 0,
            child: Image.asset("assets/images/top_right_disk_categories_screen.png"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/robot.png"),
                  const SizedBox(height: 19,),
                  Text("Thank you for letting us know youur preferences.",
                  style: TextStyle(
                    fontSize: size.width * .045,
                    fontWeight: FontWeight.w700
                  ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: appBarHeight,),
                  Text("We are preparing your feed. Thank you for your patience...",
                  style: TextStyle(
                    fontSize: size.width * .075,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xff2C6AA3),
                    height: 0
                  ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
                    Get.to(() => HomePage());
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
                        "Lets Go",
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
        ],
      ),
      ),
    );
  }
}
