import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/widgets/strings.dart';

import '../app_state.dart';

class PopupConfirmation extends StatelessWidget {
  const PopupConfirmation({
    Key? key,
    required this.title,
    required this.onConfirm,
  }) : super(key: key);

  final String title;
  final Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      height: 130,
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Consumer<ApplicationState>(
            builder: (context, appState, _) => Row(
              children: [
                Spacer(),
                ElevatedButton(
                  onPressed: onConfirm,
                  child: appState.uploading_title
                      ? Center(
                          child: SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Text(Strings.delete.toUpperCase()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appState.uploading_title
                        ? Colors.red.withOpacity(0.3)
                        : Colors.red,
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    if (!appState.uploading_title) context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appState.uploading_title
                        ? Colors.blueGrey.withOpacity(0.3)
                        : Colors.blueGrey,
                  ),
                  child: Text(Strings.cancel.toUpperCase()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
