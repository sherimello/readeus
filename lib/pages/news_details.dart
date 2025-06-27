import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:line_icons/line_icons.dart';
import 'package:readeus/pages/news_webview.dart';
import 'package:readeus/widgets/news_details_loading_shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetails extends StatelessWidget {
  final String imageURL, title, link, timestamp;

  const NewsDetails(
      {super.key,
      required this.imageURL,
      required this.title,
      required this.link,
      required this.timestamp});


  Future<String> summarizeNews(String query, bool imageGenerator) async {
    print("------------------------------------------------$imageURL");
    // Replace with your FastAPI server URL
    const baseUrl = 'https://blackbox-cv4y.vercel.app/chat';

    // Construct the URI with query parameters
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'q': query,
        'imageGenerator': imageGenerator.toString(),
      },
    );

    http.Response response; // Declare response variable outside try block

    try {
      // Make the POST request
      response = await http.post(uri);

      // Check for successful status code
      if (response.statusCode == 200) {
        String decodedBody;
        try {
          // **Explicitly decode the response body using UTF-8**
          decodedBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          // Handle potential decoding errors (though less common if server sends valid UTF-8)
          print("UTF-8 Decoding Error: $e");
          print("Raw body bytes (first 100): ${response.bodyBytes.take(100)}");
          throw Exception('Failed to decode server response');
        }

        Map<String, dynamic> responseData;
        try {
          // Parse the correctly decoded JSON string
          responseData = json.decode(decodedBody) as Map<String, dynamic>;
        } on FormatException catch (e) {
          // Handle JSON parsing errors specifically
          print("JSON Parsing Error: $e");
          print("Decoded Body that failed parsing: $decodedBody");
          throw Exception('Failed to parse JSON response from server');
        }

        // Check if the expected 'content' field exists
        if (responseData.containsKey('content')) {
          final content = responseData['content'];
          if (content is String) {
            log("API Response Content: ${content}"); // Log the content
            return content;
          } else {
            // Handle case where 'content' is not a String (e.g., null)
            print("API Error: 'content' field is not a String (was ${content.runtimeType})");
            throw Exception("'content' field in response was not a String");
          }
        } else {
          // Handle case where 'content' field is missing
          print("API Error: 'content' field missing in response data: $responseData");
          throw Exception("'content' field missing in server response");
        }
      } else {
        // Handle non-200 status codes
        print('API Request failed with status: ${response.statusCode}');
        // Log the raw body (even if potentially garbled) for debugging non-200 errors
        try {
          print('Raw Response Body on Error (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
        } catch (_) {
          print('Raw Response Body on Error (${response.statusCode}) could not be UTF-8 decoded: ${response.body}');
        }
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Catch network errors, decoding errors, parsing errors, or other exceptions
      // Rethrow as a clear exception message for the UI/caller
      print("Caught error in sendChatRequest: $e");
      // Avoid rethrowing the exact same exception type if it's already specific enough
      if (e is Exception) {
        rethrow; // Rethrow the specific exception (like the ones thrown above)
      } else {
        throw Exception('An unexpected error occurred during the request: $e');
      }
    }
  }

  getNewsBody() async {
    final url = link;
    String author = "", source = "";
    var copyright = "";
    try {
      // Send the HTTP request to get the HTML content
      final response = await http.get(Uri.parse(url));

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        // Decode response body to handle special characters properly
        String decodedBody = utf8.decode(response.bodyBytes);

        // Parse the HTML content
        var document = dom.Document.html(decodedBody);

        // Extract all <p> elements
        var paragraphs = document.getElementsByTagName('p');

        // Combine all the text content of the <p> elements into a single string
        String combinedText = paragraphs
            .where((e) {
              if (e.text
                  .toLowerCase()
                  .contains(". All rights reserved.".toLowerCase())) {
                copyright = e.text; // Assign copyright
                return false; // Exclude this paragraph
              }
              return true; // Include this paragraph
            })
            .map((e) => e.text)
            .join("\n");
        log(combinedText);
        // final summary = combinedText;
        // final summary = await sendChatRequest(
        //     "summarize the following paragraph and only return the summary without adding anything extra, also make sure it is a plain paragraph: \n${combinedText}",
        //     false);

        final nameElement = document.querySelector('.sc-b42e7a8f-7.kItaYD');

        if (nameElement != null) {
          author = nameElement.text;
        } else {
          author = "";
          // throw Exception('Name element not found');
        }
        final sourceElement =
            document.querySelector('.sc-b42e7a8f-8.bTSIhT span');

        if (sourceElement != null) {
          source = sourceElement.text;
          print("source: $source");
        } else {
          source = "";
          // throw Exception('Name element not found');
        }

        return {
          'body': combinedText,
          'author': author,
          'source': source,
          'copyright': copyright
        };
      } else {
        return 'Failed to load content';
      }
    } catch (e) {
      return 'Error occurred: $e';
    }
  }
  extractArticleParagraphs(String url) async {
    print("cnn news found");
    // Fetch HTML content
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load page: ${response.statusCode}');
    }

    // Parse HTML document
    final document = dom.Document.html(response.body);

    // Find article content container
    final articleContent = document.querySelector('.article__content');
    final sourceContent = document.querySelector('.headline__sub-description');
    final authorContent = document.querySelector('.byline__name');

    print(sourceContent?.innerHtml.trim());
    print(authorContent?.innerHtml.trim());

    if (articleContent == null) {
      print('No article content found');
      return [];
    }

    // Extract all paragraph elements
    final paragraphs = articleContent.querySelectorAll('p');

    String body = "";
    // Process and print paragraphs
    final paragraphTexts = paragraphs.map((p) {
      final text = p.text.trim();
      if (text.isNotEmpty) {
        body += text;
        print(text);
      }
      return text;
    }).toList();

    return {
      'body': body,
      'author': authorContent?.innerHtml.trim(),
      'source': sourceContent?.innerHtml.trim(),
      'copyright': '''© 2025 Cable News Network. A Warner Bros. Discovery Company. All Rights Reserved.
CNN Sans ™ & © 2016 Cable News Network.'''
    };
    return paragraphTexts.where((text) => text.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;

    print(link);

    // sendChatRequest("hello", false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<dynamic>(
              future: link.contains("edition.cnn") ? extractArticleParagraphs(link) : getNewsBody(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Stack(
                    children: [
                      NewsDetailsLoadingShimmer(),
                      const Center(
                          child: CircularProgressIndicator(
                        color: Colors.white,
                      ))
                    ],
                  );
                  // return const Center(child: CircularProgressIndicator(color: Colors.white,));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No data found'));
                }
                if (snapshot.connectionState == ConnectionState.done) {}
                return Padding(
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
                              imageURL,
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
                          title,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                              height: 0,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 21),
                        ),
                        timestamp == ""
                            ? const SizedBox()
                            : Padding(
                                padding:
                                    const EdgeInsets.only(top: 7.0, bottom: 7),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      color: Colors.grey),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(
                                      " $timestamp ",
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
                          "${snapshot.data['author']}",
                          style: TextStyle(
                              color: Colors.white,
                              height: 0,
                              fontWeight: FontWeight.w200,
                              // fontStyle: FontStyle.italic,
                              fontSize: snapshot.data['author'] != "" ? 15 : 0),
                        ),
                        Text(
                          "${snapshot.data['source']}",
                          style: TextStyle(
                              height: 0,
                              color: Colors.white,
                              fontWeight: FontWeight.w200,
                              // fontStyle: FontStyle.italic,
                              fontSize: snapshot.data['source'] != "" ? 15 : 0),
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
                        FutureBuilder<String>(
                          future: summarizeNews(
                              "summarize the following paragraph and only return the summary without adding anything extra, also make sure it is a plain paragraph: \n${snapshot.data["body"]}",
                              false),
                          builder: (constext, snapshot) {
                            String summary = " summarizing...";

                            summary = snapshot.data.toString();

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 355),
                              curve: Curves.easeOut,
                              width: size.width,
                              // height: 31,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(
                                    summary == "null" ? 11 : 31),
                                image: DecorationImage(
                                  opacity: .13,
                                  image: AssetImage(
                                      'assets/images/ai bg grad.gif'),
                                  // Replace with your image path
                                  fit: BoxFit.cover, // Adjust fit as needed
                                ),
                              ),
                              child: AnimatedPadding(
                                duration: const Duration(milliseconds: 355),
                                curve: Curves.easeOut,
                                padding: EdgeInsets.all(
                                    summary == "null" ? 8.0 : 19),
                                child: Text.rich(TextSpan(children: [
                                  WidgetSpan(
                                      child: summary == "null"
                                          ? Image.asset(
                                              "assets/images/ai_loader.gif",
                                              width: size.width * .055,
                                              height: size.width * .055,
                                              color: Colors.white,
                                            )
                                          : const SizedBox(),
                                      alignment: PlaceholderAlignment.middle),
                                  TextSpan(
                                      text: summary == "null"
                                          ? " summarizing..."
                                          : summary,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          height: 0,
                                          fontSize: size.width * .035))
                                ])),
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          height: 21,
                        ),
                        SelectableText(
                          snapshot.data['body'] == null
                              ? ""
                              : "${snapshot.data['body'].toString().replaceAll("Follow:\n", "").replaceAll("\n\n", "\n")}\n\n",
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
                                text: snapshot.data['copyright'] == null
                                    ? ""
                                    : "${snapshot.data['copyright'].toString().replaceAll("\n\n", "\n")}\n\n",
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
                );
              }),
          Container(
            width: size.width,
            height: appBarHeight + topPadding,
            decoration: BoxDecoration(color: Colors.black),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: appBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        print("object");
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22.0),
                          child: Icon(
                            CupertinoIcons.back,
                            color: Colors.white,
                            size: 31,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 31.0),
                      child: GestureDetector(
                        onTap: () async {
                          final Uri uri = Uri.parse(link);
                          if (!await launchUrl(uri,
                              mode: LaunchMode.externalApplication)) {
                            throw Exception('Could not launch $link');
                          }
                          // Get.to(NewsWebview(url: link));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.white),
                          child: Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.link,
                                  color: Colors.black,
                                  opticalSize: 17,
                                  size: 17,
                                ),
                                // Text(
                                //   " open news",
                                //   style: TextStyle(
                                //       color: Colors.black,
                                //       fontSize: 12,
                                //       fontWeight: FontWeight.w900),
                                // )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
