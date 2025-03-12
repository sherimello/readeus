import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/thank_you_page.dart';

class SignInAndRegistration extends StatelessWidget {
  const SignInAndRegistration({super.key});

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
          children: [
            Positioned(
              top: topPadding + appBarHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 2,
                    child: Container(
                      width: size.width,
                      // height: size.width * .75,
                      margin: EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(45),
                          gradient: LinearGradient(
                              colors: [const Color(0xffA8CDEF), const Color(0xffffffff)],
                              begin: Alignment.bottomRight,
                              end: Alignment.topLeft),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: size.width * .17,
                                height: size.width * .17,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1000),
                                  color: Color(0xffA8CDEF),
                                ),
                              ),
                              SizedBox(width: size.width * .17 * .65,),
                              Container(
                                width: size.width * .17,
                                height: size.width * .17,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1000),
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 17,),
                          Container(
                            width: size.width * .75,
                            height: 17,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: LinearGradient(
                                  begin: AlignmentDirectional.centerEnd,
                                  end: AlignmentDirectional.centerStart,
                                  colors: [
                                Colors.black,
                                const Color(0xff6B8EA7),
                                const Color(0xff5185AB),
                                const Color(0xff347BAE),
                                const Color(0xff7EC5F7),
                                const Color(0xff99CEF5),
                              ])
                            ),
                          ),
                          const SizedBox(height: 17,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Ready To Sign Up?",
                              style: TextStyle(
                                fontSize: size.width * .041
                              ),
                              ),
                              const SizedBox(width: 17,),
                              Image.asset("assets/images/linkedIn.png"),
                              const SizedBox(width: 9,),
                              Image.asset("assets/images/twitter.png"),
                            ],
                          ),
                          const SizedBox(height: 21,),
                          Text("Click here to see features you'll get upon logging in",
                          style: TextStyle(
                            fontSize: size.width * .027,
                            fontWeight: FontWeight.w700
                          ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: SafeArea(
                      top: false,
                      child: Container(
                        width: size.width,
                        // height: size.width * .75,
                        margin: EdgeInsets.symmetric(horizontal: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(45),
                          gradient: LinearGradient(
                              colors: [const Color(0xffA8CDEF), const Color(0xffffffff)],
                              begin: Alignment.bottomRight,
                              end: Alignment.topLeft),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(17.0),
                              child: Text("What You Will Be Missing If You Don't Join Us For FREE",
                              style: TextStyle(
                                fontSize: size.width * .075
                              ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 17,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                  },
                                  child: Container(
                                    width: size.width * .41,
                                    height: appBarHeight * .85,
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(17),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Unlimited AI Articles",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            height: 0,
                                            fontSize: size.width * .029,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                  },
                                  child: Container(
                                    width: size.width * .41,
                                    height: appBarHeight * .85,
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(17),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "More Customisations",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            height: 0,
                                            fontSize: size.width * .029,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 17,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                  },
                                  child: Container(
                                    width: size.width * .41,
                                    height: appBarHeight * .85,
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(17),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Unlimited AI Articles",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            height: 0,
                                            fontSize: size.width * .029,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                  },
                                  child: Container(
                                    width: size.width * .41,
                                    height: appBarHeight * .85,
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(17),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "More Customisations",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            height: 0,
                                            fontSize: size.width * .029,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Positioned(
                top: topPadding,
                left: 21,
                child: SizedBox(
                    height: appBarHeight,
                    child: Center(child: GestureDetector(
                        onTap: () => Get.to(() => ThankYouPage()),
                        child: Image.asset("assets/images/cross.png")))))
          ],
        ),
      ),
    );
  }
}
