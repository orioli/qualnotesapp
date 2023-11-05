import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: context.pop,
        child: Scaffold(
          body: Column(
            children: [
              Spacer(),
              Center(
                child: Hero(
                  tag: image,
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                  ),
                ),
              ),
              Spacer()
            ],
          ),
        ),
      ),
    );
  }
}

Widget elapsedTimeInScreen(String hhmmss) {
  return Container(
    color: Color.fromARGB(255, 0, 0, 0),
    child: Text(
      hhmmss,
      style: TextStyle(
        color: Colors.white, fontSize: 18,
        fontWeight: FontWeight.bold, // Make text bold
      ),
    ),
  );
}
