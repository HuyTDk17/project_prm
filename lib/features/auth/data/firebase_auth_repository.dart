import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/channel.dart';
import 'auth_repository.dart';
import 'channel_store.dart';

/// Accounts with Firebase Authentication (email + password) and profile and
/// channels in Cloud Firestore. Firebase keeps the session in the browser, so a
/// registered user stays logged in after a refresh (BR17).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance {
    _channels = ChannelStore(_db);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  late final ChannelStore _channels;

  @override
  Future<AppUser?> restoreSession() async {
    // The first event tells whether a saved session exists.
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    return _loadUser(user);
  }

  @override
  Future<AppUser> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return await _loadUser(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    }
  }

  @override
  Future<AppUser> register(String displayName, String email, String password) async {
    final name = displayName.trim();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final fbUser = cred.user!;
      await fbUser.updateDisplayName(name);
      await _db.collection('users').doc(fbUser.uid).set({
        'displayName': name,
        'email': fbUser.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // BR03: every account gets a default channel named after the display name.
      final channel = await _channels.createDefault(ownerId: fbUser.uid, displayName: name);
      return AppUser(id: fbUser.uid, email: fbUser.email ?? email.trim(), displayName: name, channels: [channel]);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    }
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final fbUser = cred.user!;

      // First Google login = registration: create the profile and the default channel.
      final userRef = _db.collection('users').doc(fbUser.uid);
      final profile = await userRef.get();
      final googleName = fbUser.displayName?.trim();
      final name = (googleName != null && googleName.length >= 2)
          ? googleName
          : (fbUser.email?.split('@').first ?? 'User');
      if (!profile.exists) {
        await userRef.set({
          'displayName': name,
          'email': fbUser.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      final existing = await _channels.listByOwner(fbUser.uid);
      if (existing.isEmpty) {
        await _channels.createDefault(ownerId: fbUser.uid, displayName: name);
      }
      return await _loadUser(fbUser);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<Channel> createChannel(AppUser owner, String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 3 || trimmed.length > 50) {
      throw const ChannelException(AppStrings.channelNameInvalid);
    }
    if (owner.channels.length >= ChannelStore.maxChannelsPerAccount) {
      throw const ChannelException(AppStrings.maxChannels);
    }
    return _channels.create(ownerId: owner.id, name: trimmed, isDefault: false);
  }

  Future<AppUser> _loadUser(User fbUser) async {
    final doc = await _db.collection('users').doc(fbUser.uid).get();
    final name = (doc.data()?['displayName'] as String?) ?? fbUser.displayName ?? fbUser.email ?? 'User';
    final channels = await _channels.listByOwner(fbUser.uid);
    return AppUser(id: fbUser.uid, email: fbUser.email ?? '', displayName: name, channels: channels);
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return AppStrings.invalidCredentials;
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'user-cancelled':
        return AppStrings.googleCancelled;
      case 'popup-blocked':
        return AppStrings.googlePopupBlocked;
      case 'operation-not-allowed':
        return AppStrings.googleDisabled;
      case 'account-exists-with-different-credential':
        return AppStrings.accountExistsOtherMethod;
      case 'email-already-in-use':
        return AppStrings.emailTaken;
      case 'weak-password':
        return AppStrings.passwordInvalid;
      default:
        return AppStrings.genericError;
    }
  }
}
