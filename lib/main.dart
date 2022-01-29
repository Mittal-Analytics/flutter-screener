// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(ScreenerWebView());

class ScreenerWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Screener',
      home: Scaffold(
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: AppBar(
              // ignore: prefer_const_constructors
              title: SizedBox(
                height: kToolbarHeight,
              ),
            )),
        // ignore: prefer_const_constructors
        body: WebView(
          initialUrl: "https://www.screener.in/",
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    );
  }
}
