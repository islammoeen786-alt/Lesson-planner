import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/error_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final bool success;
    if (_isRegistering) {
      success = await auth.register(_nameController.text, _emailController.text, _passwordController.text);
    } else {
      success = await auth.login(_emailController.text, _passwordController.text);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (auth.appError != null) {
        ErrorSnackbar.show(context, auth.appError!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [AppColors.primary.withValues(alpha: 0.05), theme.scaffoldBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.school, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text('Smart Lesson Planner', style: theme.textTheme.displaySmall?.copyWith(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 6),
                      Text(_isRegistering ? 'Create your account' : 'Welcome back!', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 36),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              if (_isRegistering) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email address.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters.' : null,
                              ),
                              const SizedBox(height: 24),
                              Consumer<AuthProvider>(
                                builder: (_, auth, __) => LoadingButton(
                                  isLoading: auth.status == AuthStatus.loading || _isSubmitting,
                                  onPressed: _submit,
                                  label: _isRegistering ? 'Create Account' : 'Sign In',
                                  loadingLabel: _isRegistering ? 'Creating account...' : 'Signing in...',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => setState(() {
                          _isRegistering = !_isRegistering;
                          _animController.reset();
                          _animController.forward();
                        }),
                        child: RichText(
                          text: TextSpan(
                            text: _isRegistering ? 'Already have an account? ' : "Don't have an account? ",
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
                            children: [
                              TextSpan(text: _isRegistering ? 'Sign In' : 'Register', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
