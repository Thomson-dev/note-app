import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/email_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCount = 0;
  final int _maxResendAttempts = 3;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    // Start periodic verification check
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkEmailVerification();
      }
    });
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = EmailService.getTimeRemaining();
    });
  }

  Future<void> _checkEmailVerification() async {
    setState(() => _isLoading = true);
    try {
      final isVerified = await EmailService.checkEmailVerification();

      if (isVerified) {
        EmailService.resetVerificationTimer();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox.'),
            ),
          );
          // Continue checking
          _startVerificationCheck();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error checking verification status')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCount >= _maxResendAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum resend attempts reached. Please try again later.',
          ),
        ),
      );
      return;
    }

    if (EmailService.isVerificationExpired()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification link has expired. Please request a new one.',
          ),
        ),
      );
      return;
    }

    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await EmailService.sendVerificationEmail(user);
        setState(() => _resendCount++);
        _updateTimeRemaining();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification email sent. Please check your inbox.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sending verification email')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Verify your email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'We have sent you a verification email. '
              'Please check your inbox and click the verification link.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            if (_timeRemaining.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Link expires in: $_timeRemaining',
                style: TextStyle(
                  color: _timeRemaining == 'Expired' ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (_resendCount < _maxResendAttempts &&
                !EmailService.isVerificationExpired()) ...[
              ElevatedButton(
                onPressed: _isResending ? null : _resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child:
                    _isResending
                        ? const CircularProgressIndicator()
                        : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 16),
              Text(
                'Resend attempts remaining: ${_maxResendAttempts - _resendCount}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkEmailVerification,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('I have verified my email'),
            ),
          ],
        ),
      ),
    );
  }
}
