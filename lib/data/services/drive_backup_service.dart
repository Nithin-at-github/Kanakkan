import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:kanakkan/data/services/backup_service.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown for any Google Sign-In / Drive authorization failure — the caller
/// (BackupSettingsProvider) surfaces [message] to the user as-is.
class DriveAuthException implements Exception {
  final String message;
  DriveAuthException(this.message);
  @override
  String toString() => message;
}

/// Uploads the app's sqlite DB to the signed-in user's hidden Google Drive
/// "app data" folder, replacing the previous backup in place rather than
/// creating a new file each time.
///
/// Requires a Google Cloud OAuth client to be configured before it will
/// actually authenticate — see the "Platform setup" section of the plan
/// this was built from. [iosClientId]/[webServerClientId] are placeholders
/// until that's done.
class DriveBackupService {
  static final DriveBackupService instance = DriveBackupService._();
  DriveBackupService._();

  // From the Google Cloud project's OAuth clients (Testing publishing status).
  // - _iosClientId: the iOS-type client's ID — the matching CFBundleURLTypes
  //   entry (its reversed form) is set in ios/Runner/Info.plist.
  // - _webServerClientId: the *Web application* type client's ID — on
  //   Android, google_sign_in's Credential Manager flow needs this even
  //   though the app itself is not a web app (see google_sign_in_android's
  //   README). This is NOT the Android OAuth client's own ID.
  static const String _iosClientId =
      '260383784604-5va2skd2s6ej2n3mf737gfls6kg04dc9.apps.googleusercontent.com';
  static const String _webServerClientId =
      '260383784604-cmk68mjat9g0q5ind4g4bi8ktq7vvmao.apps.googleusercontent.com';

  static const _backupFileName = 'kanakkan_backup.db';
  static const _scopes = [drive.DriveApi.driveAppdataScope];

  bool _initialized = false;
  GoogleSignInAccount? _currentUser;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _iosClientId,
      serverClientId: _webServerClientId,
    );
    GoogleSignIn.instance.authenticationEvents.listen((event) {
      _currentUser = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        GoogleSignInAuthenticationEventSignOut() => null,
      };
    });
    _initialized = true;
  }

  /// Silent check — does not prompt the user. Safe to call on every app
  /// start to see whether a previously-granted session is still valid.
  Future<bool> isSignedIn() async {
    await _ensureInitialized();
    if (_currentUser != null) return true;
    try {
      _currentUser = await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (_) {
      _currentUser = null;
    }
    return _currentUser != null;
  }

  /// Interactive sign-in — must be called from a user gesture (e.g. the
  /// Settings toggle). Requests the Drive app-data scope as part of sign-in.
  Future<void> signIn() async {
    await _ensureInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw DriveAuthException("Google sign-in isn't supported on this platform.");
    }
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      throw DriveAuthException('Google sign-in failed: ${e.description ?? e.code}');
    }
    _currentUser = account;

    final authorization = await account.authorizationClient.authorizeScopes(_scopes);
    if (authorization.accessToken.isEmpty) {
      throw DriveAuthException('Google Drive access was not granted.');
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
    _currentUser = null;
  }

  /// Signed-in check + authorized Drive API client, shared by every method
  /// below that actually talks to Drive. Caller must close the returned
  /// client when done.
  Future<(drive.DriveApi, _AuthorizedClient)> _authorizedApi() async {
    await _ensureInitialized();

    var user = _currentUser;
    user ??= await GoogleSignIn.instance.attemptLightweightAuthentication();
    if (user == null) {
      throw DriveAuthException('Not signed in to Google.');
    }
    _currentUser = user;

    final headers = await user.authorizationClient.authorizationHeaders(_scopes);
    if (headers == null) {
      throw DriveAuthException('Google Drive access was not granted.');
    }

    final client = _AuthorizedClient(headers);
    return (drive.DriveApi(client), client);
  }

  Future<String?> _findBackupFileId(drive.DriveApi api) async {
    final existing = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName' and trashed = false",
      $fields: 'files(id)',
    );
    return existing.files?.firstOrNull?.id;
  }

  /// Checkpoints the DB, uploads it to the app-data folder, and deletes the
  /// local temp copy afterwards. Overwrites the existing backup file (found
  /// by name) instead of creating a new one, so there's always exactly one
  /// backup in Drive. Throws [DriveAuthException] if not signed in / not
  /// authorized, or rethrows any Drive API error.
  Future<void> backupNow() async {
    final (api, client) = await _authorizedApi();
    File? localCopy;
    try {
      localCopy = await BackupService.instance.checkpointedCopy();
      final media = drive.Media(localCopy.openRead(), await localCopy.length());

      final existingId = await _findBackupFileId(api);
      if (existingId != null) {
        await api.files.update(drive.File(), existingId, uploadMedia: media);
      } else {
        final metadata = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await api.files.create(metadata, uploadMedia: media);
      }
    } finally {
      client.close();
      if (localCopy != null && await localCopy.exists()) {
        await localCopy.delete();
      }
    }
  }

  /// Downloads the backup from the app-data folder to a fresh temp file and
  /// returns it — caller owns the file and should delete it once done.
  /// Throws [DriveAuthException] if not signed in, or a plain [Exception] if
  /// no backup exists in Drive yet.
  Future<File> downloadLatestBackup() async {
    final (api, client) = await _authorizedApi();
    try {
      final fileId = await _findBackupFileId(api);
      if (fileId == null) {
        throw Exception('No backup found in Google Drive yet.');
      }

      final media =
          await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia)
              as drive.Media;

      final temp = await getTemporaryDirectory();
      final dest = File('${temp.path}/kanakkan_drive_restore.db');
      final sink = dest.openWrite();
      await media.stream.pipe(sink);

      return dest;
    } finally {
      client.close();
    }
  }
}

/// Attaches the Google-provided auth headers to every outgoing request —
/// the standard hand-off pattern from google_sign_in's access token to a
/// plain http.Client that googleapis can use.
class _AuthorizedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  _AuthorizedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
