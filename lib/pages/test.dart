import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:readeus/pages/news_details.dart';

class Test extends StatelessWidget {
  const Test({super.key});

  // Future<Map<String, List<dynamic>>> fetchHeadlines() async {
  //   final response = await http.get(Uri.parse('https://www.bbc.com'));
  //   final headlines = <String>[];
  //   final images = <String?>[];
  //   final timestamps = <String?>[];
  //
  //   if (response.statusCode == 200) {
  //     final document = dom.Document.html(response.body);
  //     final newsCards = document.querySelectorAll('''
  //     [data-testid="dundee-card"],
  //     [data-testid="manchester-card"],
  //     [data-testid="westminster-card"]
  //   ''');
  //
  //     print('Number of news cards: ${newsCards.length}');
  //
  //     for (final card in newsCards) {
  //       // Extract headline
  //       final headlineElement = card.querySelector('h2[data-testid="card-headline"]');
  //       final headline = headlineElement?.text.trim() ?? 'No headline';
  //       headlines.add(headline);
  //
  //       // Extract timestamp
  //       final timestampElement = card.querySelector('span[data-testid="card-metadata-lastupdated"]');
  //       timestamps.add(timestampElement?.text.trim());
  //
  //       // Extract image URL
  //       String? imageUrl;
  //       final mediaContainer = card.querySelector('div[data-testid="card-media"]');
  //       if (mediaContainer != null) {
  //         final img = mediaContainer.querySelector('img');
  //         if (img != null) {
  //           final srcset = img.attributes['srcset'];
  //           if (srcset != null && srcset.isNotEmpty) {
  //             final parts = srcset.split(',');
  //             if (parts.isNotEmpty) {
  //               imageUrl = parts.last.trim().split(' ')[0];
  //             }
  //           } else {
  //             imageUrl = img.attributes['src'];
  //           }
  //         }
  //       }
  //       images.add(imageUrl);
  //
  //       // Debug print
  //       print('''
  //     Card ${headlines.length - 1}:
  //     Headline: $headline
  //     Timestamp: ${timestamps.last}
  //     Image: ${images.last ?? "No image"}
  //     ''');
  //     }
  //   } else {
  //     throw Exception('Failed to load BBC homepage');
  //   }
  //
  //   // Remove placeholder filtering since we're maintaining 1:1 mapping
  //   return {
  //     'headlines': headlines,
  //     'images': images,
  //     'timestamps': timestamps
  //   };
  // }

  Future<Map<String, List<dynamic>>> fetchNewsData() async {
    final response = await http.get(Uri.parse('https://www.bbc.com'));
    final headlines = <String>[];
    final images = <String?>[];
    final timestamps = <String?>[];
    final articleUrls = <String?>[];

    if (response.statusCode == 200) {
      final document = dom.Document.html(response.body);
      final newsCards = document.querySelectorAll('''
      [data-testid="dundee-card"],
      [data-testid="manchester-card"],
      [data-testid="westminster-card"]
    ''');

      for (final card in newsCards) {
        // Extract headline
        final headlineElement = card.querySelector('h2[data-testid="card-headline"]');
        headlines.add(headlineElement?.text.trim() ?? 'No headline');

        // Extract timestamp
        final timestampElement = card.querySelector('span[data-testid="card-metadata-lastupdated"]');
        timestamps.add(timestampElement?.text.trim());

        // Extract article URL
        final linkElement = card.querySelector('a[data-testid="internal-link"]');
        final relativeUrl = linkElement?.attributes['href'];
        articleUrls.add(relativeUrl != null
            ? Uri.parse('https://www.bbc.com').resolve(relativeUrl).toString()
            : null);

        // Extract image URL
        String? imageUrl;
        final mediaContainer = card.querySelector('div[data-testid="card-media"]');
        if (mediaContainer != null) {
          final img = mediaContainer.querySelector('img');
          if (img != null) {
            final srcset = img.attributes['srcset'];
            if (srcset != null && srcset.isNotEmpty) {
              final parts = srcset.split(',');
              imageUrl = parts.last.trim().split(' ')[0];
            } else {
              imageUrl = img.attributes['src'];
            }
          }
        }
        images.add(imageUrl);
      }
    }

    return {
      'headlines': headlines,
      'images': images,
      'timestamps': timestamps,
      'urls': articleUrls,
    };
  }

  Future<Map<String, List<dynamic>>> fetchHeadlines() async {

    final response = await http.get(Uri.parse('https://www.bbc.com'));
    final headlines = <String>[];
    final images = <String>[];
    final urls = <String>[];
    final timestamps = <String?>[];
    var articleUrls = <String?>[];

    if (response.statusCode == 200) {
      final document = dom.Document.html(response.body);
      final newsCards = document.querySelectorAll('''
      [data-testid="dundee-card"],
      [data-testid="manchester-card"],
      [data-testid="westminster-card"]
    ''');

      print('Number of news cards: ${newsCards.length}');

      for (final card in newsCards) {
        // Extract headline
        final headlineElement = card.querySelector('h2[data-testid="card-headline"]');
        headlines.add(headlineElement?.text.trim() ?? 'No headline');

        // Extract timestamp
        final timestampElement = card.querySelector('span[data-testid="card-metadata-lastupdated"]');
        timestamps.add(timestampElement?.text.trim());

        final linkElement = card.querySelector('''
        a[data-testid="internal-link"],
        a[data-testid="external-anchor"]
      ''');
        final relativeUrl = linkElement?.attributes['href'];
        articleUrls.add(relativeUrl != null
            ? Uri.parse('https://www.bbc.com').resolve(relativeUrl).toString()
            : null);

        articleUrls = articleUrls.toSet().toList();

        print('Headline: ${headlines.last}');
        // Target images within the card-media container
        final mediaContainer = card.querySelector('div[data-testid="card-media"]');
        if (mediaContainer != null) {
          final imgs = mediaContainer.querySelectorAll('img');
          for (final img in imgs) {
            // Prioritize srcset for higher quality images
            final srcset = img.attributes['srcset'];
            if (srcset != null) {
              // Get largest image from srcset (last entry)
              final parts = srcset.split(',');
              if (parts.isNotEmpty) {
                final largest = parts.last.trim().split(' ')[0];
                urls.add(largest);
              }
              else {
                urls.add("No image URL");
              }
            } else {
              // Fallback to src attribute
              final src = img.attributes['src'];
              if (src != null && src.isNotEmpty) {
                urls.add(src);
              }
              else {
                urls.add("No image URL");
              }
            }
          }
        }
        else {
          urls.add("value");
        }
      }
    } else {
      throw Exception('Failed to load BBC homepage');
    }


    print(urls.length);
    // Filter and deduplicate
    // final filteredUrls = urls
    //     .where((url) => !url.contains("placeholder")) //z Remove data URIs
    // // .toSet() // Remove duplicates
    //     .toList();

    List<String> filteredUrls = [];

    for(String url in urls) {
      filteredUrls.addIf((url == "value" && url == "/bbcx/grey-placeholder.png") || !filteredUrls.contains(url) && !url.contains("placeholder"), url == "value" ? "https://www.bbc.com/bbcx/grey-placeholder.png" : url);
    }

    print('Found ${filteredUrls.length} news card images:');
    filteredUrls.forEach((url) => print("News card image: $url"));
    articleUrls.forEach((v) => print(v));

    return {'headlines': headlines.toSet().toList(), 'images': filteredUrls, 'timestamps': timestamps, 'articleUrls': articleUrls};
  }

  Future<void> fetchImageUrls() async {
    final url = 'https://www.bbc.com';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = dom.Document.html(response.body);
      final urls = <String>[];

      // First find news card containers using specific data-testid attributes
      final newsCards = document.querySelectorAll('''
      [data-testid="dundee-card"],
      [data-testid="manchester-card"],
      [data-testid="westminster-card"]
    ''');

      for (final card in newsCards) {
        // Target images within the card-media container
        final mediaContainer = card.querySelector('div[data-testid="card-media"]');
        if (mediaContainer != null) {
          final imgs = mediaContainer.querySelectorAll('img');
          for (final img in imgs) {
            // Prioritize srcset for higher quality images
            final srcset = img.attributes['srcset'];
            if (srcset != null) {
              // Get largest image from srcset (last entry)
              final parts = srcset.split(',');
              if (parts.isNotEmpty) {
                final largest = parts.last.trim().split(' ')[0];
                urls.add(largest);
              }
              else {
                urls.add("No image URL");
              }
            } else {
              // Fallback to src attribute
              final src = img.attributes['src'];
              if (src != null && src.isNotEmpty) {
                urls.add(src);
              }
              else {
                urls.add("No image URL");
              }
            }
          }
        }
        else {
          urls.add("value");
        }
      }

      print(urls.length);
      // Filter and deduplicate
      final filteredUrls = urls
          .where((url) => !url.contains("placeholder")) // Remove data URIs
          // .toSet() // Remove duplicates
          .toList();

      print('Found ${filteredUrls.length} news card images:');
      filteredUrls.forEach((url) => print("News card image: $url"));
    } else {
      print('Failed to load page. Status code: ${response.statusCode}');
    }
  }

  // Future<void> fetchImageUrls() async {
  //   // Replace this URL with the one you want to scrape
  //   final url = 'https://bbc.com';  // Replace with your target URL
  //   final response = await http.get(Uri.parse(url));
  //
  //   if (response.statusCode == 200) {
  //     dom.Document document = dom.Document.html(response.body);
  //     // Use selector to get the images
  //     List<dom.Element> imgElements = document.querySelectorAll('img');
  //     List<String> urls = [];
  //
  //     for (var img in imgElements) {
  //       final src = img.attributes['src'];
  //       if (src != null) {
  //         urls.add(src);
  //       }
  //     }
  //
  //     urls.removeWhere((v) => v.contains("placeholder"));
  //
  //     print(urls.length);
  //     // Print image URLs to the console
  //     for (var url in urls) {
  //       print("temp: $url");
  //     }
  //   } else {
  //     print('Failed to load the page.');
  //   }
  // }

  // test() async{
  //   final url = 'https://bbc.com';  // Replace with your target URL
  //   final response = await http.get(Uri.parse(url));
  //
  //   if (response.statusCode == 200) {
  //     dom.Document document = dom.Document.html(response.body);
  //
  //     final newsCards = document.querySelectorAll('''
  //   [data-testid="dundee-card"],
  //   [data-testid="manchester-card"],
  //   [data-testid="westminster-card"],
  //   'img'
  //   ''');
  //
  //     print('Number of news cards to process: ${newsCards.length}');
  //
  //     List<String> urls = [];
  //
  //     for (final card in newsCards) {
  //       List<dom.Element> imgElements = document.querySelectorAll('img');
  //       List<String> urls = [];
  //
  //       for (var img in imgElements) {
  //         final src = img.attributes['src'];
  //         if (src != null) {
  //           urls.add(src);
  //         }
  //       }
  //     }
  //
  //   }
  // }

  Future<void> fetchImageUrls2() async {
    final url = 'https://bbc.com';  // Replace with your target URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      dom.Document document = dom.Document.html(response.body);

      // Select the specific cards you're interested in
      final newsCards = document.querySelectorAll('''
    [data-testid="dundee-card"],
    [data-testid="manchester-card"],
    [data-testid="westminster-card"],
    ['img']
    ''');

      print('Number of news cards to process: ${newsCards.length}');

      List<String> urls = [];

      for (final card in newsCards) {
        final imageElement = card.querySelector('img');
        String imageUrl = 'No image URL';  // Default fallback

        if (imageElement != null) {
          // Log the raw img element HTML for debugging
          print('Raw image element: ${imageElement.outerHtml}');

          final srcset = imageElement.attributes['srcset'];
          final src = imageElement.attributes['src'];

          // Log the srcset and src attributes
          print('srcset: $srcset');
          print('src: $src');

          // Try extracting the highest resolution image from srcset
          if (srcset != null && srcset.isNotEmpty) {
            final imageUrls = srcset.split(',').map((e) => e.trim().split(' ').first).toList();
            imageUrl = imageUrls.last;  // Pick the highest resolution image
          } else if (src != null && src.isNotEmpty) {
            imageUrl = src;  // Fallback to src if srcset is missing
          }
        }

        // Check if the URL is a relative URL, and if so, resolve it to an absolute one
        if (imageUrl != 'No image URL' && !imageUrl.startsWith('http')) {
          // Assuming the URL is relative, we need to prepend the base URL
          imageUrl = 'https://bbc.com$imageUrl';
        }

        // If the image URL is the placeholder, we replace it
        if (imageUrl.contains('grey-placeholder.png') || imageUrl == 'No image URL') {
          urls.add('No valid image URL');
          print("Image URL is placeholder or not found. Skipping...");
        } else {
          urls.add(imageUrl);  // Add actual image URL
          print("Image URL: $imageUrl");
        }
      }

      // After processing all the cards, print the final URLs
      print('Final list of image URLs:');
      for (var url in urls) {
        print(url);
      }
    } else {
      print('Failed to load the page.');
    }
  }




  @override
  Widget build(BuildContext context) {

    // fetchImageUrls();

    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.asset("assets/images/readeus_text.png",
        width: size.width * .25,
        fit: BoxFit.contain,),
      ),
      body: FutureBuilder<Map<String, List<dynamic>>>(
        future: fetchHeadlines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white,));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!['headlines']!.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          final headlines = snapshot.data!['headlines']!;
          final images = snapshot.data!['images']!;
          final timestamps = snapshot.data!['timestamps'];
          final links = snapshot.data!['articleUrls'];

          return ListView.builder(
            padding: EdgeInsets.all(31),
            itemCount: headlines.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (builder) => NewsDetails(imageURL: images[index], title: headlines[index], link: links![index], timestamp: timestamps[index] ?? "",)));
                  print(links![index]);
                  // selectedNews.value = index;
                  // newsCardClicked.value = true;
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: size.width,
                      height: size.width * .49,
                      margin: EdgeInsets.only(bottom: 11),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(27),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                          loadingBuilder:
                              (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress
                                      .expectedTotalBytes !=
                                      null
                                      ? loadingProgress
                                      .cumulativeBytesLoaded /
                                      loadingProgress
                                          .expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11.0),
                      child: Text(
                        headlines[index],
                        style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 19,
                          color: Colors.white
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 10.0, bottom: 21),
                      child: timestamps![index] == null ? const SizedBox() : 
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: Colors.grey
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Text(" ${timestamps[index]} ",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 12,
                                height: 0),),
                        ),
                      )
                      // Text.rich(TextSpan(children: [
                      //   WidgetSpan(
                      //       child: Icon(
                      //         Icons.category,
                      //         color: Colors.grey,
                      //         size: 19,
                      //       ),
                      //       alignment: PlaceholderAlignment.middle),
                      //   TextSpan(
                      //     text: " ${timestamps[index]}",
                      //     style: TextStyle(
                      //         fontWeight: FontWeight.w900,
                      //         color: Colors.grey,
                      //         fontSize: 12,
                      //         height: 0),
                      //   )
                      // ])),
                    )
                  ],
                ),
              );
              // return ListTile(
              //   leading: images[index].isNotEmpty
              //       ? Image.network(
              //     images[index],
              //     width: 100,
              //     height: 100,
              //     fit: BoxFit.cover,
              //     errorBuilder: (context, error, stackTrace) {
              //       return const Icon(Icons.broken_image);
              //     },
              //   )
              //       : const Icon(Icons.image),
              //   title: Text(headlines[index]),
              //   subtitle: SelectableText('Image URL: ${images[index]}'),
              // );
            },
          );
        },
      ),
    );
  }
}