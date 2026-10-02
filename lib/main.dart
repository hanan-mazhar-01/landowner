import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // The phone layout is designed for portrait; tablets keep every orientation.
  final view = WidgetsBinding.instance.platformDispatcher.implicitView;
  if (view != null && (view.physicalSize / view.devicePixelRatio).shortestSide < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp note: $e');
  }
  runApp(const ProviderScope(child: HomelyApp()));
}
