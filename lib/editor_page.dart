import 'dart:collection';
import 'dart:js_util';
import 'dart:typed_data';

import 'package:dh2vrml_flutter/x3d_preview.dart';
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
  final _editableKey = GlobalKey<EditableState>();

  @override
  void initState() {
    super.initState();
  }

  // TODO: DRY
  String _csvName() {
    return file?.files.single.name ?? "robot.csv";
  }

  String _x3dName() {
    return file?.files.single.name ?? "robot.x3d";
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

  // TODO: DRY?
  void saveCsv() {
    String name = _csvName();
    String? csv = getCsvData();

    if (csv == null) return;

    Uint8List csvData = Uint8List.fromList(csv.codeUnits);
    saveFile(name, csvData);
  }

  void saveX3D() async {
    String name = _x3dName();
    String? x3d = await generateX3D();
    if (x3d == null) return;

    Uint8List x3dData = Uint8List.fromList(x3d.codeUnits);
    saveFile(name, x3dData);
  }

  void previewX3D() async {
    String? x3d = await generateX3D();
    if (x3d == null) return;

    showDialog(context: context, builder: (_) => X3DPreview(x3d));
  }

  void saveFile(String name, Uint8List data) async {
    // ext doesn't seem to do anything?
    await FileSaver.instance.saveFile(name, data, "");
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

  Future<String?> generateX3D() async {
    String? csvData = getCsvData();
    if (csvData == null) return null;
    await promiseToFuture(writePyodideFile(_csvName(), csvData));

    String? modelXML = await promiseToFuture(generateX3DFile(_csvName()));
    return modelXML;
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
                  Wrap(
                    direction: Axis.horizontal,
                    spacing: 20.0,
                    runSpacing: 20.0,
                    children: [
                      ElevatedButton(
                          onPressed: () {}, child: const Text("New File")),
                      ElevatedButton(
                          onPressed: pickFile,
                          child: const Text("Select File")),
                      ElevatedButton(
                          onPressed: saveCsv, child: const Text("Save CSV")),
                      ElevatedButton(
                          onPressed: previewX3D,
                          child: const Text("Preview X3D")),
                      ElevatedButton(
                          onPressed: saveX3D, child: const Text("Export X3D")),
                      Text(file?.files.single.name ?? "No file picked")
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                      height: 1000.0,
                      child: Editable(
                        key: _editableKey, //Assign Key to Widget
                        showCreateButton: true,
                        showRemoveIcon: true,
                        createButtonIcon: const Icon(Icons.add),
                        createButtonColor: Colors.black,
                        columns: cols,
                        rows: rows,
                        zebraStripe: true,
                        stripeColor1: Colors.black12,
                        stripeColor2: Colors.black,
                        borderColor: Colors.blueGrey,
                      )),
                  //const SizedBox(height: 20.0),
                ]))));
  }
}
