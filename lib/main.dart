import 'package:flutter/material.dart';
import './splash.dart';

void main() {
  runApp(const ScreenerHome());
}

class ScreenerHome extends StatelessWidget {
  const ScreenerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Screener',
      home: Splash(debug: false),
      debugShowCheckedModeBanner: false,
    );
  }
}
