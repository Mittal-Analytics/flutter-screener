import 'package:flutter/material.dart';
import './checkinternet.dart';
import './webview.dart';

class Splash extends StatefulWidget {
  final bool debug;
  const Splash({Key? key, required this.debug}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

int checkInt = 0;

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future<int> internetState = CheckInternet().checkInternetConnection();
    internetState.then((internetStatus) {
      if (internetStatus == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No internet connection!'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connected to the internet'),
        ));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ScreenerApp(debug: widget.debug)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 44, 42, 42),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/images/circle-icon@144px.png"),
            ]),
      ),
    );
  }
}
