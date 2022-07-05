import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import './pull_to_refresh.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:draggable_fab/draggable_fab.dart';

class ScreenerApp extends StatefulWidget {
  final bool debug;
  const ScreenerApp({Key? key, required this.debug}) : super(key: key);

  @override
  State<ScreenerApp> createState() => _ScreenerAppState();
}

class _ScreenerAppState extends State<ScreenerApp> {
  late WebViewController controller;
  final _razorpay = Razorpay();
  var options = {};
  late final String _screenerHomeUrl =
      widget.debug ? "http://10.0.2.2:8000" : "https://www.screener.in";
  late String paymentUrl = "'$_screenerHomeUrl/payment/capture/'";
  late String googleLoginUrl = "'$_screenerHomeUrl/auth/flutter/'";
  late String postParam = "{}";
  late String requestMethod = "'post'";
  late DragGesturePullToRefresh dragGesturePullToRefresh;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late bool googleUser;
  List<String> websites = [];
  @override
  void initState() {
    super.initState();
    dragGesturePullToRefresh = DragGesturePullToRefresh();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void postFunction(postUrl, postParam, requestMethod) {
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

  _paymentBody(paymentId) {
    return {
      'razorpay_payment_id': paymentId,
      'plan_name': options['notes']['plan_name'],
      'currency': options['currency'] == "INR" ? "inr" : 'usd',
      'user_id': options['notes']['user_id'],
    };
  }

  Future<void> _handleSignOut() async {
    if (googleUser) {
      googleUser = false;
      await _googleSignIn.disconnect();
    }
  }

  Future<void> _handleSignIn() async {
    try {
      var user = await _googleSignIn.signIn();
      if (user != null) {
        var authToken = await user.authentication;
        var accessToken = authToken.accessToken;
        googleUser = true;
        postFunction(googleLoginUrl, jsonEncode({'access_token': accessToken}),
            requestMethod);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error occured $error. Please try again later."),
      ));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Map body = _paymentBody(
      response.paymentId,
    );
    postFunction(paymentUrl, jsonEncode(body), requestMethod);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Map body = _paymentBody(
      '',
    );
    postFunction(paymentUrl, jsonEncode(body), requestMethod);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Map body = _paymentBody(
      '',
    );
    postFunction(paymentUrl, jsonEncode(body), requestMethod);
  }

  void didChangeMetrics() {
    // on portrait / landscape or other change, recalculate height
    dragGesturePullToRefresh.setHeight(MediaQuery.of(context).size.height);
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
    const _proxyUserAgent = "random";

    return RefreshIndicator(
      onRefresh: () => dragGesturePullToRefresh.refresh(),
      child: Builder(
        builder: (context) => MaterialApp(
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
                body: WebView(
                  initialUrl: _screenerHomeUrl,
                  javascriptMode: JavascriptMode.unrestricted,
                  gestureRecognizers: {Factory(() => dragGesturePullToRefresh)},
                  userAgent: _proxyUserAgent,
                  onWebViewCreated: (controller) {
                    this.controller = controller;
                    dragGesturePullToRefresh
                        .setContext(context)
                        .setController(controller);
                  },
                  zoomEnabled: false,
                  navigationDelegate: (NavigationRequest request) {
                    if (request.url.endsWith('login/google/')) {
                      _handleSignIn();
                      return NavigationDecision.prevent;
                    } else if (request.url.contains('home')) {
                      _handleSignOut();
                      return NavigationDecision.navigate;
                    } else if (request.url.startsWith(_screenerHomeUrl)) {
                      return NavigationDecision.navigate;
                    } else if (request.url.contains("google")) {
                      return NavigationDecision.navigate;
                    } else {
                      websites.add(request.url);
                      buildSheet(websites);
                      setState(() {});
                      return NavigationDecision.prevent;
                    }
                  },
                  onPageStarted: (String url) {
                    dragGesturePullToRefresh.started();
                  },

                  onPageFinished: (String url) async {
                    if (url.contains("premium")) {
                      await controller.runJavascript("if (document.getElementById('razorpay-info')) {" +
                          "var info = document.getElementById('razorpay-info');" +
                          "btn1 = document.createElement('button');" +
                          "function cloneAttributes(element, sourceNode) { let attr; let attributes = Array.prototype.slice.call(sourceNode.attributes); while(attr =attributes.pop()) {element.setAttribute(attr.nodeName, attr.nodeValue);}};" +
                          "cloneAttributes(btn1, info);" +
                          "info.parentElement.append(btn1);" +
                          "info.style.display = 'none';" +
                          "btn1.innerText='BUY NOW';" +
                          "btn1.addEventListener('click', function() {" +
                          "options = {'key': info.getAttribute('data-key'),'amount': info.getAttribute('data-amount'),'currency': 'INR','name': 'Mittal Analytics (P) Ltd','description': info.getAttribute('data-description')," +
                          "'display_currency': info.getAttribute('data-display_currency'),'display_amount': info.getAttribute('data-display_amount'),'prefill': {'name': info.getAttribute('data-prefill.name')," +
                          "'email': info.getAttribute('data-prefill.email')}," +
                          "'handler': function (response) {var inputs = info.form.elements;for (var i = 0; i < inputs.length; i++) {if (inputs[i].name === 'razorpay_payment_id') {inputs[i].value = response.razorpay_payment_id}};info.form.submit()}," +
                          "'notes': {'plan_name': info.getAttribute('data-notes.plan_name')" +
                          ",'user_id': info.getAttribute('data-notes.user_id')}};RAZORPAY.postMessage(JSON.stringify(options))})}");
                    }
                    dragGesturePullToRefresh.finished();
                  },
                  onWebResourceError: (error) {
                    dragGesturePullToRefresh.finished();
                  },
                  // ignore: prefer_collection_literals
                  javascriptChannels: <JavascriptChannel>[
                    _razorpayChannel(),
                  ].toSet(),
                ),
                floatingActionButton: DraggableFab(
                  child: ElevatedButton(
                    child: Text('WebPage ${websites.length}'),
                    onPressed: () => {
                      showModalBottomSheet(
                          isScrollControlled: true,
                          isDismissible: true,
                          context: context,
                          builder: (context) => buildSheet(websites)),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

_launchURL(String url) async {
  await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
}

Widget buildSheet(websites) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: websites.length,
              itemBuilder: ((context, index) {
                return Container(
                  margin: const EdgeInsets.all(10),
                  height: 200,
                  child: WebView(
                    initialUrl: websites[index],
                    gestureRecognizers: Set()
                      ..add(
                        Factory<VerticalDragGestureRecognizer>(
                          () => VerticalDragGestureRecognizer(),
                        ),
                      ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
