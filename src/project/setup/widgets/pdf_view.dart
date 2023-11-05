import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfView extends StatelessWidget {
  const PdfView({Key? key, required this.title, required this.file})
      : super(key: key);

  final String file;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: true,
        child: SfPdfViewer.network(file),
      ),
    );
  }
}
