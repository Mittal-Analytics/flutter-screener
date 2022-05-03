import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScreenerApp extends StatefulWidget {
  const ScreenerApp({Key? key}) : super(key: key);

  @override
  State<ScreenerApp> createState() => _ScreenerAppState();
}

class _ScreenerAppState extends State<ScreenerApp> {
  late WebViewController controller;
  final _razorpay = Razorpay();
  var options = {};
  late bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  Future<void> _postPayment(url, body) async {
    setState(() {
      isLoading = true;
    });
    var response = await http.post(url, body: body);
    await controller.loadUrl('http://10.0.2.2:8000/premium/member/');
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    var url = Uri.parse("http://10.0.2.2:8000/payment/capture/");
    Map body = {
      'razorpay_payment_id': response.paymentId,
      'plan_name': options['notes']['plan_name'],
      'currency': options['currency'] == "INR" ? "inr" : 'usd',
      'user_id': options['notes']['user_id'],
    };
    _postPayment(url, body);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Error Response: $response');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External SDK Response: $response');
  }

  JavascriptChannel _razorpayChannel() {
    return JavascriptChannel(
        name: 'RAZORPAY',
        onMessageReceived: (JavascriptMessage message) async {
          options = jsonDecode(message.message);
          _razorpay.open(jsonDecode(message.message));
        });
  }

  @override
  Widget build(BuildContext context) {
    const _screenerHomeUrl = "http://10.0.2.2:8000";
    const _proxyUserAgent = "random";
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
            body: Stack(children: <Widget>[
              WebView(
                initialUrl: _screenerHomeUrl,
                javascriptMode: JavascriptMode.unrestricted,
                userAgent: _proxyUserAgent,
                onWebViewCreated: (controller) {
                  this.controller = controller;
                },
                zoomEnabled: false,
                navigationDelegate: (NavigationRequest request) {
                  if (request.url.contains('premium')) {
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
                onPageFinished: (String url) async {
                  if (url.endsWith('premium/member/')) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                  if (url.contains('premium')) {
                    await controller.runJavascript(
                        "if (document.getElementById('razorpay-info')){var info = document.getElementById('razorpay-info'); btn1 = document.createElement('button');function cloneAttributes(element, sourceNode) { let attr; let attributes = Array.prototype.slice.call(sourceNode.attributes); while(attr =attributes.pop()) {element.setAttribute(attr.nodeName, attr.nodeValue);}};cloneAttributes(btn1, info); info.parentElement.append(btn1);info.style.display = 'none'; btn1.innerText='BUY NOW';btn1.addEventListener('click', function() {options = {'key': info.getAttribute('data-key'),'amount': info.getAttribute('data-amount'),'currency': 'INR','name': 'Mittal Analytics (P) Ltd','description': info.getAttribute('data-description'),'display_currency': info.getAttribute('data-display_currency'),'display_amount': info.getAttribute('data-display_amount'),'prefill': {'name': info.getAttribute('data-prefill.name'),'email': info.getAttribute('data-prefill.email')},'handler': function (response) {var inputs = info.form.elements;for (var i = 0; i < inputs.length; i++) {if (inputs[i].name === 'razorpay_payment_id') {inputs[i].value = response.razorpay_payment_id}};info.form.submit()},'notes': {'plan_name': info.getAttribute('data-notes.plan_name'),'user_id': info.getAttribute('data-notes.user_id')}};RAZORPAY.postMessage(JSON.stringify(options))})}");
                  }
                },
                // ignore: prefer_collection_literals
                javascriptChannels: <JavascriptChannel>[
                  _razorpayChannel(),
                ].toSet(),
              ),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(),
            ]),
          ),
        ),
      ),
    );
  }
}

_launchURL(String url) async {
  await launch(url);
}
