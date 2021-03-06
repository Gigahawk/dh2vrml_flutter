import 'dart:convert';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dh2vrml_flutter/constants.dart';
import 'package:file/memory.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:dh2vrml_flutter/name_setter.dart';
import 'package:dh2vrml_flutter/x3d_preview.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:editable/editable.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:dh2vrml_flutter/dh2vrml_web.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  PlatformFile? file;
  final GlobalKey<EditableState> _editableKey = GlobalKey<EditableState>();
  Widget? table;
  TextEditingController tc = TextEditingController(text: "robot");
  String get name => tc.text;
  final ValueNotifier<bool> useDegreesController = ValueNotifier<bool>(false);
  final ValueNotifier<bool> generateSimulinkController =
      ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    setupDegreesNotification();
  }

  void setupDegreesNotification() {
    useDegreesController.addListener(() {
      switchTableUnits(useDegreesController.value);
    });
  }

  void switchTableUnits(bool toDegrees) {
    switchColUnits(toDegrees, "theta");
    switchColUnits(toDegrees, "alpha");
    setState(() {});
  }

  void switchColUnits(bool toDegrees, String col) {
    double conversion = 180.0 / pi;
    for (var i = 0; i < rows.length; i++) {
      try {
        String? s = rows[i][col];
        if (s == null) continue;
        double value = double.parse(s);
        if (toDegrees) {
          value *= conversion;
        } else {
          value /= conversion;
        }
        rows[i][col] = value.toString();
      } catch (_) {
        continue;
      }
    }
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ["yaml", "yml", "py", "csv"]);
    bool restoreUseDegrees = useDegreesController.value;

    if (result == null) return;
    useDegreesController.value = false;

    PlatformFile file = result.files.single;
    await setTable(file);
    setState(() {
      tc.text = file.name.split(".")[0];
      useDegreesController.value = restoreUseDegrees;
    });
  }

  Future<void> setTable(PlatformFile file) async {
    String csvData = utf8.decode(file.bytes as List<int>);
    await promiseToFuture(writePyodideFile(file.name, csvData));
    String? csvParams = await promiseToFuture(convertParamsToCSV(file.name));
    List<List<String>> data =
        const CsvToListConverter(shouldParseNumbers: false, eol: "\n")
            .convert(csvParams);

    List<Map<String, String>> csvRows = [];
    List<String> headers = data.removeAt(0);
    for (var i = 0; i < data.length; i++) {
      Map<String, String> row = {};
      for (var j = 0; j < headers.length; j++) {
        row[headers[j]] = data[i][j];
      }
      csvRows.add(row);
    }

    setState(() {
      rows = csvRows;
      _editableKey.currentState?.rows = rows;
    });
  }

  void saveCsv() {
    String csvName = "$name.csv";
    String? csv = getCsvData();

    if (csv == null) return;

    Uint8List csvData = Uint8List.fromList(csv.codeUnits);
    saveFile(csvName, csvData);
  }

  void saveX3D() async {
    String x3dName = "$name.x3d";
    String? x3d = await generateX3D();
    if (x3d == null) return;

    Uint8List x3dData = Uint8List.fromList(x3d.codeUnits);

    if (generateSimulinkController.value) {
      String mdlName = "simulink_$name.mdl";
      String? mdl = await generateMDL();
      if (mdl == null) return;

      Uint8List mdlData = Uint8List.fromList(mdl.codeUnits);
      String zipName = "$name.zip";
      Uint8List? zipData = createZip([
        Tuple2<String, Uint8List>(x3dName, x3dData),
        Tuple2<String, Uint8List>(mdlName, mdlData),
      ]);
      if (zipData == null) return;
      saveFile(zipName, zipData);
    } else {
      saveFile(x3dName, x3dData);
    }
  }

  void previewX3D() async {
    String? x3d = await generateX3D();
    if (x3d == null) return;

    showDialog(context: context, builder: (_) => X3DPreview(x3d));
  }

  void setName() async {
    await showDialog(context: context, builder: (_) => NameSetterDialog(tc));
    if (tc.text == "") {
      tc.text = "robot";
    }
    setState(() {});
  }

  void showHelp() {
    String url =
        "https://github.com/Gigahawk/dh2vrml/blob/$dh2vrmlVersion/README.md#parameters";
    launch(url);
  }

  Uint8List? createZip(List<Tuple2<String, Uint8List>> data) {
    Archive archive = Archive();
    for (Tuple2<String, Uint8List> element in data) {
      String name = element.item1;
      Uint8List fileData = element.item2;
      ArchiveFile f = ArchiveFile(name, fileData.length, fileData);
      archive.addFile(f);
    }
    Uint8List? zipData = ZipEncoder().encode(archive) as Uint8List;
    return zipData;
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
      return csvHeader.map((String key) {
        return row[key] as String;
      }).toList();
    }).toList();

    if (useDegreesController.value) {
      csvHeader = csvHeader.map((String key) {
        if (key == "alpha" || key == "theta") {
          return "${key}_deg";
        } else {
          return key;
        }
      }).toList();
    }

    csvRows.insert(0, csvHeader);

    String csv = const ListToCsvConverter().convert(csvRows);
    return csv;
  }

  Future<String?> generateX3D() async {
    String csvName = "$name.csv";
    String? csvData = getCsvData();
    if (csvData == null) return null;
    await promiseToFuture(writePyodideFile(csvName, csvData));

    String? modelXML = await promiseToFuture(generateX3DFile(csvName));
    return modelXML;
  }

  Future<String?> generateMDL() async {
    String csvName = "$name.csv";
    String? csvData = getCsvData();
    if (csvData == null) return null;
    await promiseToFuture(writePyodideFile(csvName, csvData));

    String? modelMDL = await promiseToFuture(generateMDLFile(csvName, name));
    return modelMDL;
  }

  List<Map<String, dynamic>> cols = [
    {"title": 'Joint Type', 'widthFactor': 0.15, 'key': 'type'},
    {"title": 'd', 'widthFactor': 0.10, 'key': 'd'},
    {"title": '??', 'widthFactor': 0.10, 'key': 'theta'},
    {"title": 'r', 'widthFactor': 0.10, 'key': 'r'},
    {"title": '??', 'widthFactor': 0.10, 'key': 'alpha'},
    {"title": 'Color', 'widthFactor': 0.15, 'key': 'color'},
    {"title": 'Scale', 'widthFactor': 0.10, 'key': 'scale'},
    {"title": 'Offset', 'widthFactor': 0.15, 'key': 'offset'},
  ];

  List<Map<String, String>> rows = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('dh2vrml for web'),
          actions: [
            ElevatedButton(onPressed: showHelp, child: const Text("Help"))
          ],
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  Wrap(
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    direction: Axis.horizontal,
                    spacing: 20.0,
                    runSpacing: 20.0,
                    children: [
                      ElevatedButton(
                          onPressed: setName, child: const Text("Set Name")),
                      ElevatedButton(
                          onPressed: pickFile,
                          child: const Text("Import Parameters")),
                      ElevatedButton(
                          onPressed: saveCsv, child: const Text("Save CSV")),
                      ElevatedButton(
                          onPressed: previewX3D,
                          child: const Text("Preview X3D")),
                      ElevatedButton(
                          onPressed: saveX3D, child: const Text("Export X3D")),
                      Text("Name: $name")
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Wrap(
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    direction: Axis.horizontal,
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: [
                      const Text("Angle Unit:"),
                      AdvancedSwitch(
                          controller: useDegreesController,
                          activeChild: const Text("DEG"),
                          inactiveChild: const Text("RAD"),
                          // TODO: figure out how to pull this from theme
                          activeColor: Colors.blue,
                          width: 65.0,
                          height: 30.0),
                      const SizedBox(width: 10.0),
                      const Text("Generate Simulink Model"),
                      AdvancedSwitch(
                          controller: generateSimulinkController,
                          activeChild: const Text("ON"),
                          inactiveChild: const Text("OFF"),
                          // TODO: figure out how to pull this from theme
                          activeColor: Colors.blue,
                          width: 65.0,
                          height: 30.0)
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                      height: 600,
                      child: Editable(
                        key: _editableKey,
                        showCreateButton: true,
                        showRemoveIcon: true,
                        createButtonIcon: const Icon(Icons.add),
                        createButtonColor: Colors.black,
                        removeIconColor: Colors.white,
                        columns: cols,
                        rows: rows,
                        zebraStripe: true,
                        stripeColor1: Colors.black12,
                        stripeColor2: Colors.black,
                        borderColor: Colors.blueGrey,
                      ))
                ]))));
  }
}
