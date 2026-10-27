import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// OAuth 클라이언트 ID는 빌드 시 `--dart-define`으로 주입한다(README 참고).
/// - GOOGLE_SERVER_CLIENT_ID: '웹 애플리케이션' 유형 클라이언트 ID (Android 필수)
/// - GOOGLE_IOS_CLIENT_ID: 'iOS' 유형 클라이언트 ID (iOS, Info.plist GIDClientID 대신 사용 가능)
const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

/// 요청하는 스코프는 drive.appdata 하나뿐이다.
const kDriveScopes = [drive.DriveApi.driveAppdataScope];

class GoogleAuth {
  /// 이 빌드에 OAuth 클라이언트 ID가 들어 있는지.
  /// `--dart-define-from-file=google_oauth.json` 없이 빌드하면 false다.
  /// (Android는 웹 클라이언트 ID가 없으면 로그인 창을 띄우기 전에 실패한다.)
  static bool get isConfigured =>
      Platform.isIOS ? _iosClientId.isNotEmpty : _serverClientId.isNotEmpty;

  GoogleSignIn get _gsi => GoogleSignIn.instance;
  Future<void>? _init;
  GoogleSignInAccount? _account;

  GoogleSignInAccount? get account => _account;

  Future<void> ensureInitialized() => _init ??= _gsi.initialize(
    clientId: _iosClientId.isEmpty ? null : _iosClientId,
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );

  /// UI 없이 이전 로그인을 복원한다. 실패하면 null.
  Future<GoogleSignInAccount?> restore() async {
    await ensureInitialized();
    try {
      _account = await _gsi.attemptLightweightAuthentication();
    } catch (_) {
      _account = null;
    }
    return _account;
  }

  /// 로그인 + drive.appdata 권한 요청(사용자 상호작용).
  Future<GoogleSignInAccount> signIn() async {
    await ensureInitialized();
    final account = await _gsi.authenticate(scopeHint: kDriveScopes);
    await account.authorizationClient.authorizeScopes(kDriveScopes);
    return _account = account;
  }

  /// Drive API 호출용 클라이언트. [interactive]가 false면 UI 없이 시도하고,
  /// 권한이 없으면 null.
  Future<http.Client?> authClient({bool interactive = false}) async {
    final account = _account;
    if (account == null) return null;
    var authz = await account.authorizationClient.authorizationForScopes(
      kDriveScopes,
    );
    if (authz == null && interactive) {
      authz = await account.authorizationClient.authorizeScopes(kDriveScopes);
    }
    return authz?.authClient(scopes: kDriveScopes);
  }

  Future<void> signOut() async {
    await ensureInitialized();
    _account = null;
    await _gsi.signOut();
  }
}
