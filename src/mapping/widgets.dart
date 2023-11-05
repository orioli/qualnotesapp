import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:qualnotes/src/widgets/app_sizes.dart';
import 'package:qualnotes/src/widgets/widgets.dart';

import '../pobs/full_screen_audio.dart';
import 'geonote.dart';

class GoogleMapsMarker extends StatelessWidget {
  const GoogleMapsMarker({
    super.key,
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40.0,
        ),
        Positioned(
          top: 6,
          left: (40.0 / 2) - (18.0 / 2),
          child: Container(
            width: 18.0,
            height: 18.0,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 6,
          left: (index > 9 ? 11 : 16),
          child: Text(
            index.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

Color myColorPalette(GeoNote geoNote) {
  switch (geoNote.text) {
    case 'text':
      return const Color(0xCA20FFBA);

    case 'photo':
      return const Color(0xC0BA6520);

    case 'audio':
      return const Color(0xB2FF209E);

    default:
      return const Color(0xB2FF209E);
  }
}

Widget note2Tumbnail(GeoNote geoNote) {
  switch (geoNote.note_type) {
    case 'text':
      return GoogleMapsMarker(index: geoNote.note_index + 1);

    case 'photo':
      return ImgMapThumbnail(gn: geoNote); //MapEmoji("📷");
    case 'audio':
      return MapEmoji("🎙️");
    default:
      return GoogleMapsMarker(index: (geoNote.note_index + 1));
  }
}

class FullScreenImgUrl extends StatelessWidget {
  final String imageUrl;

  FullScreenImgUrl({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Center(
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/loading.gif',
          image: imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class FullScreenImgLocal extends StatelessWidget {
  final String imagePath;

  FullScreenImgLocal({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Center(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String path;
  final bool isLocal;

  FullScreenImage({required this.path, this.isLocal = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Center(
        child: isLocal
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
              )
            : FadeInImage.assetNetwork(
                placeholder: 'assets/loading.gif',
                image: path,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class FullScreenImageWithOvelayText extends StatelessWidget {
  final String path;
  final bool isLocal;
  final String? overlayText; // New parameter for the optional text

  FullScreenImageWithOvelayText(
      {required this.path, this.isLocal = true, this.overlayText});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Stack(
        alignment: Alignment
            .bottomCenter, // this will align children to the bottom center
        children: <Widget>[
          Center(
            child: isLocal
                ? Image.file(
                    File(path),
                    fit: BoxFit.contain,
                  )
                : FadeInImage.assetNetwork(
                    placeholder: 'assets/loading.gif',
                    image: path,
                    fit: BoxFit.contain,
                  ),
          ),
          if (overlayText != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height *
                        0.1), // 10% padding from bottom
                child: Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    overlayText!,
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget buildHtmlImageView(String imageUrl) {
  debugPrint(
      '<img src="$imageUrl" style="height: 100%; width: 100%; object-fit: cover;" />');

  return Image.network(imageUrl, height: 200, width: 200, fit: BoxFit.cover,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator(
      value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded /
              loadingProgress.expectedTotalBytes!
          : null,
    );
  }, errorBuilder: (context, error, stackTrace) {
    debugPrint('Error occurred while loading the image: $error');
    return Text('Some errors occurred! cant load :' + imageUrl.toString());
  });
}

Widget _buildHtmlImageView2(String imageUrl) {
  return LimitedBox(
    maxWidth: 200.0,
    maxHeight: 200.0,
    child: Html(
        data:
            '<img src="$imageUrl" style="height: 100%; width: 100%; object-fit: cover;" />'),
  );
}

Widget _buildNormalImageView(String imageUrl) {
  // Use a normal Image.network widget.
  return Image.network(imageUrl);
}

Widget buildImageWidget(String imgPath) {
  if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
    // it's a URL
    return kIsWeb
        ? buildHtmlImageView(imgPath)
        : FadeInImage.assetNetwork(
            placeholder: 'assets/images/loading.gif',
            image: imgPath,
            height: 150,
            fit: BoxFit.cover,
          );
  } else {
    // it's a local file path
    return Image.file(
      File(imgPath),
      height: 150,
      fit: BoxFit.cover,
    );
  }
}

Widget buildImageWidgetWithTextOVerlay(String imgPath) {
  Widget imageWidget;

  if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
    // it's a URL
    imageWidget = kIsWeb
        ? buildHtmlImageView(imgPath)
        : FadeInImage.assetNetwork(
            placeholder: 'assets/images/loading.gif',
            image: imgPath,
            fit: BoxFit.cover,
          );
  } else {
    // it's a local file path
    imageWidget = Image.file(
      File(imgPath),
      fit: BoxFit.cover,
    );
  }

  return Stack(
    fit: StackFit.expand,
    children: <Widget>[
      imageWidget,
      Container(
        color: Colors.black45,
        child: Center(
          child: Text(
            'xxxx', // Replace with your text
            style: TextStyle(color: Colors.white, fontSize: 30.0),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ],
  );
}

ImageProvider<Object> localOrNetworkProvider(String imgPath) {
  if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
    // it's a URL
    return kIsWeb ? NetworkImage(imgPath) : NetworkImage(imgPath);
  } else {
    // it's a local file path
    return FileImage(File(imgPath));
  }
}

class CardThumbnail extends StatelessWidget {
  final double imgH = AppSizes.thumbnailImgHeight;
  final GeoNote gn;
  CardThumbnail({Key? key, required this.gn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(0, 5, 0, 5), // change the padding size here
      child: InkWell(
        onTap: () async {
          if (gn.imgPath != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullScreenImage(
                  path: gn.imgPath!,
                  isLocal: !(gn.imgPath!.startsWith('http') ||
                      gn.imgPath!.startsWith('https')),
                  //overlayText: gn.text,
                ),
              ),
            );
          } else if (gn.audioPath != null) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return FractionallySizedBox(
                  heightFactor: 0.7, // adjust this value as needed
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      ParagraphCropped(
                          'Audio Note ${gn.note_index} \nRecorded on ${gn.timestamp}. \n${gn.text}'),
                      Expanded(
                        child: FullScreenAudio(
                          path: gn.audioPath!,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } //else
        },
        child: (gn.imgPath != null)
            ? SizedBox(
                width: imgH,
                height: imgH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: buildImageWidget(gn.imgPath!),
                ),
              )
            : Container(
                width: imgH,
                height: imgH,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: gn.audioPath !=
                        null // Here's where you check if there's an audioPath
                    ? Icon(Icons.music_note,
                        color: Colors.grey[
                            600]) // Show audio icon if there's an audioPath
                    : Icon(Icons.text_increase,
                        color: Colors.grey[
                            600]), // Show photo icon if there's no audioPath
              ),
      ),
    );
  }
}

class ImgMapThumbnail extends StatelessWidget {
  final double imgH = AppSizes.thumbnailImgHeight; //48;
  final GeoNote gn;
  ImgMapThumbnail({Key? key, required this.gn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(0, 5, 0, 5), // change the padding size here
      child: InkWell(
        child: (gn.imgPath != null)
            ? SizedBox(
                width: imgH,
                height: imgH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: buildImageWidget(gn.imgPath!),
                ),
              )
            : Container(
                width: imgH,
                height: imgH,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: gn.audioPath !=
                        null // Here's where you check if there's an audioPath
                    ? Icon(Icons.music_note,
                        color: Colors.grey[
                            600]) // Show audio icon if there's an audioPath
                    : Icon(Icons.text_increase,
                        color: Colors.grey[
                            600]), // Show photo icon if there's no audioPath
              ),
      ),
    );
  }
}
