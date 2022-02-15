import 'package:flutter/material.dart';
import './checkinternet.dart';
import './webview.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

int checkInt = 0;

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future<int> a = CheckInternet().checkInternetConnection();
    a.then((value) {
      if (value == 0) {
        setState(() {
          checkInt = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No internet connection!'),
        ));
      } else {
        setState(() {
          checkInt = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connected to the internet'),
        ));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const ScreenerApp()));
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
              const Text(
                "Checking Network",
                textScaleFactor: 2,
                style: TextStyle(color: Colors.white),
              ),
            ]),
      ),
    );
  }
}
