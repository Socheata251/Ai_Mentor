import 'package:flutter/foundation.dart';

/// App settings that the AI chat / code screens can read too, e.g.
///
///   if (appSettings.hintsFirst) { /* give a hint, not the full answer */ }
///
/// This is in memory only. To keep values after the app closes, save them
/// with the shared_preferences package inside the setters below.
class SettingsController extends ChangeNotifier {
  // ---- Options shown in the pickers (edit freely) ----
  static const languages = ['English', 'Khmer'];
  static const aiModels = ['IT Mentor v2', 'IT Mentor v2 Fast', 'IT Mentor v1'];
  static const codeFormats = ['Auto', '2 spaces', '4 spaces', 'Tabs'];

  // ---- Current values (defaults match your design) ----
  String language = 'Khmer';
  bool hintsFirst = true;
  String aiModel = 'IT Mentor v2';
  String codeFormat = 'Auto';

  void setLanguage(String v) {
    if (v == language) return;
    language = v;
    notifyListeners();
  }

  void setHintsFirst(bool v) {
    if (v == hintsFirst) return;
    hintsFirst = v;
    notifyListeners();
  }

  void setAiModel(String v) {
    if (v == aiModel) return;
    aiModel = v;
    notifyListeners();
  }

  void setCodeFormat(String v) {
    if (v == codeFormat) return;
    codeFormat = v;
    notifyListeners();
  }
}

/// One shared instance for the whole app.
final SettingsController appSettings = SettingsController();
