import 'dart:developer';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../pages/bangla_news_fetcher.dart';
import '../view models/category_view_model.dart';

class ChipSelectionController extends GetxController {
  final RxList<String> selectedChips = <String>[].obs;
  final RxBool isLoadingSaved = true.obs;
  final CategoryViewModel categoryViewModel = Get.find<CategoryViewModel>();

  @override
  void onInit() {
    super.onInit();
    loadSavedCategories();
  }

  Future<void> loadSavedCategories() async {
    isLoadingSaved.value = true;
    try {
      final savedCatsMap = await categoryViewModel.fetchCategories();
      final savedCatsList = savedCatsMap
          .map((action) => action["categories"] as String?)
          .whereType<String>()
          .toList();
      selectedChips.assignAll(savedCatsList);
    } catch (e) {
      log("Error loading saved categories: $e");
    } finally {
      isLoadingSaved.value = false;
    }
  }

  void toggleChip(String chipText) {
    if (selectedChips.contains(chipText)) {
      selectedChips.remove(chipText);
    } else {
      selectedChips.add(chipText);
    }
  }

  Future<void> confirmSelection() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.white)),
      barrierDismissible: false,
    );

    try {
      await categoryViewModel.deleteTable();
      if (selectedChips.isNotEmpty) {
        await categoryViewModel.saveCategories(selectedChips);
      }
      Get.back(); // Close loading dialog
      Get.to(() => BanglaNewsFetcher(url: 'https://www.prothomalo.com/collection/latest/'));
    } catch (e) {
      Get.back(); // Close loading dialog on error
      log("Error saving categories: $e");
    }
  }
}