import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_thumb_kit/video_thumb_kit.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Platform messages are asynchronous, so we initialize in an async method.

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String? thumbnail;
  Uint8List? thumbanilBytes;

  bool isLoading = false;

  Future<void> getVideoFile() async {
    setState(() => isLoading = true);
    try {
      if (kIsWeb || Platform.isMacOS) {
        final files = await FilePicker.platform.pickFiles();

        if (files != null && files.files.isNotEmpty) {
          if (kIsWeb) {
            thumbanilBytes = await VideoThumbKit.thumbnailDataWeb(
              videoBytes: files.files.first.bytes ?? Uint8List(0),
            );
          } else {
            final selectedPath = files.files.first.path ?? '';
            if (selectedPath.isNotEmpty) {
              thumbnail = await VideoThumbKit.thumbnailFile(
                video: selectedPath,
                imageFormat: ImageFormat.webp,
              );
            }
          }
        }
      } else {
        final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
        thumbnail = await VideoThumbKit.thumbnailFile(
          video: file?.path ?? '',
          imageFormat: ImageFormat.png,
        );
      }
    } catch (error) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        getVideoFile();
                      },
                      child: thumbnail == null
                          ? Text('Click to get thumbnail')
                          : Text('Running on: \n$thumbnail'),
                    ),
                    if (thumbnail != null && !kIsWeb) ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Image.file(
                          File(thumbnail ?? ''),
                        ),
                      ),
                    ] else if (thumbanilBytes != null) ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Image.memory(
                        thumbanilBytes ?? Uint8List(0),
                      )),
                    ],
                    if (thumbanilBytes != null || thumbnail != null) ...[
                      SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          getVideoFile();
                        },
                        child: Text('Get Next Thumbnail'),
                      ),
                    ]
                  ],
                ),
        ),
      ),
    );
  }
}
