// the widgets here below are used in the stepper
// TODO: move to appropriate location or renam to invite_widgets.dart ?

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class GenInviteLink extends StatelessWidget {
  final String projectId;

  GenInviteLink({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite People')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final link = await generateInvitationLink(projectId);
            debugPrint("here is link to share" + link);
            print(
                link); // Show the generated link or use a plugin to share the link via SMS
          },
          child: Text('Generate Invitation Link'),
        ),
      ),
    );
  }
}

class QRInviteScanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRInviteScannerState();
}

class _QRInviteScannerState extends State<QRInviteScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRScannerViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text(
                      'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  : Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRScannerViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream
        .firstWhere((scanData) => scanData != null)
        .then((scanData) {
      //format:    'https://' + Strings.baseHostingURL + '/accept-invitation/$token';

      final String url_with_token = scanData.code!;
      Uri uri = Uri.parse(url_with_token);
      List<String> segments = uri.fragment.split('/');
      String inviteToken = segments.last;
      debugPrint("      String inviteToken = ${segments.last}");
      context.pushNamed('accept-invitation-in-app',
          queryParams: {'token': inviteToken});
    });
  }
}
/*
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AcceptInvitationScreen(token: inviteToken)));
    });
  }*/

class DetailScreen extends StatelessWidget {
  final String data;

  DetailScreen(this.data);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Data'),
      ),
      body: Center(
        child: Text('QR code data: $data'),
      ),
    );
  }
}

class QRCodeImage extends StatelessWidget {
  final String link;

  const QRCodeImage({Key? key, required this.link}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: QrImageView(
        data: link,
        version: QrVersions.auto,
        size: 220.0,
      ),
    );
  }
}

class QRCodeScreen extends StatefulWidget {
  final String link;

  const QRCodeScreen({Key? key, required this.link}) : super(key: key);

  @override
  _QRCodeScreenState createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Code"),
      ),
      body: Center(
        child: QrImageView(
          data: widget.link,
          version: QrVersions.auto,
          size: 220.0,
        ),
      ),
    );
  }
}

Future<String> generateInvitationLink(String projectId) async {
  // Check if an invitation link already exists for the project
  final querySnapshot = await FirebaseFirestore.instance
      .collection('project_invitations')
      .where('projectId', isEqualTo: projectId)
      // .where('status', isEqualTo: 'pending') // ont invite can be accepted by vsatious users... not jsut once
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    // Return the existing invite link if one exists
    final token = querySnapshot.docs.first.id;
    final link =
        'https://' + Strings.baseHostingURL + '/accept-invitation/$token';
    return link;
  } else {
    // Generate a unique token for the invitation
    final token =
        FirebaseFirestore.instance.collection('project_invitations').doc().id;

    // Store the invitation data in Firestore
    await FirebaseFirestore.instance
        .collection('project_invitations')
        .doc(token)
        .set({
      'projectId': projectId,
      'status': 'not yet accepted by anyone',
      'timestamp': Timestamp.now(),
    });

    // Return the generated invite link
    final link =
        'https://' + Strings.baseHostingURL + '/accept-invitation/$token';
    return link;
  }
}

Future<void> showCopyToClipboardDialog(
    BuildContext context, String textToCopy) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true, // Close the dialog when tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Invite Link'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Hello, to join this project click:'),
              SelectableText(textToCopy),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textToCopy));
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
