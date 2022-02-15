import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import './splash.dart';
import './webview.dart';

void main() {
  runApp(const ScreenerHome());
}

class ScreenerHome extends StatelessWidget {
  const ScreenerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screener',
      home: Splash(),
      debugShowCheckedModeBanner: false,
    );
  }
}
