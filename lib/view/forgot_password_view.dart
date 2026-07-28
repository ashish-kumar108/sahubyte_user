import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/utils/user_session_store.dart';
import 'package:sahubyte_user/view_model/auth_view_model.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key, this.initialMobile = ''});

  final String initialMobile;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _mobileController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authViewModel = AuthViewModel();
  String? _receivedOtp;
  Map<String, dynamic>? _loginResponse;
  bool _otpVerified = false;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController(text: widget.initialMobile);
    _authViewModel.addListener(_refresh);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authViewModel.removeListener(_refresh);
    _authViewModel.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String get _mobile => _mobileController.text.trim();

  bool get _hasValidMobile => RegExp(r'^[0-9]{10}$').hasMatch(_mobile);

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendOtp() async {
    if (!_hasValidMobile) {
      return _message('Please enter a valid 10-digit mobile number.');
    }
    try {
      final response = await _authViewModel.sendOtpLogin(_mobile);
      if (!mounted) return;
      if (!response.isSuccess) return _message(response.displayMessage);
      setState(() {
        _receivedOtp = response.otp;
        _loginResponse = response.raw;
      });
      _message('Recovery OTP sent successfully.');
    } catch (error) {
      _message(
        professionalErrorMessage(
          error,
          fallback: 'OTP could not be verified. Please try again.',
        ),
      );
    }
  }

  void _verifyOtp() {
    if (_receivedOtp == null) {
      return _message('Please request your recovery OTP first.');
    }
    if (_otpController.text.trim() != _receivedOtp) {
      return _message('Please enter the correct OTP.');
    }
    setState(() => _otpVerified = true);
    _message('Mobile verified. Create your new password.');
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (password.length < 6) {
      return _message('Password must be at least 6 characters.');
    }
    if (password != confirmPassword) {
      return _message('New password and confirmation do not match.');
    }

    var userId = UserSessionStore.extractUserId(_loginResponse ?? const {});
    if (userId.isEmpty) {
      userId = await _authViewModel.findUserIdByMobile(_mobile);
      if (!mounted) return;
    }
    if (userId.isEmpty) {
      return _message('No user account was found for this mobile number.');
    }

    try {
      final resetResponse = await _authViewModel.resetPassword(
        userId: userId,
        password: password,
      );
      if (!mounted) return;
      if (!resetResponse.isSuccess) {
        return _message(resetResponse.displayMessage);
      }
      if (!mounted) return;
      Navigator.of(context).pop(_mobile);
    } catch (error) {
      _message(
        professionalErrorMessage(
          error,
          fallback: 'Password could not be updated. Please try again.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      showBack: true,
      centerContent: true,
      eyebrow: 'Account recovery',
      title: 'Recover access\nwith OTP.',
      subtitle:
          'We will verify your registered mobile number and sign you in securely.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFieldLabel('Registered mobile number'),
          TextField(
            controller: _mobileController,
            enabled: !_otpVerified,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Enter 10-digit mobile number',
              prefixIcon: Icon(Icons.phone_iphone_rounded),
            ),
          ),
          const SizedBox(height: 16),
          const AppFieldLabel('Recovery OTP'),
          TextField(
            controller: _otpController,
            enabled: !_otpVerified,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter OTP',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: TextButton(
                onPressed: _authViewModel.isLoading || _otpVerified
                    ? null
                    : _sendOtp,
                child: Text(_receivedOtp == null ? 'Send OTP' : 'Resend'),
              ),
            ),
          ),
          if (_otpVerified) ...[
            const SizedBox(height: 18),
            const AppFieldLabel('New password'),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Create a new password',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
            ),
            const SizedBox(height: 16),
            const AppFieldLabel('Confirm new password'),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter new password again',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
            ),
          ],
          const SizedBox(height: 22),
          AppPrimaryButton(
            label: _authViewModel.isLoading
                ? (_otpVerified ? 'Updating password...' : 'Verifying...')
                : (_otpVerified ? 'Update password' : 'Verify OTP'),
            icon: Icons.arrow_forward_rounded,
            onPressed: _authViewModel.isLoading
                ? null
                : (_otpVerified ? _updatePassword : _verifyOtp),
          ),
        ],
      ),
    );
  }
}
