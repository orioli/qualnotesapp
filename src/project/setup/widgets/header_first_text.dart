import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qualnotes/src/widgets/strings.dart';

class HeaderText extends StatelessWidget {
  const HeaderText({
    Key? key,
    required this.id,
    required this.title,
    required this.fieldKey,
    required this.onTap,
  }) : super(key: key);

  final String id;
  final String fieldKey;
  final String title;
  final Function() onTap;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('/projects/')
          .doc(id)
          .snapshots()
          .asBroadcastStream(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        bool _isFileExist = false;

        try {
          if ((snapshot.data?.data() as Map?)?.containsKey(fieldKey) ?? false) {
            _isFileExist = true;
          }
        } catch (e) {}
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(
              width: 5,
            ),
            ElevatedButton(
              onPressed: onTap,
              child: Text(
                _isFileExist ? Strings.replace : Strings.upload,
                style: const TextStyle(fontSize: 16),
              ),
            )
          ],
        );
      },
    );
  }
}
