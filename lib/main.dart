// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(ScreenerApp());
}

class ScreenerApp extends StatelessWidget {
  const ScreenerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Screener',
      home: ScreenerHome(),
    );
  }
}

class ScreenerHome extends StatefulWidget {
  const ScreenerHome({Key? key}) : super(key: key);

  @override
  _ScreenerHomeState createState() => _ScreenerHomeState();
}

class _ScreenerHomeState extends State<ScreenerHome> {
  @override
  Widget build(BuildContext context) {
    const _screenerHomeUrl = "https://www.screener.in";
    const _proxyUserAgent =
        "Mozilla/5.0 (Linux; Android 4.1.1; Galaxy Nexus Build/JRO03C) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.166 Mobile Safari/535.19";
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(
            title: const SizedBox(
              height: kToolbarHeight,
            ),
          )),
      body: WebView(
        initialUrl: _screenerHomeUrl,
        javascriptMode: JavascriptMode.unrestricted,
        userAgent: _proxyUserAgent,
      ),
    );
  }
}
