import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/business_types.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'subscription_screen.dart';
import '../utils/validators.dart';
import '../utils/error_text.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _customBusinessTypeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedBusinessType;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _businessNameController.dispose();
    _customBusinessTypeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final businessType = _selectedBusinessType == kOtherBusinessType
        ? _customBusinessTypeController.text.trim()
        : _selectedBusinessType!;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            businessName: _businessNameController.text.trim(),
            businessType: businessType,
          );

      // Registration succeeded — navigate to subscription placeholder.
      // The auth listener in AuthNotifier will pick up the new session
      // and load the business automatically.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorText(e),
            ),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Set up your business',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your account to start managing inventory and sales.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 32),

                // Business name
                TextFormField(
                  controller: _businessNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Business Name *',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your business name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Business type dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedBusinessType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Business Type *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    ...kBusinessTypes.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const DropdownMenuItem(
                      value: kOtherBusinessType,
                      child: Text(kOtherBusinessType),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBusinessType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a business type';
                    }
                    return null;
                  },
                ),
                if (_selectedBusinessType == kOtherBusinessType) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customBusinessTypeController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Specify Business Type *',
                      prefixIcon: Icon(Icons.edit_outlined),
                      hintText: 'e.g. Pet Salon, Antique Shop',
                    ),
                    validator: (value) {
                      if (_selectedBusinessType == kOtherBusinessType) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please specify your business type';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: validateNewPassword,
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) => validatePasswordConfirmation(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
