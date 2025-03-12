import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/sign_in_and_registration.dart';

class ChannelsPage extends StatelessWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;

    // Create a list to store the random numbers
    List<int> randomNumbers = [];

    List channelIcons = ["assets/images/the_business_standard.png", "assets/images/bbc.png",
    "assets/images/cnn.png", "assets/images/prothom_alo.png"];

    getRandomChannelName() {
      // Create an instance of Random
      Random random = Random();


      // Generate 6 random numbers between 1 and 3 (inclusive)
      for (int i = 0; i < 9; i++) {
        int randomInt = random.nextInt(3); // Generates 1, 2, or 3
        randomNumbers.add(randomInt);
      }

      // Print the list of random numbers
      print(randomNumbers);

    }

    getRandomChannelName();

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
              child: Image.asset("assets/images/top_right_circle_topics_page.png"),
            ),
            Positioned(
              top: topPadding * 1.25,
              left: 21,
              child: Text(
                "Select The\n#Channels",
                style: TextStyle(
                    fontSize: size.width * .055,
                    height: 0,
                    fontWeight: FontWeight.w700
                ),
              ),
            ),
            Positioned(
              top: size.width * .055 * 2 + topPadding * 1.25,
              left: 8,
              right: 8,
              child: Container(
                width: size.width,
                height: (size.width + size.width * .055 + topPadding * 1.25),
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Number of columns
                          childAspectRatio: 1, // Aspect ratio of each item
                        ),
                        itemCount: 9, // Total number of items
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.all(8), // Margin around each container
                            decoration: BoxDecoration(
                              color: Colors.white, // Different shades of blue
                              borderRadius: BorderRadius.circular(35), // Rounded corners
                            ),
                            child: Center(
                              child: Image.asset(channelIcons[randomNumbers[index]]),
                              // child: Text(
                              //   'Item ${index + 1}',
                              //   style: TextStyle(
                              //     color: Colors.black,
                              //     fontSize: 20,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                            ),
                          );
                        },
                      ),
                    ),
                    // const SizedBox(height: 11),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: const Color(0xff083D61)
                      ),
                      child: Padding(padding: EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 7
                      ),
                      child: Text("  Browse More Channels  ",
                      style: TextStyle(color: Colors.white),
                      ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: SizedBox(
                width: size.width,
                height: size.height * 1/3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                            },
                            child: Container(
                              width: size.width * .45,
                              height: appBarHeight * .85,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(topRight: Radius.circular(19), bottomRight: Radius.circular(19)),
                                color: const Color(0xff083D61),
                              ),
                              child: Center(
                                child: Text(
                                  "Previous",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      height: 0,
                                      fontSize: size.width * .041,
                                      color: Colors.white
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => SignInAndRegistration());
                            },
                            child: Container(
                              width: size.width * .45,
                              height: appBarHeight * .85,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(19), bottomLeft: Radius.circular(19)),
                                color: const Color(0xff083D61),
                              ),
                              child: Center(
                                child: Text(
                                  "Choose Any 3",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      height: 0,
                                      fontSize: size.width * .041,
                                      color: Colors.white
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: SizedBox(
                            width: size.width * .45,
                            height: appBarHeight * .85,
                            child: Center(child: Text("Skip",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700
                              ),
                            ))),
                      )
                    ],
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
