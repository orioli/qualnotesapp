import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';
import 'package:qualnotes/src/widgets/strings.dart';

class myTitleDialog extends StatelessWidget {
  final String? prj_id;
  final String title;
  final String hint;
  final Future<void> Function(String) onPress;

  const myTitleDialog({
    Key? key,
    this.prj_id,
    required this.title,
    required this.hint,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          validator: (val) =>
              val?.isEmpty ?? true ? Strings.pleaseEnterTitle : null,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ),
      actions: [
        Consumer<ApplicationState>(
          builder: (context, appState, _) => TextButton(
            onPressed: appState.uploading_title
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await onPress(_titleController.text);
                      _titleController.clear();
                      Navigator.of(context).pop();
                    }
                  },
            child: appState.uploading_title
                ? CircularProgressIndicator()
                : Text(Strings.ok),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Strings.cancel.toUpperCase()),
        ),
      ],
    );
  }
}
