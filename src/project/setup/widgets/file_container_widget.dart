import 'package:flutter/material.dart';
import 'package:qualnotes/src/project/setup/widgets/pdf_view.dart';

class FileContainerWidget extends StatelessWidget {
  const FileContainerWidget({super.key, required this.file});

  final String file;

  String getFileName(String url) {
    RegExp regExp = new RegExp(r'.+(\/|%2F)(.+)\?.+');
    var matches = regExp.allMatches(url);
    var match = matches.elementAt(0);
    return Uri.decodeFull(match.group(2) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: UniqueKey(),
      margin: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PdfView(title: getFileName(file), file: file),
                    ),
                  ),
                  child: Text(
                    getFileName(file),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(
                  width: 4,
                ),
                Icon(
                  Icons.check,
                  color: Colors.green,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
