import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:readeus/models/news_data.dart';
import 'package:sqflite/sqflite.dart';

import '../controllers/database_controller.dart';

class NewsViewModel extends GetxController {

  Rx<NewsData> newsDataModel = NewsData(time: [].obs, category: [].obs, title: [].obs, summary: [].obs, link: [].obs, image: [].obs).obs;

  fetchData() async {
    final Database db = await DatabaseController().database;

    // Get all table names from the database
    // var tableNames = await db.rawQuery("SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'");
    // var tableData = await db.rawQuery("SELECT * FROM verses WHERE surah_id = $surahNumber");

    var time = await db.rawQuery("SELECT Time FROM sample_data");
    var category = await db.rawQuery("SELECT Category FROM sample_data");
    var title = await db.rawQuery("SELECT Title FROM sample_data");
    var summary = await db.rawQuery("SELECT Summary FROM sample_data");
    var link = await db.rawQuery("SELECT Link FROM sample_data");
    var image = await db.rawQuery("SELECT Image FROM sample_data");

    newsDataModel.value = NewsData(time: time.obs, category: category.obs, title: title.obs, summary: summary.obs, link: link.obs, image: image.obs);
    print(newsDataModel.value.time[0]);
  }

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    await fetchData();
  }
}
