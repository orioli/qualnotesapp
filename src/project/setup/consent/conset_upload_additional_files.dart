import 'package:flutter/material.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class UploadAdditionalPDF extends StatelessWidget {
  UploadAdditionalPDF({
    Key? key,
    required this.sfSignKey,
    required this.name,
    required this.formKey,
    required this.email,
  }) : super(key: key);

  final GlobalKey<SfSignaturePadState> sfSignKey;
  GlobalKey<FormState> formKey;
  TextEditingController name;
  TextEditingController email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.userName,
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: name,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return Strings.nameShouldNotBeEmpty;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                      hintText: Strings.enterFullName,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(10))),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  Strings.userEmail,
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: email,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return Strings.emailShouldNotBeEmpty;
                    }
                    if (!validateEmail(value ?? "")) {
                      return Strings.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                      hintText: Strings.enterEmail,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(10))),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Text(
                      Strings.signature,
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        sfSignKey.currentState!.clear();
                      },
                      child: Text(
                        Strings.clear,
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  child: SfSignaturePad(
                    key: sfSignKey,
                    strokeColor: Colors.black,
                    minimumStrokeWidth: 1.0,
                    maximumStrokeWidth: 2.0,
                    backgroundColor: Colors.grey[200],
                  ),
                  height: 200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern.toString());
    return (!regex.hasMatch(value)) ? false : true;
  }
}
