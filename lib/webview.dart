import 'dart:typed_data';

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
  late String postUrl = "'https://jsonplaceholder.typicode.com/posts'";
  late String postParam = "{}";
  late String requestMethod = "'post'";
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

  void jsFunction(postUrl, postParam, requestMethod) {
    postUrl = "'http://10.0.2.2:8000/payment/capture/'";
    // postParam =
    //     "{razorpay_payment_id: '12456', plan_name:'kavi', currency: 'inr', user_id:'1'}";
    postParam = "$postParam";
    requestMethod = "'post'";
    controller.runJavascript("function post(path, params, method='post') {" +
        "const form = document.createElement('form');" +
        "form.method = method;" +
        "form.action = path;" +
        "for (const key in params) {" +
        "if (params.hasOwnProperty(key)) {" +
        "const hiddenField = document.createElement('input');" +
        "hiddenField.type = 'hidden';" +
        "hiddenField.name = key;" +
        "hiddenField.value = params[key];" +
        "form.appendChild(hiddenField);}}document.body.appendChild(form);form.submit();}" +
        "post($postUrl, $postParam, method=$requestMethod)");
  }

  Future<void> _postPayment(body) async {
    var url = Uri.parse("http://10.0.2.2:8000/payment/capture/");
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Map body = {
      'razorpay_payment_id': response.paymentId,
      'plan_name': options['notes']['plan_name'],
      'currency': options['currency'] == "INR" ? "inr" : 'usd',
      'user_id': options['notes']['user_id'],
    };
    jsFunction("/payment/capture", jsonEncode(body), requestMethod);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Map body = {
      'razorpay_payment_id': '',
      'plan_name': options['notes']['plan_name'],
      'currency': options['currency'] == "INR" ? "inr" : 'usd',
      'user_id': options['notes']['user_id'],
    };
    _postPayment(body);
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
                  if (url.contains('premium')) {
                    await controller.runJavascript("if (document.getElementById('razorpay-info'))" +
                        "{var info = document.getElementById('razorpay-info'); btn1 = document.createElement('button');" +
                        "function cloneAttributes(element, sourceNode) { let attr; let attributes = Array.prototype.slice.call(sourceNode.attributes); while(attr =attributes.pop()) {element.setAttribute(attr.nodeName, attr.nodeValue);}};" +
                        "cloneAttributes(btn1, info); info.parentElement.append(btn1);info.style.display = 'none'; btn1.innerText='BUY NOW';" +
                        "btn1.addEventListener('click', function() {options = {'key': info.getAttribute('data-key'),'amount': info.getAttribute('data-amount'),'currency': 'INR','name': 'Mittal Analytics (P) Ltd','description': info.getAttribute('data-description')," +
                        "'display_currency': info.getAttribute('data-display_currency'),'display_amount': info.getAttribute('data-display_amount'),'prefill': {'name': info.getAttribute('data-prefill.name'),'email': info.getAttribute('data-prefill.email')}," +
                        "'handler': function (response) {var inputs = info.form.elements;for (var i = 0; i < inputs.length; i++) {if (inputs[i].name === 'razorpay_payment_id') {inputs[i].value = response.razorpay_payment_id}};info.form.submit()},'notes': {'plan_name': info.getAttribute('data-notes.plan_name')" +
                        ",'user_id': info.getAttribute('data-notes.user_id')}};RAZORPAY.postMessage(JSON.stringify(options))})}");
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
