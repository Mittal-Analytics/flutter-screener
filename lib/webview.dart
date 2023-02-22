import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
// #docregion platform_imports
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

class ScreenerApp extends StatefulWidget {
  final bool debug;
  const ScreenerApp({Key? key, required this.debug}) : super(key: key);

  @override
  State<ScreenerApp> createState() => _ScreenerAppState();
}

class _ScreenerAppState extends State<ScreenerApp> with WidgetsBindingObserver {
  late WebViewController _controller;
  final _razorpay = Razorpay();
  var options = {};
  late final String _screenerHomeUrl =
      widget.debug ? "http://10.0.2.2:8000" : "https://www.screener.in";
  late String paymentUrl = "'$_screenerHomeUrl/payment/capture/'";
  late String googleLoginUrl = "'$_screenerHomeUrl/auth/flutter/'";
  late String postParam = "{}";
  late String requestMethod = "'post'";
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late bool googleUser;
  var _lightMode = true;
  var _currentcompany = '';
  @override
  void initState() {
    super.initState();
    //RazorPay settings
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    //Webview Controller
    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
                Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onPageStarted: (String url) async {
            if (url.contains('screener')) {
              await controller.runJavaScript(
                  "if(document.querySelectorAll('.top-nav-holder')){"
                  "const topNavHolders = document.querySelectorAll('.top-nav-holder');"
                  "for (let i = 0; i < topNavHolders.length; i++) {"
                  "  topNavHolders[i].style.display = 'none';}}");
              await controller.runJavaScript(
                  'document.querySelector(\'button[onclick="SetTheme(\\\'light\\\')"]\').onclick = function() {window.MODES.postMessage(\'light\'); SetTheme(\'light\');};');
              await controller.runJavaScript(
                  'document.querySelector(\'button[onclick="SetTheme(\\\'dark\\\')"]\').onclick = function() {window.MODES.postMessage(\'dark\'); SetTheme(\'dark\');};');
              await controller.runJavaScript('let title = document.title;'
                  'let index = title.indexOf(" Ltd");'
                  'let companyName = title.substring(0, index + 4);'
                  'CompanyName.postMessage(companyName)');
            }
          },
          onPageFinished: (String url) async {
            if (url.contains('screener')) {
              await controller.runJavaScript(
                  "if(document.querySelectorAll('.top-nav-holder')){"
                  "const topNavHolders = document.querySelectorAll('.top-nav-holder');"
                  "for (let i = 0; i < topNavHolders.length; i++) {"
                  "  topNavHolders[i].style.display = 'none';}}");
              await controller.runJavaScript(
                  'document.querySelector(\'button[onclick="SetTheme(\\\'light\\\')"]\').onclick = function() {window.MODES.postMessage(\'light\'); SetTheme(\'light\');};');
              await controller.runJavaScript(
                  'document.querySelector(\'button[onclick="SetTheme(\\\'dark\\\')"]\').onclick = function() {window.MODES.postMessage(\'dark\'); SetTheme(\'dark\');};');
            }
            if (url.contains("premium")) {
              await controller.runJavaScript("if (document.getElementById('razorpay-info')) {" +
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
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.endsWith('login/google/')) {
              _handleSignIn();
              return NavigationDecision.prevent;
            } else if (request.url.contains('export')) {
              downloadFile(request.url, _currentcompany);
              return NavigationDecision.prevent;
            } else if (request.url.contains('home')) {
              _handleSignOut();
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
        ),
      )
      //RazorPay channel
      ..addJavaScriptChannel(
        'RAZORPAY',
        onMessageReceived: (JavaScriptMessage message) async {
          options = jsonDecode(message.message);
          _razorpay.open(jsonDecode(message.message));
        },
      )
      // Managing Light-Dark Modes
      ..addJavaScriptChannel(
        'MODES',
        onMessageReceived: (JavaScriptMessage message) async {
          if (message.message == "light") {
            setState(() {
              _lightMode = true;
            });
          }
          if (message.message == "dark") {
            setState(() {
              _lightMode = false;
            });
          }
        },
      )
      ..addJavaScriptChannel('CompanyName',
          onMessageReceived: (JavaScriptMessage message) async {
        setState(() {
          _currentcompany = message.message;
        });
      })
      ..enableZoom(false)
      ..setUserAgent("random")
      ..loadRequest(Uri.parse(_screenerHomeUrl));
    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features
    _controller = controller;
    // Refresh whenever the app is resumed from the background
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _controller.reload();
    }
  }

  void postFunction(postUrl, postParam, requestMethod) {
    postParam = "$postParam";
    requestMethod = "'post'";
    _controller.runJavaScript("function post(path, params, method='post') {" +
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error occured $error. Please try again later."),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Screener',
        home: WillPopScope(
          onWillPop: () async {
            if (await _controller.canGoBack()) {
              _controller.goBack();
              return false;
            } else {
              return true;
            }
          },
          child: SafeArea(
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: SizedBox(
                  height: 150,
                  width: 150,
                  child: SvgPicture.asset(
                    'assets/images/screener-logo.svg',
                    colorFilter: _lightMode
                        ? null
                        : const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
                elevation: 0,
                backgroundColor: _lightMode
                    ? Colors.white
                    : const Color.fromARGB(255, 24, 34, 48),
                actions: [
                  IconButton(
                    onPressed: () => _controller.reload(),
                    icon: Icon(
                      Icons.replay,
                      color: _lightMode ? Colors.black : Colors.white,
                    ),
                  )
                ],
              ),
              body: WebViewWidget(
                controller: _controller,
              ),
              // floatingActionButton:
              //     const FloatingActionButton(onPressed: downloadFile),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> downloadFile(String url, String name) async {
  final response = await http.post(Uri.parse(url));
  final bytes = response.bodyBytes;
  var status = await Permission.storage.request();
  if (status != PermissionStatus.granted) {
    throw Exception('Permission denied to write to storage');
  }
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  if (selectedDirectory != null) {
    final file = File('$selectedDirectory/$name.xlsx');
    await file.writeAsBytes(bytes);
  }
}

_launchURL(String url) async {
  await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
}
