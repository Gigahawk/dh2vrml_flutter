import 'package:flutter/material.dart';

class NameSetterDialog extends StatelessWidget {
  final TextEditingController tc;
  const NameSetterDialog(this.tc, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Set Name"),
      content: TextField(autofocus: true, controller: tc),
      actions: [
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"))
      ],
    );
  }
}
