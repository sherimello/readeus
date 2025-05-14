import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/news_portals.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  "assets/images/top_disk_welcome_screen.png",
                  height: size.width * .55,
                  fit: BoxFit.contain,
                )),
            SingleChildScrollView(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Image.asset("assets/images/icon.png"),
                          Image.asset(
                            "assets/images/welcome_text.png",
                            color: Colors.white,
                          ),
                          Image.asset("assets/images/readeus_text.png"),
                          const SizedBox(
                            height: 29,
                          ),
                          Text(
                            "we reduce content into a\nreadable manner",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                height: 0,
                                fontSize: size.width * .051),
                          ),
                          SizedBox(
                            height: topPadding,
                          )
                        ],
                      ),
                    ),
                    Flexible(
                        flex: 1,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => const NewsPortals());
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
                                  "Lets Move",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      height: 0,
                                      fontSize: size.width * .045,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
