import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/utils/user_session_store.dart';
import 'package:sahubyte_user/view/forgot_password_view.dart';
import 'package:sahubyte_user/view/home_view.dart';
import 'package:sahubyte_user/view/signup_view.dart';
import 'package:sahubyte_user/view_model/auth_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    this.returnOnSuccess = false,
    this.asSheet = false,
  });

  final bool returnOnSuccess;
  final bool asSheet;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authViewModel = AuthViewModel();

  @override
  void initState() {
    super.initState();
    _authViewModel.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _authViewModel.removeListener(_refresh);
    _authViewModel.dispose();
    super.dispose();
  }

  String get _mobile => _mobileController.text.trim();
  bool get _hasValidMobile => RegExp(r'^[0-9]{10}$').hasMatch(_mobile);

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _login() async {
    if (!_hasValidMobile) {
      return _message('Please enter a valid 10-digit mobile number.');
    }
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      return _message('Please enter your password.');
    }
    try {
      final response = await _authViewModel.login(
        mobile: _mobile,
        password: password,
      );
      if (!mounted) return;
      if (!response.isSuccess) return _message(response.displayMessage);
      final prefs = await SharedPreferences.getInstance();
      await UserSessionStore.saveLoggedInUser(
        prefs: prefs,
        mobile: _mobile,
        raw: response.raw,
      );
      _completeAuthentication();
    } catch (error) {
      _message(
        professionalErrorMessage(
          error,
          fallback: 'Login could not be completed. Please try again.',
        ),
      );
    }
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await UserSessionStore.saveGuestSession(prefs);
    _goHome();
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  void _completeAuthentication() {
    if (widget.returnOnSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    _goHome();
  }

  Future<void> _openSignup() async {
    if (widget.asSheet) {
      final signedUp = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.navyDark.withValues(alpha: .42),
        builder: (_) => const FractionallySizedBox(
          heightFactor: .92,
          child: SignupView(returnOnSuccess: true, asSheet: true),
        ),
      );
      if (!mounted || signedUp != true) return;
      Navigator.of(context).pop(true);
      return;
    }
    final signedUp = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SignupView(returnOnSuccess: widget.returnOnSuccess),
      ),
    );
    if (!mounted || signedUp != true) return;
    _completeAuthentication();
  }

  Future<void> _openForgotPassword() async {
    final recoveredMobile = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordView(initialMobile: _mobile),
      ),
    );
    if (!mounted || recoveredMobile == null) return;
    _mobileController.text = recoveredMobile;
    _passwordController.clear();
    _message('Password updated. Login with your new password.');
  }

  @override
  Widget build(BuildContext context) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFieldLabel('Mobile number'),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter 10-digit mobile number',
            prefixIcon: Icon(Icons.phone_iphone_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('Password'),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _openForgotPassword,
            child: const Text('Forgot or do not have a password?'),
          ),
        ),
        const SizedBox(height: 10),
        AppPrimaryButton(
          label: 'Login',
          icon: Icons.arrow_forward_rounded,
          onPressed: _authViewModel.isLoading ? null : _login,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'New to Sahubyte? ',
              style: TextStyle(color: AppColors.muted),
            ),
            TextButton(
              onPressed: _openSignup,
              child: const Text('Create account'),
            ),
          ],
        ),
      ],
    );
    if (widget.asSheet) {
      return AuthSheetShell(
        title: 'Login to continue',
        subtitle: 'Use your mobile number and password to submit booking.',
        children: [form],
      );
    }
    return AuthPageShell(
      eyebrow: 'Welcome back',
      title: 'Your tech support\nis one tap away.',
      subtitle: 'Sign in securely with your mobile number and password.',
      centerContent: true,
      footer: widget.returnOnSuccess
          ? null
          : TextButton(
              onPressed: _continueAsGuest,
              child: const Text('Continue as guest'),
            ),
      child: form,
    );
  }
}
