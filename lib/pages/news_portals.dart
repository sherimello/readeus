import 'dart:convert';
import 'dart:developer'; // For log

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:readeus/pages/bangla_news_fetcher.dart';
import 'package:readeus/pages/test.dart';
import 'package:readeus/view%20models/category_view_model.dart';

// REMOVE GLOBAL LISTS - State will be managed locally or returned by functions
// List<String?> menuItems = [];
// List<String> selectedChips = [];

class NewsPortals extends StatelessWidget {
  const NewsPortals({super.key});

  // --- Fetch Functions Now RETURN Lists ---

  Future<List<String>> fetchProthomAloCategories() async {
    final url = Uri.parse('https://www.prothomalo.com/');
    // Use LOCAL list inside the function
    final List<String> localCategories = [];

    print("Fetching Prothom Alo categories from: $url");
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      };
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        String decodedHtml = utf8.decode(response.bodyBytes);
        dom.Document document = dom.Document.html(decodedHtml);
        List<dom.Element> categoryLinks = document.querySelectorAll('ul.navbar-list li a');
        // ... (fallback selector logic if needed) ...

        print("Found ${categoryLinks.length} potential Prothom Alo links.");
        for (var linkElement in categoryLinks) {
          String categoryName = linkElement.text.trim();
          if (categoryName.isNotEmpty) {
            localCategories.add(categoryName);
          }
        }
        print("Extracted Prothom Alo Categories: ${localCategories.join(', ')}");
        // RETURN the locally fetched list
        return localCategories;
      } else {
        print('Failed Prothom Alo: ${response.statusCode}');
        throw Exception('Failed Prothom Alo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Prothom Alo categories: $e');
      throw Exception('Error fetching Prothom Alo categories: $e');
    }
  }

  Future<List<String>> fetchCNNCats() async {
    final url = Uri.parse("https://www.edition.cnn.com");
    // Use LOCAL list
    List<String> localCnnCats = [];
    print("Fetching CNN categories from: $url");
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      };
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final document = dom.Document.html(response.body);
        // Use a more specific selector for CNN nav if possible
        final links = document.querySelectorAll('div.header__nav-item a, .nav-section__item a'); // Example selectors
        localCnnCats = links.map((e) => e.text.trim()).where((text) => text.isNotEmpty).toList();
        print("Extracted CNN Categories (raw): ${localCnnCats.join(', ')}");
        // RETURN the locally fetched list
        return localCnnCats;
      } else {
        print("Failed CNN: ${response.statusCode}");
        throw Exception("Failed CNN: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching CNN categories: $e');
      throw Exception('Error fetching CNN categories: $e');
    }
  }

  // --- Main Fetch Function to Combine Results ---
  Future<List<String>> fetchAllPortalCategories() async {
    print("--- Starting to fetch all portal categories ---");
    // Use LOCAL lists to store results from each source
    List<String> bbcCats = [];
    List<String> cnnCats = [];
    List<String> prothomAloCats = [];

    // 1. Fetch BBC
    final urlBbc = Uri.parse("https://www.bbc.com");
    print("Fetching BBC categories from: $urlBbc");
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      };
      final responseBbc = await http.get(urlBbc, headers: headers);
      if (responseBbc.statusCode == 200) {
        final documentBbc = dom.Document.html(responseBbc.body);
        final linksBbc = documentBbc.querySelectorAll('[data-testid="mainNavigationLink"]');
        bbcCats = linksBbc.map((e) => e.text.trim()).toList();
        print("Extracted BBC Categories (raw): ${bbcCats.join(', ')}");
      } else {
        print("Failed BBC: ${responseBbc.statusCode}");
        // Decide if you want to throw or continue if one source fails
      }
    } catch (e) {
      print('Error fetching BBC categories: $e');
      // Decide if you want to throw or continue
    }

    // 2. Fetch CNN (await the result)
    try {
      cnnCats = await fetchCNNCats(); // Gets the returned list
    } catch (e) {
      print('Error occurred during CNN fetch, continuing without CNN cats: $e');
      cnnCats = []; // Assign empty list on error
    }


    // 3. Fetch Prothom Alo (await the result)
    try {
      prothomAloCats = await fetchProthomAloCategories(); // Gets the returned list
    } catch(e) {
      print('Error occurred during Prothom Alo fetch, continuing without PA cats: $e');
      prothomAloCats = []; // Assign empty list on error
    }


    // 4. Combine and Process Locally
    print("Combining and processing all categories...");
    List<String> combinedCats = [];
    combinedCats.addAll(bbcCats);
    combinedCats.addAll(cnnCats);
    combinedCats.addAll(prothomAloCats);
    print("Combined (Before filtering): ${combinedCats.length} items");

    // Apply filtering - Use a Set for efficient filtering and deduplication
    Set<String> finalCatsSet = combinedCats.where((cat) {
      // Keep non-empty strings, remove specific items, remove items with '-'
      return cat.isNotEmpty &&
          cat != "Audio" &&
          cat != "Video" &&
          cat != "Live" &&
          cat != "News" && // Keep "News"? Maybe remove later if needed
          cat != "Earth" &&
          //  cat != "Business" && // Keep Business?
          cat != "Games" &&
          !cat.contains("-") &&
          !cat.toLowerCase().contains("weather") && // Example: case-insensitive filter
          !cat.toLowerCase().contains("tv & radio"); // Example
    }).toSet(); // toSet automatically handles duplicates

    List<String> finalCatsList = finalCatsSet.toList();
    // Optional: Sort the final list alphabetically
    finalCatsList.sort((a, b) => a.compareTo(b));

    print("--- Finished fetching. Final Categories (${finalCatsList.length}): ${finalCatsList.join(', ')} ---");
    return finalCatsList; // Return the final processed list
  }

  @override
  Widget build(BuildContext context) {
    // This ViewModel is likely okay, assuming it uses its own state management
    CategoryViewModel categoryViewModel = Get.put(CategoryViewModel());
    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<List<String>>( // Expecting List<String> now
          // Call the coordinating function
          future: fetchAllPortalCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              // Provide more context if possible
              return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Error Loading Categories: ${snapshot.error}", // Show error
                      style: TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ));
            }

            // Check if data is null or empty
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text(
                    "No categories found.",
                    style: TextStyle(color: Colors.white),
                  ));
            }

            // Data is guaranteed to be List<String> here
            List<String> cats = snapshot.data!;

            // Pass the clean list to the stateful widget
            return ChipSelectionWidget(
              categories: cats,
              categoryViewModel: categoryViewModel,
            );
          },
        ),
      ),
    );
  }
}

// --- ChipSelectionWidget ---
class ChipSelectionWidget extends StatefulWidget {
  final List<String> categories; // Now List<String>, not List<String?>
  final CategoryViewModel categoryViewModel;

  const ChipSelectionWidget(
      {super.key, required this.categories, required this.categoryViewModel});

  @override
  _ChipSelectionWidgetState createState() => _ChipSelectionWidgetState();
}

class _ChipSelectionWidgetState extends State<ChipSelectionWidget> {
  // MAKE selectedChips a LOCAL STATE VARIABLE
  final List<String> _selectedChips = [];
  bool _isLoadingSaved = true; // Flag for loading saved categories

  @override
  void initState() {
    super.initState();
    // Load saved categories asynchronously
    _loadSavedCategories();
  }

  // Function to load saved categories
  Future<void> _loadSavedCategories() async {
    // Reset loading state if called again
    // if (mounted) {
    //   setState(() {
    //     _isLoadingSaved = true;
    //   });
    // }
    try {
      final savedCatsMap = await widget.categoryViewModel.fetchCategories();
      final List<String> savedCatsList = savedCatsMap
          .map((action) => action["categories"] as String?) // Cast safely
          .where((cat) => cat != null) // Filter out nulls
          .cast<String>() // Cast to String
          .toList();

      // Update state only if the widget is still mounted
      if (mounted) {
        setState(() {
          _selectedChips.clear(); // Clear existing selections first
          _selectedChips.addAll(savedCatsList);
          _isLoadingSaved = false; // Mark loading as complete
          log("Loaded saved categories: ${_selectedChips.join(', ')}");
        });
      }
    } catch (e) {
      log("Error loading saved categories: $e");
      // if (mounted) {
      //   setState(() {
      //     _isLoadingSaved = false; // Still finish loading state on error
      //   });
      //   // Optionally show an error message
      //   // ScaffoldMessenger.of(context).showSnackBar(
      //   //     SnackBar(content: Text("Error loading saved preferences: $e"), backgroundColor: Colors.red,)
      //   // );
      // }
    }
  }


  // Toggle selection using the local _selectedChips list
  void _toggleChipSelection(String chipText) {
    setState(() {
      if (_selectedChips.contains(chipText)) {
        _selectedChips.remove(chipText);
      } else {
        _selectedChips.add(chipText);
      }
      log("Current selected chips: ${_selectedChips.join(', ')}");
    });
  }

  // Function to handle confirmation
  Future<void> _confirmSelection() async {
    // Show loading indicator while saving
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await widget.categoryViewModel.deleteTable(); // Clear existing saved data
      if (_selectedChips.isNotEmpty) {
        await widget.categoryViewModel.saveCategories(_selectedChips); // Save current selection
        log("Saved categories: ${_selectedChips.join(', ')}");
      } else {
        log("No categories selected, cleared saved data.");
      }
      // Pop loading indicator
      Navigator.of(context).pop();
      // Navigate to Test page
      Get.to(() => BanglaNewsFetcher(url: 'https://www.prothomalo.com/collection/latest/'));

    } catch (e) {
      log("Error saving categories: $e");
      // Pop loading indicator
      Navigator.of(context).pop();
      // Show error message
      // ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text("Error saving preferences: $e"), backgroundColor: Colors.red,)
      // );
    }
  }


  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text("Select Categories", style: TextStyle(color: Colors.white)),
        actions: [
          // Use the local _selectedChips list for button state
          GestureDetector(
            onTap: _confirmSelection, // Call the save function
            child: Container(
              margin: const EdgeInsets.only(right: 15), // Reduced margin
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Padding
              decoration: BoxDecoration(
                  color: _selectedChips.isEmpty ? Colors.white24 : Colors.blue, // Update color based on local state
                  borderRadius: BorderRadius.circular(20)), // Rounded corners
              child: Text(
                _selectedChips.isEmpty ? "Skip" : "Confirm", // Simpler text
                style: TextStyle(color: Colors.white, height: 1), // Adjusted style
              ),
            ),
          )
        ],
      ),
      backgroundColor: Colors.black,
      // Show loading indicator while fetching saved categories OR show chips
      body: ListView( // Use ListView instead of Builder for single child scroll
        padding: const EdgeInsets.all(20), // Adjusted padding
        children: [
          Container(
            width: size.width,
            decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(41) // Slightly less rounded
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0), // Adjusted padding
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15), // Add rounding
                    child: Image.asset(
                      "assets/images/img.png", // Ensure this asset exists
                      width: size.width * .25, // Adjusted size
                      height: size.width * .25,
                      errorBuilder: (ctx, err, st) => Icon(Icons.newspaper, size: size.width * .2, color: Colors.white30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(27, 0, 27, 27), // Adjusted padding
                  child: Wrap(
                    spacing: 8, // Spacing between chips horizontally
                    runSpacing: 8, // Spacing between chips vertically
                    alignment: WrapAlignment.center,
                    children: widget.categories.map((category) { // Iterate directly
                      // Use the local state variable _selectedChips
                      final bool isSelected = _selectedChips.contains(category);
                      return ChoiceChip(
                        label: Text(category),
                        labelStyle: TextStyle( // Consistent label style
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w500
                        ),
                        selected: isSelected,
                        selectedColor: Colors.white,
                        backgroundColor: Color(0xff4e4e4e), // Background for unselected
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.white : Colors.transparent)), // Optional border
                        onSelected: (bool selected) {
                          _toggleChipSelection(category);
                        },
                      );
                    }).toList(), // Convert map result to list
                  ),
                ),
                // Show selected categories at the bottom if needed
                if (_selectedChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0, 20, 20),
                    child: Text(
                      "Selected: ${_selectedChips.join(", ")}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10,) // Add some bottom padding inside the container
              ],
            ),
          ),
        ],
      ),
    );
  }
}