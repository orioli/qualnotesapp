import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qualnotes/src/widgets/app_sizes.dart';

class LoadingImage extends StatelessWidget {
  final String url;
  const LoadingImage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: _loadImage(url),
      builder: (BuildContext context, AsyncSnapshot<ImageProvider> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Icon(Icons.error);
        }
        return Container(
          width: AppSizes.thumbnailImgHeight,
          height: AppSizes.thumbnailImgHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            image: DecorationImage(
              image: snapshot.data!,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Future<ImageProvider> _loadImage(String url) async {
    final NetworkImage imageProvider = NetworkImage(url);
    final Completer<ImageProvider> completer = Completer();
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo image, bool sync) {
        if (!completer.isCompleted) {
          completer.complete(imageProvider);
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    completer.future.then((_) {
      stream.removeListener(listener);
    });
    return completer.future;
  }
}

Future<File?> pickImage() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    return File(image.path);
  } else {
    return null;
  }
}

Future<String?> uploadImage(File imageFile) async {
  try {
    final String filePath =
        'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = FirebaseStorage.instance.ref().child(filePath);
    final UploadTask uploadTask = ref.putFile(imageFile);
    final TaskSnapshot taskSnapshot = await uploadTask;
    final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print(e);
    return null;
  }
}
