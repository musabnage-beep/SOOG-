import 'user.dart';

class AuthResult {
  AuthResult({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// The answer to `/auth/register`: no session yet, just the number the SMS code
/// went to. Tokens only arrive once that code is verified.
class OtpChallenge {
  const OtpChallenge({required this.target, required this.purpose});

  final String target;
  final String purpose;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
        target: json['target'] as String,
        purpose: json['purpose'] as String,
      );
}
