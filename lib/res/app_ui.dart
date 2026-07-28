import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String professionalErrorMessage(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  var message = error?.toString().trim() ?? '';
  message = message
      .replaceFirst(RegExp(r'^(Exception:\s*)+', caseSensitive: false), '')
      .replaceFirst(
        RegExp(r'^(Communication Error:\s*)+', caseSensitive: false),
        '',
      )
      .replaceFirst(RegExp(r'^(Server Error:\s*)+', caseSensitive: false), '')
      .trim();
  final lower = message.toLowerCase();
  if (message.isEmpty) return fallback;
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection refused')) {
    return 'Please check your internet connection and try again.';
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'The request took too long. Please try again.';
  }
  if (lower.contains('unknown column') ||
      lower.contains('sqlstate') ||
      lower.contains('database')) {
    return 'This service is being updated. Please try again shortly.';
  }
  if (lower.contains('formatexception') ||
      lower.contains('unexpected character')) {
    return 'We received an invalid response. Please refresh and try again.';
  }
  if (lower.contains('error: 404')) {
    return 'This service is currently unavailable. Please try again later.';
  }
  if (lower == 'server error' || lower.contains('internal server error')) {
    return 'The server is temporarily unavailable. Please try again shortly.';
  }
  return message.length > 180 ? fallback : message;
}

class AppColors {
  static const navy = Color(0xFF17213C);
  static const navyDark = Color(0xFF0A1022);
  static const primary = Color(0xFF6D5DFB);
  static const primaryDark = Color(0xFF5547E8);
  static const aqua = Color(0xFF69E6C5);
  static const coral = Color(0xFFFF8B72);
  static const sky = Color(0xFFF0EFFF);
  static const background = Color(0xFFF7F7FC);
  static const surface = Colors.white;
  static const text = Color(0xFF1B2138);
  static const muted = Color(0xFF7A8198);
  static const line = Color(0xFFEAEBF3);
  static const success = Color(0xFF1FBA8A);
}

const appGradient = LinearGradient(
  colors: [AppColors.navyDark, AppColors.navy, AppColors.primary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navyDark,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF9F9FD),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: AppColors.primary),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
    ),
    dividerColor: AppColors.line,
  );
}

class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppPageHeader({
    super.key,
    this.title,
    this.showBack = true,
    this.showCart = false,
  });

  final String? title;
  final bool showBack;
  final bool showCart;

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 70,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.maybePop(context),
            )
          : const Padding(
              padding: EdgeInsets.only(left: 16),
              child: CircleAvatar(
                backgroundColor: Color(0x22FFFFFF),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  color: AppColors.aqua,
                  size: 20,
                ),
              ),
            ),
      title: title == null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset('assets/sahubyte_logo.png', height: 25),
            )
          : Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis),
      centerTitle: title == null,
      actions: [
        if (showCart)
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your service cart is empty.')),
            ),
          ),
        const SizedBox(width: 6),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller!.clear();
                  onChanged?.call('');
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
      ),
    );
  }
}

class AppSearchEmptyState extends StatelessWidget {
  const AppSearchEmptyState({
    super.key,
    required this.query,
    required this.label,
    required this.onClear,
  });

  final String query;
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 34, 16, 24),
    children: [
      AppSurfaceCard(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 42,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              'No $label found',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'No result matches “${query.trim()}”. Try another keyword.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    ],
  );
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: appSurface(
        radius: radius,
        color: color,
        borderColor: borderColor,
      ),
      child: child,
    );
  }
}

class AppScreenIntro extends StatelessWidget {
  const AppScreenIntro({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onHero = _AppHeroTextScope.maybeOf(context)?.onHero ?? false;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: onHero ? Colors.white : AppColors.sky,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(child: AppSectionTitle(title, subtitle: subtitle)),
      ],
    );
  }
}

class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: margin,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: appGradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x242E245F),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: _AppHeroTextScope(child: child),
  );
}

class _AppHeroTextScope extends InheritedWidget {
  const _AppHeroTextScope({required super.child});

  final bool onHero = true;

  static _AppHeroTextScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppHeroTextScope>();
  }

  @override
  bool updateShouldNotify(_AppHeroTextScope oldWidget) => false;
}

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.showBack = false,
    this.centerContent = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.navyDark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF30336B),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navyDark, AppColors.navy, Color(0xFF30336B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SizedBox.expand(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 14 : 20,
                      16,
                      compact ? 14 : 20,
                      28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 44,
                      ),
                      child: Column(
                        mainAxisAlignment: centerContent
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (showBack)
                                IconButton.filledTonal(
                                  onPressed: () => Navigator.maybePop(context),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                              if (showBack) const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Image.asset(
                                  'assets/sahubyte_logo.png',
                                  height: 32,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 24 : 38),
                          _buildContent(compact),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool compact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AppColors.aqua,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 27 : 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 26),
        Container(
          padding: EdgeInsets.all(compact ? 15 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
        if (footer != null) ...[
          const SizedBox(height: 20),
          Center(child: footer!),
        ],
      ],
    );
  }
}

class AuthSheetShell extends StatelessWidget {
  const AuthSheetShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Image.asset(
                        'assets/sahubyte_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: backgroundColor == null && foregroundColor == null
            ? null
            : ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                disabledBackgroundColor: backgroundColor?.withValues(
                  alpha: .55,
                ),
                disabledForegroundColor: foregroundColor?.withValues(
                  alpha: .85,
                ),
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final onHero = _AppHeroTextScope.maybeOf(context)?.onHero ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: onHero ? Colors.white : AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: TextStyle(
              color: onHero ? const Color(0xCCFFFFFF) : AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class AppBookingHero extends StatelessWidget {
  const AppBookingHero({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.totalSteps = 8,
    this.eyebrow = 'SERVICE BOOKING',
  });

  final int step;
  final int totalSteps;
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: appGradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x242E245F),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.aqua, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xAAFFFFFF),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'STEP $step OF $totalSteps',
              style: const TextStyle(
                color: AppColors.aqua,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: step / totalSteps,
            minHeight: 3,
            backgroundColor: const Color(0x33FFFFFF),
            valueColor: const AlwaysStoppedAnimation(AppColors.aqua),
          ),
        ),
      ],
    ),
  );
}

class AppBottomAction extends StatelessWidget {
  const AppBottomAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stackActions =
            secondaryLabel != null && constraints.maxWidth < 360;
        final primary = ElevatedButton.icon(
          onPressed: onPressed,
          icon: const SizedBox.shrink(),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18),
            ],
          ),
        );
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: stackActions
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: double.infinity, child: primary),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondaryPressed,
                        child: Text(
                          secondaryLabel!,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (secondaryLabel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSecondaryPressed,
                          child: Text(
                            secondaryLabel!,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: secondaryLabel == null ? 1 : 2,
                      child: primary,
                    ),
                  ],
                ),
        );
      },
    ),
  );
}

class AppSelectionTile extends StatelessWidget {
  const AppSelectionTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.sky : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: .12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.navy,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
            color: selected ? AppColors.primary : AppColors.muted,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 14,
    this.margin,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + (_controller.value * 2.4), 0),
              end: Alignment(0.2 + (_controller.value * 2.4), 0),
              colors: const [
                Color(0xFFE9EAF5),
                Color(0xFFF9F9FE),
                Color(0xFFE9EAF5),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({
    super.key,
    this.itemCount = 4,
    this.padding = const EdgeInsets.all(16),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 54, height: 54, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: MediaQuery.sizeOf(context).width * 0.48,
                    height: 14,
                  ),
                  const SizedBox(height: 10),
                  const SkeletonBox(width: double.infinity, height: 10),
                  const SizedBox(height: 8),
                  SkeletonBox(
                    width: MediaQuery.sizeOf(context).width * 0.36,
                    height: 10,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(child: SkeletonBox(height: 38, radius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 38, radius: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonInlineLoader extends StatelessWidget {
  const SkeletonInlineLoader({super.key, this.labelWidth = 120});

  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SkeletonBox(width: 28, height: 28, radius: 10),
        const SizedBox(width: 10),
        SkeletonBox(width: labelWidth, height: 12, radius: 8),
      ],
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, this.currentIndex = 0, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: compact ? 68 : 76,
      elevation: 12,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.sky,
      labelBehavior: compact
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note_rounded),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront_rounded),
          label: 'Store',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

BoxDecoration appSurface({
  double radius = 18,
  Color? color,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.line),
    boxShadow: const [
      BoxShadow(
        color: Color(0x120A1022),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
  );
}
