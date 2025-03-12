import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OneSidedCircularButton extends StatelessWidget {
  final String tag, image;
  const OneSidedCircularButton({super.key, required this.tag, required this.image});

  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;

    return Container(
      width: size.width * .53,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(100), bottomLeft: Radius.circular(100)),
        color: const Color(0xff3778A6),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image),
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
    );
  }
}
