@JS()
library dh2vrml_web;

import 'package:js/js.dart';

@JS('initPyodide')
external void initPyodide();

@JS('writePyodideFile')
external dynamic writePyodideFile(String fileName, String fileData);

@JS('updatePyodideProgress')
external set _updatePyodideProgress(void Function(double, String) f);

@JS('generateX3DFile')
external dynamic generateX3DFile(String fileName);

@JS()
external void updatePyodideProgress(double progress, String msg);

void initInterop(void Function(double, String) onProgress) {
  _updatePyodideProgress = allowInterop(onProgress);
}
