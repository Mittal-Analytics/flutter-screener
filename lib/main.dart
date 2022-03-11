import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart' hide CookieManager;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );
  runApp(const ScreenerApp());
}

class ScreenerApp extends StatefulWidget {
  const ScreenerApp({Key? key}) : super(key: key);

  @override
  State<ScreenerApp> createState() => _ScreenerAppState();
}

class _ScreenerAppState extends State<ScreenerApp> {
  late WebViewController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ReceivePort _port = ReceivePort();
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (status.toString() == "DownloadTaskStatus(3)" &&
          progress == 100 &&
          id != null) {
        String query = "SELECT * FROM task WHERE task_id='" + id + "'";
        var tasks = await FlutterDownloader.loadTasksWithRawQuery(query: query);
        //if the task exists, open it
        // FlutterDownloader.open(taskId: id);
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  Future<String?> _findLocalPath() async {
    String? externalStorageDirPath;
    if (Platform.isAndroid) {
      try {
        externalStorageDirPath =
            '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}Download';
        final savedDir = Directory(externalStorageDirPath);
        bool hasExisted = await savedDir.exists();
        if (!hasExisted) {
          savedDir.create();
        }
      } catch (e) {
        final directory = await getExternalStorageDirectory();
        externalStorageDirPath = directory?.path;
      }
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }
    return externalStorageDirPath;
  }

  var cookieString;

  @override
  Widget build(BuildContext context) {
    const _screenerHomeUrl = "https://www.screener.in";
    const _proxyUserAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36";
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
              body: InAppWebView(
                initialUrlRequest: URLRequest(url: Uri.parse(_screenerHomeUrl)),
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    useOnDownloadStart: true,
                    useShouldOverrideUrlLoading: true,
                    useShouldInterceptFetchRequest: true,
                    useOnLoadResource: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    useShouldInterceptAjaxRequest: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    // useShouldInterceptAjaxRequest: true,
                  ),
                  android: AndroidInAppWebViewOptions(
                    useShouldInterceptRequest: true,
                    saveFormData: true,
                    allowContentAccess: true,
                    allowFileAccess: true,
                    mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                    thirdPartyCookiesEnabled: true,
                    supportMultipleWindows: true,
                  ),
                ),
                shouldInterceptFetchRequest: (controller, fetchRequest) {
                  return Future.value(fetchRequest);
                },
                onCreateWindow: (controller, createWindowAction) {
                  return Future.value(false);
                },
                onLoadResource: (controller, resource) {
                  print(resource);
                },
                shouldInterceptAjaxRequest: (controller, ajaxRequest) {
                  return Future.value(ajaxRequest);
                },
                shouldOverrideUrlLoading: (controller, navigationAction) {
                  return Future.value(NavigationActionPolicy.ALLOW);
                },
                onLoadStop: (controller, url) async {
                  if (url != null) {
                    await updateCookies(url);
                  }
                },
                onDownloadStart: (controller, url, userAgent,
                    contentDisposition, mimeType, contentLength) async {
                  void _download(String url) async {
                    final status = await Permission.storage.request();

                    if (status.isGranted) {
                      String? localPath = await _findLocalPath();
                      final id = await FlutterDownloader.enqueue(
                        url: url,
                        savedDir: localPath!,
                        showNotification: true,
                        headers: {
                          HttpHeaders.cookieHeader: cookieString,
                          HttpHeaders.contentTypeHeader: mimeType,
                          HttpHeaders.connectionHeader: 'keep-alive',
                          // 'Content-Length': contentLength.toString(),
                          // 'User-Agent': userAgent
                        },
                        fileName: 'demo.xlsx',
                        saveInPublicStorage: true,
                        openFileFromNotification: true,
                      );
                    } else {
                      print('Permission Denied');
                    }
                  }

                  _download(_screenerHomeUrl + url.path);
                },
              ),
            ),
          ),
        ));
  }

  Future<void> updateCookies(Uri url) async {
    var cookies = await CookieManager().getCookies(url: url);
    cookieString = "";
    for (var cookie in cookies) {
      cookieString += cookie.name + "=" + cookie.value;
      if (cookies.indexOf(cookie) != cookies.length - 1) {
        cookieString += "; ";
      }
    }
  }
}
