import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/auth_prompt.dart';
import 'create_channel_sheet.dart';

/// Entry point of "upload a video" (the + button and the Studio button).
/// Guests are asked to log in first. A registered account already owns a
/// default channel, so there is no channel registration step before uploading.
Future<void> startUpload(BuildContext context) async {
  if (!requireLogin(context, 'Log in to upload videos.')) return;

  final auth = context.read<AuthViewModel>();
  if (!auth.hasChannel) {
    // Safety net: should not happen because accounts get a default channel.
    final created = await showCreateChannelSheet(context);
    if (created != true || !context.mounted) return;
  }
  context.push(RouteNames.upload);
}
