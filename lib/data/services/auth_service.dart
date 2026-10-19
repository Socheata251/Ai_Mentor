import '../../core/constants/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/user.dart';
import '../repositories/user_session.dart';
import 'storage_service.dart';

/// Register / sign in / sign out against the backend.
/// With --dart-define=USE_BACKEND=false it keeps a local-only profile instead.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _api = ApiClient.instance;

  AppUser _userFrom(Map<String, dynamic> j) => AppUser(
        name: j['name'] as String,
        email: j['email'] as String,
        university: (j['university'] as String?) ?? 'ACLEDA University',
        semester: (j['semester'] as num?)?.toInt() ?? 4,
      );

  Future<AppUser> _finish(Map<String, dynamic> data) async {
    await TokenStorage.instance.save(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    final user = _userFrom(data['user'] as Map<String, dynamic>);
    UserSession.instance.signIn(user);
    return user;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!ApiConfig.useBackend) return _local(name, email);
    final data = await _api.post(
      '/api/auth/register',
      auth: false,
      body: {'name': name, 'email': email, 'password': password},
    );
    return _finish(data as Map<String, dynamic>);
  }

  Future<AppUser> login({required String email, required String password}) async {
    if (!ApiConfig.useBackend) return _local(email.split('@').first, email);
    final data = await _api.post(
      '/api/auth/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    return _finish(data as Map<String, dynamic>);
  }

  AppUser _local(String name, String email) {
    final user = AppUser(name: name, email: email);
    UserSession.instance.signIn(user);
    return user;
  }

  /// Call once at startup. Returns true when a saved login is still valid.
  Future<bool> restoreSession() async {
    if (!ApiConfig.useBackend) return false;
    await TokenStorage.instance.load();
    if (TokenStorage.instance.refreshToken == null) return false;
    try {
      final data = await _api.get('/api/users/me') as Map<String, dynamic>;
      UserSession.instance.signIn(_userFrom(data['user'] as Map<String, dynamic>));
      return true;
    } on ApiException catch (e) {
      // Offline at startup: do not throw the student out.
      if (e.isNetwork && TokenStorage.instance.refreshToken != null) return false;
      await TokenStorage.instance.clear();
      return false;
    }
  }

  Future<void> logout() async {
    final refresh = TokenStorage.instance.refreshToken;
    UserSession.instance.signOut();
    await TokenStorage.instance.clear();
    if (ApiConfig.useBackend && refresh != null) {
      try {
        await _api.post('/api/auth/logout', auth: false, body: {'refreshToken': refresh});
      } catch (_) {
        // Already signed out on this device; the server token expires by itself.
      }
    }
  }

  /// Returns a dev-only reset code when the server runs outside production.
  Future<String?> forgotPassword(String email) async {
    if (!ApiConfig.useBackend) return null;
    final data = await _api.post('/api/auth/forgot-password', auth: false, body: {'email': email});
    return (data as Map<String, dynamic>)['devToken'] as String?;
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _api.post(
      '/api/auth/reset-password',
      auth: false,
      body: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<AppUser> updateProfile({
    required String name,
    required String university,
    required int semester,
  }) async {
    final current = UserSession.instance.user ?? AppUser(name: name, email: '');
    if (!ApiConfig.useBackend) {
      final u = current.copyWith(name: name, university: university, semester: semester);
      UserSession.instance.updateProfile(u);
      return u;
    }
    final data = await _api.patch(
      '/api/users/me',
      body: {'name': name, 'university': university, 'semester': semester},
    ) as Map<String, dynamic>;
    final user = _userFrom(data['user'] as Map<String, dynamic>);
    UserSession.instance.updateProfile(user);
    return user;
  }
}