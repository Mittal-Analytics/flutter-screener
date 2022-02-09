import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  await FlutterDownloader.initialize(debug: true);
  // set true to enable printing logs to console
  await Permission.storage.request();
  await Permission.mediaLibrary.request();
  // ask for storage permission on app create
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
              body: HomePage(),
            ),
          ),
        ));
  }
}

_launchURL(String url) async {
  await launch(url);
}
