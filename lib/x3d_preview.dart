import 'dart:convert';
import 'dart:html';

import 'package:easy_web_view2/easy_web_view2.dart';
import 'package:flutter/material.dart';

class X3DPreview extends StatelessWidget {
  final String model;
  final ValueKey previewKey = const ValueKey('previewKey');

  const X3DPreview(this.model, {Key? key}) : super(key: key);

  String _htmlSrc() {
    //TODO: ExamineMode and ViewPoint seems to break things, remove
    LineSplitter ls = LineSplitter();
    List<String> lines = ls.convert(model);
    lines.removeWhere((String line) {
      if (line.toUpperCase().contains("EXAMINEMODE") ||
          line.toUpperCase().contains("VIEWPOINT")) {
        return true;
      }
      return false;
    });
    String _model = lines.join('\n');

    // TODO: fullscreen css doesn't really work properly.
    String htmlSrc = """
    <html>
      <head>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <script type='text/javascript' src='https://x3dom.org/release/x3dom-full.js'> </script> 
        <link rel='stylesheet' type='text/css' href='https://www.x3dom.org/download/x3dom.css'></link> 
        <link rel='stylesheet' type='text/css' href='x3dfullscreen.css'></link> 
      </head>
      <body>
        $_model
      </body>
    </html>
      """;
    return htmlSrc;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("X3D Preview"),
      content: EasyWebView(
        key: previewKey,
        src: _htmlSrc(),
        onLoaded: () {},
        isHtml: true,
        isMarkdown: false,
        convertToWidgets: false,
        widgetsTextSelectable: false,
        webNavigationDelegate: (_) => WebNavigationDecision.prevent,
        crossWindowEvents: const [],
        width: 1000.0,
        height: 600.0,
      ),
    );
  }
}
