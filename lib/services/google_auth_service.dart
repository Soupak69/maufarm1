import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<bool> signInWithGoogle() async {
    final clientId = dotenv.env['ANDROID_CLIENT_ID'];
    final serverClientId = dotenv.env['WEB_CLIENT_ID'];

    if (clientId == null || serverClientId == null) {
      throw AuthException('Missing Google client configuration.');
    }

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw AuthException('Missing Google ID token.');
    }

    final authorization = await googleUser.authorizationClient
            .authorizationForScopes(['email', 'profile']) ??
        await googleUser.authorizationClient
            .authorizeScopes(['email', 'profile']);

    final accessToken = authorization.accessToken;

    final authResponse = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = authResponse.user;
    if (user != null) {
      final userId = user.id;
      final fullName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '';

      await Supabase.instance.client.from('user_profile').upsert({
        'id': userId,
        'username': fullName,
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id'); 
    }

    return true;
  }
}
