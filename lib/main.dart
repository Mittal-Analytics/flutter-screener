import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ScreenerApp());
}

class ScreenerApp extends StatefulWidget {
  const ScreenerApp({Key? key}) : super(key: key);

  @override
  State<ScreenerApp> createState() => _ScreenerAppState();
}

class _ScreenerAppState extends State<ScreenerApp> {
  late WebViewController controller;

  @override
  Widget build(BuildContext context) {
    const _screenerHomeUrl = "https://www.screener.in";
    const _proxyUserAgent =
        "Mozilla/5.0 (Linux; Android 4.1.1; Galaxy Nexus Build/JRO03C) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.166 Mobile Safari/535.19";
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Screener',
        home: WillPopScope(
          onWillPop: () async {
            if (await controller.canGoBack()) {
              controller.goBack();
              return false;
            } else {
              return true;
            }
          },
          child: SafeArea(
            child: Scaffold(
              appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(0),
                  child: AppBar(
                    title: const SizedBox(
                      height: kToolbarHeight,
                    ),
                  )),
              body: WebView(
                initialUrl: _screenerHomeUrl,
                javascriptMode: JavascriptMode.unrestricted,
                // javascriptChannels: <JavascriptChannel>[
                //   _jsFormCallback(context),
                // ].toSet(),
                userAgent: _proxyUserAgent,
                onWebViewCreated: (controller) {
                  this.controller = controller;
                },
                zoomEnabled: false,
                navigationDelegate: (NavigationRequest request) {
                  if (request.url.contains("export")) {
                    var csrfToken = controller.runJavascript(
                        'document.getElementsByName("csrfmiddlewaretoken")[0].value');
                    print(request.url);
                    print(controller.runJavascriptReturningResult(
                        'console.log(document.getElementsByName("csrfmiddlewaretoken")[0].value)'));
                    openFile(url: request.url, fileName: "test.xlsx");
                    return NavigationDecision.navigate;
                  } else if (request.url.startsWith(_screenerHomeUrl)) {
                    return NavigationDecision.navigate;
                  } else if (request.url.contains("google")) {
                    return NavigationDecision.navigate;
                  } else {
                    _launchURL(request.url);
                    return NavigationDecision.prevent;
                  }
                },
              ),
            ),
          ),
        ));
  }
}

JavascriptChannel _jsFormCallback(BuildContext context) {
  return JavascriptChannel(
      name: 'CsrfToken',
      onMessageReceived: (JavascriptMessage message) {
        print(message);
      });
}

Future openFile({required url, required String fileName}) async {
  print(fileName);
  final file = await downloadFile(url, fileName);
  if (file == null) return;
  print('Path: ${file.path}');
  OpenFile.open(file.path);
}

Future<File?> downloadFile(String url, String name) async {
  final appStorage = await getApplicationDocumentsDirectory();
  final file = File('${appStorage.path}/$name');
  print(file);
  try {
    final response = await Dio().post(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        receiveTimeout: 0,
      ),
    );
    print(response);
    final raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(response.data);
    await raf.close();
    return file;
  } catch (e) {
    print(e);
    return null;
  }
}

_launchURL(String url) async {
  await launch(url);
}
