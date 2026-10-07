import 'package:flutter/foundation.dart';

import '../models/user.dart';

/// Who is signed in right now. Screens read [name] instead of a hard-coded
/// student name, and listen to this object to refresh when the profile
/// changes.
///
/// NOTE: kept in memory only (no extra packages needed). To remember the
/// user between app launches, save/load [AppUser] in
/// `data/services/storage_service.dart` (e.g. with shared_preferences) and
/// call [signIn] at startup.
class UserSession extends ChangeNotifier {
  UserSession._();

  static final UserSession instance = UserSession._();

  /// Shown when nobody is signed in (tests, previews).
  static const fallbackName = 'Student';

  AppUser? _user;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  String get name {
    final n = _user?.name.trim() ?? '';
    return n.isEmpty ? fallbackName : n;
  }

  String get email => _user?.email ?? '';

  void signIn(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void updateProfile(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    notifyListeners();
  }
}