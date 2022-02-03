import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ScreenerApp());
}

class ScreenerApp extends StatelessWidget {
  const ScreenerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const _appTitle = "Screener";
    return const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: _appTitle,
        home: ScreenerHome(),
    );
  }
}

class ScreenerHome extends StatelessWidget {
  const ScreenerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            title: const SizedBox(
              height: kToolbarHeight,
            ),
          )),
      body: const ScreenerWebView(),
    );
  }
}

class ScreenerWebView extends StatelessWidget {
  const ScreenerWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const _screenerHomeUrl = "https://www.screener.in";
    const _proxyUserAgent =
        "Mozilla/5.0 (Linux; Android 4.1.1; Galaxy Nexus Build/JRO03C) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.166 Mobile Safari/535.19";
    return WebView(
      initialUrl: _screenerHomeUrl,
      javascriptMode: JavascriptMode.unrestricted,
      userAgent: _proxyUserAgent,
      navigationDelegate: (NavigationRequest request) {
        if (request.url.startsWith(_screenerHomeUrl)) {
          return NavigationDecision.navigate;
        } else {
          _launchURL(request.url);
          return NavigationDecision.prevent;
        }
      },
    );
  }
}

_launchURL(String url) async {
  await launch(url);
}
