import 'package:get/get.dart';

class NewsData {
  late RxList<dynamic> time, category, title, summary, link, image;

  NewsData(
      {required this.time,
      required this.category,
      required this.title,
      required this.summary,
      required this.link,
      required this.image});
}
