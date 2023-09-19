import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoDownloader {
  Dio dio = Dio();

  Future<void> downloadVideo(
      String url, String filename, Function(double) onProgress) async {
    try {
      final response = await dio.get(url,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              var progress = received / total;
              onProgress(progress);
            }
          });

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        File file = File(filePath);
        await file.writeAsBytes(response.data);
      } else {
        throw Exception('Failed to download video');
      }
    } catch (e) {
      print("Failed to download video, try again! $e");
      rethrow;
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Video Downloader',
      home: Homepage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _editingController = TextEditingController();
  final videoDownloader = VideoDownloader();

  int _selectedIndex = 0;
  double _downloadProgress = 0.0;
  bool _downloading = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _downloadVideo() async {
    final urlToDownload = _editingController.text;
// check for the textediting controller is empty 
    if (urlToDownload.isEmpty) {
      _showErrorDialog("Nothing to download");
    } else {
      setState(() {
        _downloading = true;
      });
      await _startDownload(urlToDownload, 'downloaded_video.mp4'); // Specify the video file name
    }
  }

  Future<void> _startDownload(String urlToDownload, String filename) async {
    try {
      await videoDownloader.downloadVideo(urlToDownload, filename, (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      });

      setState(() {
        _downloading = false;
      });

      _showDownloadCompletionDialog();
    } catch (e) {
      _showErrorDialog("Failed to download video. Try again!");
    }
  }

  void _pasteFromClipboard() async {
    final clipboardText = await Clipboard.getData('text/plain');
    // check if the url is in the
    if (clipboardText != null) {
      _editingController.text = clipboardText.text!;
    }
  }

  Future<void> _showDownloadCompletionDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const  Text("Download Completed",
          style: TextStyle(
              color: Colors.green,
          ),),
          content: const Text("Video downloaded successfully!",
          style: TextStyle(
              color: Colors.green,
          ),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog(String errorMessage) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Error",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:const  Text("Ok"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            "Video Downloader",
            style: TextStyle(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _editingController,
              decoration: const InputDecoration(
                labelText: 'Enter the video link to download ',
                hintStyle: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black12,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: _pasteFromClipboard,
              child: const Text(
                'Paste URL from Clipboard',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _downloading ? null : _downloadVideo,
              child: _downloading
                  ? Column(
                      children: [
                        LinearProgressIndicator(value: _downloadProgress),
                      const   SizedBox(height: 8.0),
                        Text(
                          "${(_downloadProgress * 100).toStringAsFixed(2)}%",
                          style:const  TextStyle(fontSize: 16.0),
                        ),
                      ],
                    )
                  : const Text(
                      'Download Video',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.purple,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Download',
            backgroundColor: Colors.purple,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
