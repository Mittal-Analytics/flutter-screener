import 'package:flutter/material.dart';
import './splash.dart';

void main() {
  runApp(const ScreenerHome());
}

class ScreenerHome extends StatelessWidget {
  const ScreenerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screener',
      home: Splash(debug: true),
      debugShowCheckedModeBanner: false,
    );
  }
}
