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
import 'package:url_launcher/url_launcher.dart';

class NewsDetails extends StatelessWidget {
  final String imageURL, title, link, timestamp;

  const NewsDetails(
      {super.key,
      required this.imageURL,
      required this.title,
      required this.link,
      required this.timestamp});

  Future<String> chatRequest(String query, bool imageGenerator) async {
    const String apiUrl = 'https://blackbox-cv4y.vercel.app/chat?'; // Replace with your actual FastAPI URL

    final Map<String, dynamic> payload = {
      "q": query,
      "imageGenerator": imageGenerator
    };

    final headers = {
      "Content-Type": "application/json",
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/133.0.0.0 Safari/537.36",
      "Accept": "*/*",
      "DNT": "1",
      "Origin": "https://www.blackbox.ai",
      "Referer": "https://www.blackbox.ai/"
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData["content"] ?? "No content available";
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error occurred: $error');
    }
  }

  Future<String> callChatApi(String question, bool imageGenerator) async {
    final url = Uri.parse('https://blackbox-cv4y.vercel.app/chat'); // Replace with your FastAPI URL

    final payload = {
      "messages": [
        {"id": "6kXJ4t8", "content": question, "role": "user"}
      ],
      "agentMode": {},
      "id": "6kXJ4t8",
      "previewToken": null,
      "userId": '7f26c6a7-c1d2-4216-abb4-0681912ea0a5',
      "codeModelMode": false,
      "trendingAgentMode": {},
      "isMicMode": false,
      "userSystemPrompt": null,
      "maxTokens": 2048,
      "playgroundTopP": null,
      "playgroundTemperature": null,
      "isChromeExt": false,
      "githubToken": "",
      "clickedAnswer2": false,
      "clickedAnswer3": false,
      "clickedForceWebSearch": false,
      "visitFromDelta": false,
      "isMemoryEnabled": true,
      "mobileClient": true,
      "userSelectedModel": "@2",
      "validated": "00f37b34-a166-4efb-bce5-1312d87f2f94",
      "imageGenerationMode": imageGenerator,
      "webSearchModePrompt": false,
      "deepSearchMode": false,
      "domains": null,
      "vscodeClient": false,
      "codeInterpreterMode": false,
      "customProfile": {
        "name": "",
        "occupation": "",
        "traits": [],
        "additionalInfo": "",
        "enableNewChats": true
      },
      "session": {
        "user": {
          "name": "shahriar rahman",
          "email": "shahriarr.inan@gmail.com",
          "image": "https://lh3.googleusercontent.com/a/ACg8ocLeF2SJqSX7FnAH7RpYMKQ1lrta37sGpzYl4eawbOM_JbqbqQ=s96-c"
        },
        "expires": "2025-03-30T11:02:54.764Z"
      },
      "isPremium": true,
      "subscriptionCache": {
        "status": "PREMIUM",
        "expiryTimestamp": null,
        "lastChecked": 1740740574503
      },
      "beastMode": false
    };

    final headers = {
      'Content-Type': 'application/json',
      'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
      'accept': '*/*',
      'accept-language': 'en-US,en;q=0.9,ar-JO;q=0.8,ar;q=0.7,bn;q=0.6',
      'dnt': '1',
      'origin': 'https://www.blackbox.ai',
      'referer': 'https://www.blackbox.ai/'
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse['content']; // Return only the content
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> sendChatRequest(String query, bool imageGenerator) async {
    try {
      // Replace with your FastAPI server URL
      const baseUrl = 'https://blackbox-cv4y.vercel.app/chat';

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'q': query,
          'imageGenerator': imageGenerator.toString(),
        },
      );

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        if (responseData.containsKey('content')) {
          print("summmmmmm: " + responseData['content'] as String);
          return responseData['content'] as String;
        } else {
          throw Exception('Content field missing in response');
        }
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } on FormatException {
      throw Exception('Failed to parse JSON response');
    } catch (e) {
      throw Exception('Request error: $e');
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
              if (e.text.contains(". All rights reserved.")) {
                copyright = e.text; // Assign copyright
                return false; // Exclude this paragraph
              }
              return true; // Include this paragraph
            })
            .map((e) => e.text)
            .join("\n");
        log(combinedText);
        // final summary = combinedText;
        final summary = await sendChatRequest("summarize the following paragraph and only return the summary without adding annything extra: \n${combinedText}", false);

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
          'body': summary,
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

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;

    // sendChatRequest("hello", false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<dynamic>(
              future: getNewsBody(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white,));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No data found'));
                }
                if(snapshot.connectionState == ConnectionState.done) {

                }
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
                                padding: const EdgeInsets.only(top: 7.0, bottom: 7),
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
                        SelectableText(
                          snapshot.data['body'] == null
                              ? ""
                              : "${snapshot.data['body'].toString().replaceAll("\n\n", "\n")}\n\n",
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
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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
