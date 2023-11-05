import 'package:flutter/material.dart';

void showRotateToDualScreenDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Rotate to Dual Screen'),
        content: Text(
            'To use dual screen rotate your device to landscape orientation.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
