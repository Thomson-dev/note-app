import 'package:firebase_auth/firebase_auth.dart';

class EmailService {
  static const int _verificationTimeoutMinutes = 30;
  static DateTime? _lastVerificationSent;

  static Future<void> sendVerificationEmail(User user) async {
    try {
      // Send verification email
      await user.sendEmailVerification();
      _lastVerificationSent = DateTime.now();
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> checkEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reload user to get latest email verification status
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static bool isVerificationExpired() {
    if (_lastVerificationSent == null) return false;

    final difference = DateTime.now().difference(_lastVerificationSent!);
    return difference.inMinutes >= _verificationTimeoutMinutes;
  }

  static String getTimeRemaining() {
    if (_lastVerificationSent == null) return '';

    final difference = DateTime.now().difference(_lastVerificationSent!);
    final remainingMinutes = _verificationTimeoutMinutes - difference.inMinutes;

    if (remainingMinutes <= 0) return 'Expired';
    return '$remainingMinutes minutes';
  }

  static void resetVerificationTimer() {
    _lastVerificationSent = null;
  }
}
