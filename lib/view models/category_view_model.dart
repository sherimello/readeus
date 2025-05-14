import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../controllers/database_controller.dart';

class CategoryViewModel extends GetxController {


  saveCategories(List<String?> categories) async {
    final Database db = await DatabaseController().database;
    await db.rawQuery(
        """CREATE TABLE IF NOT EXISTS categories(id INT PRIMARY KEY, categories VARCHAR(255), portal VARCHAR(255))""");
    for (var category in categories) {
      db.rawInsert("""INSERT INTO categories (categories, portal)
SELECT '$category', 'BBC'
WHERE NOT EXISTS (
    SELECT 1
    FROM categories
    WHERE categories = '$category' AND portal = 'BBC'
)""");
    }
    var cats = await db.rawQuery("SELECT * FROM categories");

    cats.forEach((action) => print(action["categories"]));

    // print(cats);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async{

    final Database db = await DatabaseController().database;

    var cats = await db.rawQuery("SELECT * FROM categories");

    return cats;

  }

  deleteACategory(String cat) async{
    final Database db = await DatabaseController().database;
    await db.rawDelete("DELETE FROM categories WHERE portal = 'BBC' AND categories = $cat");
  }

  deleteTable() async{
    final Database db = await DatabaseController().database;
    await db.rawDelete("DROP TABLE IF EXISTS categories");
  }


}
