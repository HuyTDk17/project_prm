import 'package:firebase_core/firebase_core.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
