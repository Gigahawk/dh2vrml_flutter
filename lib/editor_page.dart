import 'dart:collection';
import 'dart:js_util';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:editable/editable.dart';
import 'package:easy_web_view2/easy_web_view2.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:dh2vrml_flutter/dh2vrml_web.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  FilePickerResult? file;
  static ValueKey key = ValueKey('key_0');
  final _editableKey = GlobalKey<EditableState>();

  @override
  void initState() {
    super.initState();
  }

  String _csvName() {
    return file?.files.single.name ?? "robot.csv";
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ["yaml", "yml", "py", "csv"]);

    if (result != null) {
      setState(() {
        file = result;
      });
    }
  }

  void saveFile() async {
    String name = _csvName();
    String? csv = getCsvData();
    if (csv == null) {
      return;
    }
    Uint8List csvBytes = Uint8List.fromList(csv.codeUnits);

    // ext doesn't seem to do anything?
    await FileSaver.instance.saveFile(name, csvBytes, "");
  }

  String? getCsvData() {
    List<dynamic>? currCols = _editableKey.currentState?.columns;
    List<dynamic>? currRows = _editableKey.currentState?.rows;
    if (currRows == null || currCols == null) {
      return null;
    }
    List<String> csvHeader =
        currCols.map((element) => element['key'] as String).toList();
    List<List<String>> csvRows = currRows.map((row) {
      return csvHeader.map((key) {
        return row[key] as String;
      }).toList();
    }).toList();

    csvRows.insert(0, csvHeader);

    String csv = const ListToCsvConverter().convert(csvRows);
    return csv;
  }

  void generateX3D() async {
    String? csvData = getCsvData();
    if (csvData == null) {
      return;
    }
    String output =
        await promiseToFuture(writePyodideFile(_csvName(), csvData));
    print(output);
  }

  List cols = [
    {"title": 'Joint Type', 'widthFactor': 0.15, 'key': 'type'},
    {"title": 'd', 'widthFactor': 0.10, 'key': 'd'},
    {"title": 'theta', 'widthFactor': 0.10, 'key': 'theta'},
    {"title": 'r', 'widthFactor': 0.10, 'key': 'r'},
    {"title": 'alpha', 'widthFactor': 0.10, 'key': 'alpha'},
    {"title": 'Color', 'widthFactor': 0.15, 'key': 'color'},
    {"title": 'Scale', 'widthFactor': 0.10, 'key': 'scale'},
    {"title": 'Offset', 'widthFactor': 0.15, 'key': 'offset'},
  ];

  List rows = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('dh2vrml for web')),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: () {}, child: const Text("New File")),
                      const SizedBox(width: 20.0),
                      ElevatedButton(
                          onPressed: pickFile,
                          child: const Text("Select File")),
                      const SizedBox(width: 20.0),
                      ElevatedButton(
                          onPressed: saveFile, child: const Text("Save CSV")),
                      const SizedBox(width: 20.0),
                      ElevatedButton(
                          onPressed: generateX3D,
                          child: const Text("Export X3D")),
                      const SizedBox(width: 20.0),
                      Text(file?.files.single.name ?? "No file picked")
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                      height: 1000.0,
                      child: Editable(
                        key: _editableKey, //Assign Key to Widget
                        showCreateButton: true,
                        createButtonIcon: const Icon(Icons.add),
                        createButtonColor: Colors.black,
                        columns: cols,
                        rows: rows,
                        zebraStripe: true,
                        stripeColor1: Colors.black12,
                        stripeColor2: Colors.black,
                        borderColor: Colors.blueGrey,
                      )),
                  const SizedBox(height: 20.0),
                  EasyWebView(
                    key: key,
                    src: htmlSrc,
                    onLoaded: () {},
                    isHtml: true,
                    isMarkdown: false,
                    convertToWidgets: false,
                    //key: key,
                    widgetsTextSelectable: false,
                    webNavigationDelegate: (_) => WebNavigationDecision.prevent,
                    crossWindowEvents: [
                      CrossWindowEvent(
                          name: 'Test',
                          eventAction: (eventMessage) {
                            print('Event message: $eventMessage');
                          }),
                    ],
                    // width: 100,
                    height: 1000.0,
                  ),
                ]))));
  }

  String htmlSrc = """
   <head>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/> 
     <title>My first X3DOM page</title> 
     <script type='text/javascript' src='https://www.x3dom.org/download/x3dom.js'> </script> 
     <link rel='stylesheet' type='text/css' href='https://www.x3dom.org/download/x3dom.css'></link> 
   </head> 
   <body> 
     <h1>Hello, X3DOM!</h1> 
     <p> 
       This is my first html page with some 3d objects. 
     </p> 
	 <x3d width='500px' height='400px'> 
	   <scene> 
		<shape> 
		   <appearance> 
			 <material diffuseColor='1 0 0'></material> 
		   </appearance> 
		   <box></box> 
		</shape> 
		<transform translation='-3 0 0'> 
		  <shape> 
			 <appearance> 
			   <material diffuseColor='0 1 0'></material> 
			 </appearance> 
			 <cone></cone> 
		  </shape> 
		</transform> 
		<transform translation='3 0 0'> 
		  <shape> 
			 <appearance> 
			   <material diffuseColor='0 0 1'></material> 
			 </appearance> 
			 <sphere></sphere> 
		  </shape> 
		</transform> 
	   </scene> 
	</x3d> 
   </body> 
</html> 

    """;
}
