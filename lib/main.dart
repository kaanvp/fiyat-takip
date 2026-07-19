import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _intentSubscription;
  String? _sharedUrl;

  @override
  void initState() {
    super.initState();
    
    // For sharing content coming from outside the app while the app is in the memory
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> intent) {
        _handleSharedIntent(intent);
      },
      onError: (err) {
        // ignore: avoid_print
        print('Error receiving sharing intent: $err');
      },
    );

    // For sharing content coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedIntent(value);
        }
      },
      onError: (err) {
        // ignore: avoid_print
        print('Error receiving initial sharing intent: $err');
      },
    );
  }

  void _handleSharedIntent(List<SharedMediaFile> intent) {
    if (intent.isNotEmpty && intent.first.path.isNotEmpty) {
      final url = intent.first.path;
      if (Uri.tryParse(url) != null) {
        setState(() {
          _sharedUrl = url;
        });
      }
    }
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return App(
      sharedUrl: _sharedUrl,
    );
  }
}
