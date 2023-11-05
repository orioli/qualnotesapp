import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class UploadPDF extends StatelessWidget {
  const UploadPDF({Key? key, required this.docType, required this.prj_id})
      : super(key: key);

  final String prj_id;
  final String docType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('/projects/')
            .doc(prj_id)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.data?.exists ?? false) {
            return SafeArea(
              top: true,
              child: SfPdfViewer.network(
                snapshot.data?.get(docType),
                scrollDirection: PdfScrollDirection.vertical,
              ),
            );
          } else {
            return Text(Strings.tryAgain);
          }
        },
      ),
    );
  }
}
