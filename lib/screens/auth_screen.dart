import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_data.dart';
import '../branding/brand_config.dart';
import '../services/firebase_backend.dart';
import '../widgets/brand_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email दर्ज करें।';
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(email)) return 'मान्य Email दर्ज करें।';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password दर्ज करें।';
    if (password.length < 6) return 'Password कम से कम 6 अक्षर का होना चाहिए।';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_isLogin) return null;
    final confirm = value ?? '';
    if (confirm.isEmpty) return 'Confirm Password दर्ज करें।';
    if (confirm != _passwordController.text) {
      return 'Password और Confirm Password समान नहीं हैं।';
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (!FirebaseBackend.instance.isAvailable) {
        await FirebaseBackend.instance.initialize();
      }

      if (!FirebaseBackend.instance.isAvailable) {
        throw StateError(
          'Firebase is not configured correctly. Please verify the Firebase project and Authentication settings.',
        );
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (kDebugMode) {
        debugPrint(
          'AuthScreen: ${_isLogin ? 'login' : 'register'} request started for email=$email',
        );
      }

      if (_isLogin) {
        final credential = await FirebaseBackend.instance
            .signIn(email: email, password: password)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Login request timed out. Please check your internet connection and try again.',
                );
              },
            );

        final isAdmin = await FirebaseBackend.instance
            .isCurrentUserAdmin()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException(
                  'Admin authorization check timed out. Please try again.',
                );
              },
            );

        if (!isAdmin) {
          await FirebaseBackend.instance.signOut();
          _showMessage('You are not authorized to access the admin portal.');
          return;
        }

        if (kDebugMode) {
          debugPrint(
            'AuthScreen: login success for uid=${credential.user!.uid}, email=${credential.user!.email}',
          );
        }

        if (kDebugMode) {
          debugPrint(
            'AuthScreen: syncing local cloud data for authenticated uid=${credential.user!.uid}',
          );
        }

        await LocalGoshalaStore.instance.syncLocalDataToCloud();
        if (mounted) Navigator.of(context).pop();
      } else {
        final credential = await FirebaseBackend.instance
            .register(email: email, password: password)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Account creation timed out. Please try again.',
                );
              },
            );

        if (credential.user != null && mounted) {
          _showMessage(
            'Account created successfully. Please login with your credentials.',
          );
          setState(() {
            _isLogin = true;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        }

        if (kDebugMode) {
          debugPrint('AuthScreen: registration success for $email');
        }
      }
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'AuthScreen: FirebaseAuthException code=${error.code}, message=${error.message ?? 'null'}',
        );
      }
      _showMessage(FirebaseBackend.userFriendlyAuthError(error));
    } on TimeoutException catch (error) {
      if (kDebugMode) {
        debugPrint('AuthScreen: TimeoutException: ${error.message}');
      }
      _showMessage(error.message ?? 'The request timed out. Please try again.');
    } on SocketException {
      if (kDebugMode) {
        debugPrint('AuthScreen: network error during auth request');
      }
      _showMessage(
        FirebaseBackend.userFriendlyAuthError(
          const SocketException('Network error'),
        ),
      );
    } on StateError catch (error) {
      if (kDebugMode) {
        debugPrint('AuthScreen: StateError: ${error.message}');
      }
      _showMessage(FirebaseBackend.userFriendlyAuthError(error));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AuthScreen: unexpected auth error: $error');
      }
      _showMessage(FirebaseBackend.userFriendlyAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Password reset के लिए Email दर्ज करें।');
      return;
    }
    if (_validateEmail(email) != null) {
      _showMessage('मान्य Email दर्ज करें।');
      return;
    }

    try {
      await FirebaseBackend.instance.auth.sendPasswordResetEmail(email: email);
      _showMessage('Password reset link has been sent to $email.');
    } on FirebaseAuthException catch (error) {
      _showMessage(FirebaseBackend.userFriendlyAuthError(error));
    } on SocketException {
      _showMessage(
        FirebaseBackend.userFriendlyAuthError(
          const SocketException('Network error'),
        ),
      );
    } catch (error) {
      _showMessage(FirebaseBackend.userFriendlyAuthError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _isLogin;

    return Scaffold(
      backgroundColor: BrandConfig.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: BrandLogo(size: 76, showName: true)),
                        const SizedBox(height: 22),
                        Text(
                          isLogin ? 'Login' : 'Create Account',
                          style: const TextStyle(
                            color: BrandConfig.ink,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? 'गौशाला समिति के सुरक्षित admin portal में प्रवेश करें।'
                              : 'नया admin account बनाएं और प्रवेश करें।',
                          style: const TextStyle(
                            color: BrandConfig.muted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !_passwordVisible,
                          textInputAction: isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (!isLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: !_confirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            validator: _validateConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _confirmPasswordVisible =
                                      !_confirmPasswordVisible,
                                ),
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSubmitting ? null : _forgotPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_open_rounded),
                            label: Text(
                              _isSubmitting
                                  ? 'Please wait...'
                                  : (isLogin ? 'Login' : 'Create Account'),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: BrandConfig.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isLogin
                                  ? 'अभी account नहीं है?'
                                  : 'पहले से account है?',
                              style: const TextStyle(color: BrandConfig.muted),
                            ),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => setState(() {
                                      _isLogin = !_isLogin;
                                      _passwordController.clear();
                                      _confirmPasswordController.clear();
                                      _formKey.currentState?.reset();
                                    }),
                              child: Text(
                                isLogin ? 'Create Account' : 'Back to Login',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!FirebaseBackend.instance.isAvailable)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Firebase configuration अभी उपलब्ध नहीं है। कृपया setup सत्यापित करें।',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: BrandConfig.muted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
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
      ),
    );
  }
}
