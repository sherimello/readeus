import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CircularButton extends StatelessWidget {
  final String tag, imageAddress;

  const CircularButton({super.key, required this.tag, required this.imageAddress});

  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.only(right: 3.0),
      child: Container(
        width: size.width * .5,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: const Color(0xff083D61),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imageAddress),
            Text(
              tag,
              textAlign: TextAlign.center,
              style: TextStyle(
                  height: 0,
                  fontSize: size.width * .035,
                  color: Colors.white
              ),
            ),
          ],
        ),
      ),
    );
  }
}
