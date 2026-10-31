import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/channel/data/firestore_channel_repository.dart';
import 'features/home/data/firestore_video_repository.dart';
import 'features/studio/data/firestore_studio_repository.dart';
import 'features/video_player/data/firestore_engagement_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error, stack) {
    // Without this, a failed initialisation stops main() before runApp()
    // and the browser shows an empty white page.
    debugPrint('Firebase initialisation failed: $error\n$stack');
    runApp(_StartupError(message: '$error'));
    return;
  }
  runApp(
    MiniTubeApp(
      authRepository: FirebaseAuthRepository(),
      videoRepository: FirestoreVideoRepository(),
      engagementRepository: FirestoreEngagementRepository(),
      channelRepository: FirestoreChannelRepository(),
      studioRepository: FirestoreStudioRepository(),
    ),
  );
}

/// Shown instead of a blank page when Firebase cannot be initialised.
class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MiniTube cannot start',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Firebase could not be initialised. Check lib/firebase_options.dart '
                    '(run "flutterfire configure --platforms=web") and your Internet connection.',
                  ),
                  const SizedBox(height: 16),
                  SelectableText(message, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
