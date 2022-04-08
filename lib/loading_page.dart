import 'package:dh2vrml_flutter/constants.dart';
import 'package:flutter/material.dart';
import 'package:dh2vrml_flutter/dh2vrml_web.dart';
import 'package:dh2vrml_flutter/editor_page.dart';
import 'package:dh2vrml_flutter/navigation.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);
  static const Duration loadDelay = Duration(seconds: 1);

  @override
  State<LoadingPage> createState() => LoadingPageState();
}

class LoadingPageState extends State<LoadingPage> {
  double _progress = 0.0;
  String _msg = "";

  void onLoadProgress(double progress, String msg) {
    setState(() {
      _progress = progress;
      _msg = msg;
    });

    if (progress >= 1.0) {
      Future.delayed(LoadingPage.loadDelay, () {
        navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (_) => const EditorPage()));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initInterop(onLoadProgress);
    initPyodide(dh2vrmlVersion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
          Text(_msg, style: Theme.of(context).textTheme.headline6),
          CircularProgressIndicator(
            value: _progress,
            semanticsLabel: _msg,
          )
        ])));
  }
}
