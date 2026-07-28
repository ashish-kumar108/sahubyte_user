import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/register_view.dart';
import 'package:sahubyte_user/view_model/auth_view_model.dart';

class SignupView extends StatefulWidget {
  const SignupView({
    super.key,
    this.returnOnSuccess = false,
    this.asSheet = false,
  });

  final bool returnOnSuccess;
  final bool asSheet;
  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _authViewModel = AuthViewModel();
  String? _receivedOtp;

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
    _otpController.dispose();
    _authViewModel.removeListener(_refresh);
    _authViewModel.dispose();
    super.dispose();
  }

  String get _mobile => _mobileController.text.trim();
  bool get _validMobile => RegExp(r'^[0-9]{10}$').hasMatch(_mobile);
  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _sendOtp() async {
    if (!_validMobile) {
      return _message('Please enter a valid 10-digit mobile number.');
    }
    try {
      final response = await _authViewModel.signupOtp(_mobile);
      if (!mounted) return;
      if (!response.isSuccess) return _message(response.displayMessage);
      setState(() => _receivedOtp = response.otp);
      _message('OTP sent successfully.');
    } catch (error) {
      _message(
        professionalErrorMessage(
          error,
          fallback: 'OTP could not be sent. Please try again.',
        ),
      );
    }
  }

  Future<void> _continue() async {
    if (!_validMobile) {
      return _message('Please enter a valid 10-digit mobile number.');
    }
    if (_receivedOtp == null) return _message('Please request your OTP first.');
    if (_otpController.text.trim() != _receivedOtp) {
      return _message('Please enter the correct OTP.');
    }
    if (!context.mounted) return;
    final registered = widget.asSheet
        ? await showModalBottomSheet<bool>(
            // ignore: use_build_context_synchronously
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: AppColors.navyDark.withValues(alpha: .42),
            builder: (_) => FractionallySizedBox(
              heightFactor: .92,
              child: RegisterView(
                mobile: _mobile,
                returnOnSuccess: true,
                asSheet: true,
              ),
            ),
          )
        : await Navigator.push<bool>(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (_) => RegisterView(
                mobile: _mobile,
                returnOnSuccess: widget.returnOnSuccess,
              ),
            ),
          );
    if (!mounted || registered != true) return;
    Navigator.of(context).pop(true);
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
        const AppFieldLabel('One-time password'),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter OTP',
            prefixIcon: const Icon(Icons.verified_user_outlined),
            suffixIcon: TextButton(
              onPressed: _authViewModel.isLoading ? null : _sendOtp,
              child: Text(_authViewModel.isLoading ? 'Sending' : 'Send OTP'),
            ),
          ),
        ),
        const SizedBox(height: 22),
        AppPrimaryButton(
          label: 'Continue to details',
          icon: Icons.arrow_forward_rounded,
          onPressed: _continue,
        ),
      ],
    );
    if (widget.asSheet) {
      return AuthSheetShell(
        title: 'Create account',
        subtitle: 'Verify your mobile number before booking submission.',
        children: [form],
      );
    }
    return AuthPageShell(
      showBack: true,
      centerContent: true,
      eyebrow: 'Step 1 of 2',
      title: 'Let us get you\nverified.',
      subtitle:
          'Create your account with your mobile number. We will send a quick OTP to confirm it is you.',
      child: form,
    );
  }
}
