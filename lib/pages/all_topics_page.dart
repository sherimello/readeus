import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/channels_page.dart';

class AllTopicsPage extends StatelessWidget {
  const AllTopicsPage({super.key});

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
            end: Alignment.topLeft,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: appBarHeight + 7, bottom: size.height * 1/3 - appBarHeight),
              child: SizedBox(
                height: size.height - (topPadding + appBarHeight - size.height * 1/3),
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return Container(
                      width: size.width,
                      height: appBarHeight,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text("#topic",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: size.width * .041
                          ),
                          )),
                      padding: EdgeInsets.symmetric(horizontal: 17),
                      margin: EdgeInsets.symmetric(vertical: 5.5,  horizontal: 21), // Optional margin for spacing
                    );
                  },
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
                      GestureDetector(
                        onTap: () => Get.to(() => ChannelsPage()),
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
                              "Choose Any 3",
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
                      const SizedBox(height: 7,),
                      Text("Skip",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700
                      ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SizedBox(
                width: size.width,
                height: appBarHeight,
                child: AppBar(
                  automaticallyImplyLeading: true,
                  backgroundColor: Colors.transparent,
                  title: Text("Extended Topics"),
                  centerTitle: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}