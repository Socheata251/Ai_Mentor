import '../../core/constants/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/user.dart';
import '../repositories/user_session.dart';
import 'storage_service.dart';

/// Result of the first sign-up step. With the backend, [user] is null and the
/// student must type the 6-digit code that was emailed. [devCode] only exists
/// while the server has no email set up (development).
class RegisterResult {
  const RegisterResult({this.user, this.devCode});
  final AppUser? user;
  final String? devCode;
}

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

  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!ApiConfig.useBackend) return RegisterResult(user: _local(name, email));
    final data = await _api.post(
      '/api/auth/register',
      auth: false,
      body: {'name': name, 'email': email, 'password': password},
    ) as Map<String, dynamic>;
    return RegisterResult(devCode: data['devCode'] as String?);
  }

  /// Step 2 of sign-up: the 6-digit code from the email. Success = signed in.
  Future<AppUser> verifyEmail({required String email, required String code}) async {
    final data = await _api.post(
      '/api/auth/verify-email',
      auth: false,
      body: {'email': email, 'code': code},
    );
    return _finish(data as Map<String, dynamic>);
  }

  /// Sends a new code. purpose: 'verify' (sign-up) or 'reset' (forgot password).
  /// Returns a dev-only code when the server has no email set up.
  Future<String?> resendCode(String email, {String purpose = 'verify'}) async {
    final data = await _api.post(
      '/api/auth/resend-code',
      auth: false,
      body: {'email': email, 'purpose': purpose},
    ) as Map<String, dynamic>;
    return data['devCode'] as String?;
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

  /// Emails a 6-digit reset code. Returns a dev-only code when the server has no email set up.
  Future<String?> forgotPassword(String email) async {
    if (!ApiConfig.useBackend) return null;
    final data = await _api.post('/api/auth/forgot-password', auth: false, body: {'email': email});
    return (data as Map<String, dynamic>)['devCode'] as String?;
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.post(
      '/api/auth/reset-password',
      auth: false,
      body: {'email': email, 'code': code, 'newPassword': newPassword},
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