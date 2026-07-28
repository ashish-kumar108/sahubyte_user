import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/utils/user_session_store.dart';
import 'package:sahubyte_user/view/home_view.dart';
import 'package:sahubyte_user/view_model/auth_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({
    super.key,
    required this.mobile,
    this.returnOnSuccess = false,
    this.asSheet = false,
  });

  final String mobile;
  final bool returnOnSuccess;
  final bool asSheet;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
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
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _authViewModel.removeListener(_refresh);
    _authViewModel.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (date == null) return;
    _dobController.text =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final dob = _dobController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || dob.isEmpty) {
      return _message('Please complete all signup details.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return _message('Please enter a valid email address.');
    }
    if (password.length < 6) {
      return _message('Password must be at least 6 characters.');
    }
    try {
      final response = await _authViewModel.signup(
        mobile: widget.mobile,
        email: email,
        name: name,
        dob: dob,
        password: password,
      );
      if (!mounted) return;
      if (!response.isSuccess) return _message(response.displayMessage);
      final prefs = await SharedPreferences.getInstance();
      await UserSessionStore.saveLoggedInUser(
        prefs: prefs,
        mobile: widget.mobile,
        raw: response.raw,
        fallbackName: name,
        fallbackEmail: email,
        fallbackDob: dob,
      );
      if (!mounted) return;
      if (widget.returnOnSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
        (_) => false,
      );
    } catch (error) {
      _message(
        professionalErrorMessage(
          error,
          fallback: 'Account could not be created. Please try again.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFieldLabel('Full name'),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('Email address'),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('Verified mobile number'),
        TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: widget.mobile,
            prefixIcon: const Icon(Icons.verified_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('Date of birth'),
        TextField(
          controller: _dobController,
          readOnly: true,
          onTap: _selectDob,
          decoration: const InputDecoration(
            hintText: 'Select date of birth',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
        ),
        const SizedBox(height: 22),
        const AppFieldLabel('Password'),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Create password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 22),
        AppPrimaryButton(
          label: _authViewModel.isLoading
              ? 'Creating account...'
              : 'Create my account',
          icon: Icons.check_circle_outline_rounded,
          onPressed: _authViewModel.isLoading ? null : _signup,
        ),
      ],
    );
    if (widget.asSheet) {
      return AuthSheetShell(
        title: 'Complete profile',
        subtitle: 'Add your details and create a password.',
        children: [form],
      );
    }
    return AuthPageShell(
      showBack: true,
      eyebrow: 'Step 2 of 2',
      title: 'Almost done.\nTell us about you.',
      subtitle:
          'These details help us personalize your service requests and booking updates.',
      child: form,
    );
  }
}
