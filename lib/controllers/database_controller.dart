import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseController extends GetxController {
  Database? _database;

  Future<Database> get database async {
    // if (_database != null) return _database.value!;

    _database = await initDatabase("output.db");
    return _database!;
  }

  //this code initializes the database...
  Future<Database> initDatabase(String dbName) async {
    // Get a location using getDatabasesPath
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, dbName);

    // Check if the database file exists in the documents directory
    if (!await databaseExists(path)) {
      // Copy the database from assets to the documents directory
      await _copyDatabase(path, dbName);
    }

    // Open the database with read and write access
    return await openDatabase(
      path,
      version: 5,
      readOnly: false,
    );
  }

  Future<void> _copyDatabase(String path, dbName) async {
    // Get the asset database file
    ByteData data = await rootBundle.load('assets/documents/$dbName');
    List<int> bytes = data.buffer.asUint8List();

    // Write the bytes to the database file
    await File(path).writeAsBytes(bytes, flush: true);
  }

  @override
  void onInit()async {
    // TODO: implement onInit
    super.onInit();
    // await database;
  }

}