import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';
import 'package:qualnotes/src/project/setup/consent/consent_upload_pdf.dart';
import 'package:qualnotes/src/project/setup/consent/conset_upload_additional_files.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({Key? key, required this.prj_id}) : super(key: key);

  final String prj_id;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  late PageController _pgController;
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  GlobalKey<SfSignaturePadState> signaturePadKey = GlobalKey();
  int selectedInd = 0;
  final _formKey = GlobalKey<FormState>();

  String _prj_id = '';

  @override
  void initState() {
    _prj_id = widget.prj_id;
    _pgController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(builder: (context, value, _) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (!value.isSignLoading) if (selectedInd != 2) {
              await _pgController.nextPage(
                  duration: Duration(milliseconds: 500), curve: Curves.ease);
            } else {
              if (_formKey.currentState?.validate() ?? false) {
                final data = await signaturePadKey.currentState!
                    .toImage(pixelRatio: 3.0);
                final bytes =
                    await data.toByteData(format: ui.ImageByteFormat.png);
                Uint8List imageInUnit8List = bytes?.buffer.asUint8List() ??
                    Uint8List(0); // store unit8List image here ;
                final tempDir = await getTemporaryDirectory();
                File file = await File('${tempDir.path}/image.png').create();
                file.writeAsBytesSync(imageInUnit8List);
                await value
                    .submitFormDataToFirebase(
                        file: file,
                        docId: widget.prj_id,
                        context: context,
                        name: _name.text,
                        email: _email.text)
                    .whenComplete(() {
                  context.pop();
                });
              }
            }
          },
          child: Text(
            selectedInd == 0
                ? Strings.next.toUpperCase()
                : selectedInd == 1
                    ? Strings.sign
                    : Strings.submit,
          ),
        ),
        appBar: AppBar(
          title: Text(Strings.collectConsent),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            onPressed: () {
              // Navigator.of(context).pop(true); TODO: this does not work, is there a better way to do this than the below code?
              context.pop();
            },
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                allowImplicitScrolling: false,
                onPageChanged: (value) {
                  setState(() {
                    selectedInd = value;
                  });
                },
                controller: _pgController,
                children: [
                  UploadPDF(prj_id: widget.prj_id, docType: 'info_statement'),
                  UploadPDF(prj_id: widget.prj_id, docType: 'consent_form'),
                  UploadAdditionalPDF(
                      sfSignKey: signaturePadKey,
                      formKey: _formKey,
                      name: _name,
                      email: _email),
                ],
              ),
            ),
            Positioned.fill(
              child: value.isSignLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : SizedBox.shrink(),
            )
          ],
        ),
      );
    });
  }
}
