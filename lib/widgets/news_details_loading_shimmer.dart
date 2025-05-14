import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:get/get.dart';

class NewsDetailsLoadingShimmer extends StatelessWidget {
  const NewsDetailsLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.black,
      child: Skeletonizer(
        justifyMultiLineText: true,
        enabled: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 31),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 0,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: appBarHeight + topPadding + 11),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: Image.network(
                      "https://www.bbc.com/bbcx/grey-placeholder.png",
                      width: size.width,
                      height: size.width * .49,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 11,
                ),
                Text(
                  "title",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      height: 0,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 21),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 7.0, bottom: 7),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: Colors.grey),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Text(
                        "                  ",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 12,
                            height: 0),
                      ),
                    ),
                  ),
                ),
                Text(
                  "author",
                  style: TextStyle(
                      color: Colors.white,
                      height: 0,
                      fontWeight: FontWeight.w200,
                      // fontStyle: FontStyle.italic,
                      fontSize: 15),
                ),
                Text(
                  "source",
                  style: TextStyle(
                      height: 0,
                      color: Colors.white,
                      fontWeight: FontWeight.w200,
                      // fontStyle: FontStyle.italic,
                      fontSize: 15),
                ),
                const SizedBox(
                  height: 7,
                ),
                Row(
                  spacing: 5,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1000),
                          color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(
                          LineIcons.bookmark,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1000),
                          color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(
                          CupertinoIcons.heart,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 21,
                ),
                SelectableText(
                  "{snapshot.data['body'].toString().replaceAll(\n\n, \n)}\n\n{snapshot.data['body'].toString().replaceAll(\n\n, \n)}\n\n{snapshot.data['body'].toString().replaceAll(\n\n, \n)}\n\n",
                  style: TextStyle(
                      height: 0,
                      color: Colors.white,
                      // fontWeight: FontWeight.w600,
                      fontSize: 15),
                  textAlign: TextAlign.justify,
                ),
                Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(children: [
                      TextSpan(
                        text: "{snapshot.data['copyright'].toString().replaceAll{snapshot.data['copyright'].toString().replaceAll{snapshot.data['copyright'].toString().replaceAll(\n\n",
                        style: TextStyle(
                            height: 0,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      )
                    ])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
