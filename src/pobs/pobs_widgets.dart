// Copyright 2022-2023 Jose Berengeueres, Qualnotes AB.
// Adapted from livelocation tutorial
import 'package:flutter/material.dart';
import 'package:qualnotes/src/mapping/widgets.dart';
import 'dart:async';

Future<dynamic> showImageFullScreen(BuildContext context, gn) {
  return showDialog(
      context: context,
      builder: (_) => Dialog(
            insetPadding: EdgeInsets.zero, // No padding around the dialog
            backgroundColor: Colors.black,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Image(
                  image: localOrNetworkProvider(gn.imgPath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ));
}

/*
  Widget _imgThumb(GeoNote gn) {
    return gn.imgPath!.isNotEmpty
        ? GestureDetector(
            onTap: () {
              showImageFullScreen(gn);
            },
            child: buildImageWidget(gn.imgPath!),
          )
        : const Text("cant find the photo!!");
  }
*/