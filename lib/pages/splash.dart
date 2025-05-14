import 'dart:async';

import 'package:alp_animated_splashscreen/alp_animated_splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readeus/pages/bangla_news_fetcher.dart';
import 'package:readeus/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late Timer timer;
  bool isFirstTimer = true;
  
  init() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.containsKey("isFirstTimer") && sharedPreferences.getBool("isFirstTimer") == false) {
      setState(() {
        isFirstTimer = false;
      });
    }
    
    timer = Timer(const Duration(seconds: 5), () {
      Get.to(() => isFirstTimer ? WelcomePage() : BanglaNewsFetcher(url: "https://www.prothomalo.com/"));
    });
  }
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return const AnimatedSplashScreen(
      companyname: 'Readeus INC.',
      brandnamecolor: Colors.blueAccent,
      backgroundcolor: Colors.white,
      foregroundcolor: Colors.black,
      logo: 'assets/images/icon_new.png',
      brandname: '',
    );
  }
}
