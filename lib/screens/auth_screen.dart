import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_data.dart';
import '../branding/brand_config.dart';
import '../models/app_user.dart';
import '../services/firebase_backend.dart';
import '../widgets/brand_logo.dart';
import 'dashboards/role_dashboard_router.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.redirectOnSuccess = true,
    this.initialRole = UserRole.admin,
  });

  final bool redirectOnSuccess;
  final UserRole initialRole;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late UserRole _selectedLoginRole;
  bool _isLogin = true;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedLoginRole = widget.initialRole;
  }

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
    final stopwatch = Stopwatch()..start();
    debugPrint('[LOGIN_BUTTON_PRESSED] elapsed: ${stopwatch.elapsedMilliseconds}ms');
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    bool signInCompleted = false;

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
        debugPrint('[SIGNIN_START] elapsed: ${stopwatch.elapsedMilliseconds}ms');
        final credential = await FirebaseBackend.instance.signIn(
          email: email,
          password: password,
        );

        final user = credential.user;
        if (user == null) {
          throw StateError('Login failed. User profile could not be found.');
        }
        signInCompleted = true;
        debugPrint(
          '[SIGNIN_SUCCESS] elapsed: ${stopwatch.elapsedMilliseconds}ms, uid: ${user.uid}',
        );

        // Fetch user profile through getCurrentUserProfile with forceRefresh to always get fresh role from Firestore
        debugPrint('[PROFILE_LOAD_START] elapsed: ${stopwatch.elapsedMilliseconds}ms');
        var profile = await FirebaseBackend.instance
            .getCurrentUserProfile(forceRefresh: true)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);

        // Fallback admin check only if profile could not be loaded from users collection
        if (profile == null) {
          final isActualAdmin = await FirebaseBackend.instance
              .isCurrentUserAdmin()
              .timeout(const Duration(seconds: 3), onTimeout: () => false);
          if (isActualAdmin) {
            profile = AppUser(
              uid: user.uid,
              email: user.email ?? email,
              name: user.displayName ?? (email.split('@').first),
              role: UserRole.admin,
              permissions: AppPermission.all,
            );
            unawaited(FirebaseBackend.instance.saveUserProfile(profile));
          } else {
            profile = AppUser(
              uid: user.uid,
              email: user.email ?? email,
              name: user.displayName ?? (email.split('@').first),
              role: UserRole.user,
            );
          }
        }

        debugPrint(
          '[PROFILE_LOAD_SUCCESS] elapsed: ${stopwatch.elapsedMilliseconds}ms, role: ${profile.role.value}',
        );

        if (!profile.isActive) {
          await FirebaseBackend.instance.signOut();
          _showMessage(
            'आपका खाता निष्क्रिय (Disabled) कर दिया गया है। व्यवस्थापक से संपर्क करें।',
          );
          return;
        }

        if (kDebugMode) {
          debugPrint(
            'AuthScreen: login success for uid=${user.uid}, role=${profile.role.value}',
          );
        }

        if (profile.canEditRecords) {
          unawaited(
            LocalGoshalaStore.instance.syncLocalDataToCloud().catchError(
              (Object e) =>
                  debugPrint('AuthScreen: background sync failed: $e'),
            ),
          );
        }

        debugPrint(
          '[ROLE_CHECK_START] elapsed: ${stopwatch.elapsedMilliseconds}ms, requested: ${_selectedLoginRole.value}, actual: ${profile.role.value}',
        );
        if (_selectedLoginRole == UserRole.admin && !profile.isAdmin) {
          await FirebaseBackend.instance.signOut();
          _showMessage(
            'यह खाता व्यवस्थापक (Admin) नहीं है (${profile.role.label})। केवल अधिकृत व्यवस्थापक ही यहाँ लॉगिन कर सकते हैं।',
          );
          return;
        } else if (_selectedLoginRole == UserRole.staff &&
            !profile.isStaff &&
            !profile.isAdmin) {
          await FirebaseBackend.instance.signOut();
          _showMessage(
            'यह खाता Staff नहीं है (${profile.role.label})। केवल अधिकृत कर्मचारी ही यहाँ लॉगिन कर सकते हैं।',
          );
          return;
        } else {
          debugPrint(
            '[ROLE_CHECK_SUCCESS] elapsed: ${stopwatch.elapsedMilliseconds}ms, role: ${profile.role.value}',
          );
          _showMessage('स्वागत है, ${profile.name}! (${profile.role.label})');
        }

        debugPrint(
          '[LOGIN_FLOW_COMPLETE] elapsed: ${stopwatch.elapsedMilliseconds}ms',
        );
        if (mounted) {
          if (widget.redirectOnSuccess) {
            RoleDashboardRouter.openDashboard(context, profile);
          } else {
            Navigator.of(context).pop(profile);
          }
        }
      } else {
        final credential = await FirebaseBackend.instance.register(
          email: email,
          password: password,
        );

        final user = credential.user;
        if (user != null) {
          final newProfile = AppUser(
            uid: user.uid,
            email: user.email ?? email,
            name: email.split('@').first,
            role: UserRole.user,
          );
          await FirebaseBackend.instance.saveUserProfile(newProfile);

          if (mounted) {
            final notice = _selectedLoginRole != UserRole.user
                ? 'खाता सफलतापूर्वक बन गया! (व्यवस्थापक व Staff अधिकार व्यवस्थापक द्वारा प्रदान किए जाते हैं)। कृपया अब लॉगिन करें।'
                : 'खाता सफलतापूर्वक बन गया! कृपया लॉगिन करें।';
            _showMessage(notice);
            setState(() {
              _isLogin = true;
              _passwordController.clear();
              _confirmPasswordController.clear();
            });
          }
        }

        if (kDebugMode) {
          debugPrint('AuthScreen: registration success for $email');
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!signInCompleted) {
        debugPrint(
          '[SIGNIN_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, code: ${error.code}, message: ${error.message}',
        );
      } else {
        debugPrint(
          '[PROFILE_LOAD_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, code: ${error.code}, message: ${error.message}',
        );
      }
      debugPrint(
        'LOGIN: FirebaseAuthException code=${error.code} message=${error.message}',
      );

      final String message;
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
          message =
              'गलत Email अथवा Password दर्ज किया गया है। कृपया पुनः जाँच कर प्रयास करें।';
          break;
        case 'user-not-found':
          message =
              'इस Email से कोई खाता नहीं मिला। कृपया सही Email डालें या नया खाता बनाएं।';
          break;
        case 'user-disabled':
          message =
              'यह खाता निष्क्रिय (Disabled) कर दिया गया है। व्यवस्थापक से संपर्क करें।';
          break;
        case 'too-many-requests':
          message =
              'बहुत अधिक असफल प्रयास किए गए हैं। कृपया कुछ समय बाद पुनः प्रयास करें।';
          break;
        case 'operation-not-allowed':
          message =
              'Firebase में Email/Password लॉगिन सेवा सक्षम नहीं है। व्यवस्थापक से संपर्क करें।';
          break;
        case 'network-request-failed':
          message =
              'इंटरनेट कनेक्शन में समस्या है या सर्वर से संपर्क नहीं हो सका। कृपया नेटवर्क जांचें।';
          break;
        case 'invalid-email':
          message = 'अमान्य Email पता दर्ज किया गया है (Invalid email)।';
          break;
        case 'email-already-in-use':
          message =
              'यह Email पहले से पंजीकृत है। कृपया लॉगिन करें या दूसरा Email उपयोग करें।';
          break;
        case 'weak-password':
          message = 'Password बहुत कमजोर है। कम से कम 6 अक्षरों का उपयोग करें।';
          break;
        case 'requires-recent-login':
          message = 'सत्र पुराना हो चुका है। कृपया दोबारा लॉगिन करें।';
          break;
        default:
          message = error.message != null && error.message!.trim().isNotEmpty
              ? error.message!.trim()
              : FirebaseBackend.userFriendlyAuthError(error);
      }
      _showMessage(message);
    } on FirebaseException catch (error) {
      if (!signInCompleted) {
        debugPrint(
          '[SIGNIN_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, code: ${error.code}, message: ${error.message}',
        );
      } else {
        debugPrint(
          '[PROFILE_LOAD_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, code: ${error.code}, message: ${error.message}',
        );
      }
      debugPrint('LOGIN: Exception $error');
      _showMessage(FirebaseBackend.userFriendlyAuthError(error));
    } on TimeoutException catch (error) {
      if (!signInCompleted) {
        debugPrint(
          '[SIGNIN_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, Timeout: ${error.message}',
        );
      } else {
        debugPrint(
          '[PROFILE_LOAD_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, Timeout: ${error.message}',
        );
      }
      debugPrint('LOGIN: Exception $error');
      _showMessage(
        error.message ??
            'अनुरोध का समय समाप्त हो गया (Timeout)। कृपया पुनः प्रयास करें।',
      );
    } on SocketException {
      if (!signInCompleted) {
        debugPrint(
          '[SIGNIN_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, SocketException',
        );
      } else {
        debugPrint(
          '[PROFILE_LOAD_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, SocketException',
        );
      }
      debugPrint('LOGIN: Exception SocketException');
      _showMessage(
        FirebaseBackend.userFriendlyAuthError(
          const SocketException('Network error'),
        ),
      );
    } on StateError catch (error) {
      if (!signInCompleted) {
        debugPrint(
          '[SIGNIN_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, StateError: ${error.message}',
        );
      } else {
        debugPrint(
          '[PROFILE_LOAD_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, StateError: ${error.message}',
        );
      }
      debugPrint('LOGIN: Exception $error');
      _showMessage(FirebaseBackend.userFriendlyAuthError(error));
    } catch (error) {
      if (!signInCompleted) {
        debugPrint(
          '[SIGNIN_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, error: $error',
        );
      } else {
        debugPrint(
          '[PROFILE_LOAD_ERROR] elapsed: ${stopwatch.elapsedMilliseconds}ms, error: $error',
        );
      }
      debugPrint('LOGIN: Exception $error');
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
                              ? 'गौशाला समिति के सुरक्षित पोर्टल में प्रवेश करें।'
                              : 'नया खाता बनाएं और सेवा से जुड़ें।',
                          style: const TextStyle(
                            color: BrandConfig.muted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'लॉगिन प्रकार चुनें (Select Login Portal)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BrandConfig.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _RoleSelectCard(
                                label: 'Admin Login',
                                sublabel: 'व्यवस्थापक',
                                icon: Icons.admin_panel_settings_outlined,
                                isSelected:
                                    _selectedLoginRole == UserRole.admin,
                                color: BrandConfig.primary,
                                onTap: () => setState(
                                  () => _selectedLoginRole = UserRole.admin,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RoleSelectCard(
                                label: 'Staff Login',
                                sublabel: 'कर्मचारी',
                                icon: Icons.badge_outlined,
                                isSelected:
                                    _selectedLoginRole == UserRole.staff,
                                color: const Color(0xFFC97A2E),
                                onTap: () => setState(
                                  () => _selectedLoginRole = UserRole.staff,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RoleSelectCard(
                                label: 'User Login',
                                sublabel: 'श्रद्धालु',
                                icon: Icons.person_outline_rounded,
                                isSelected: _selectedLoginRole == UserRole.user,
                                color: const Color(0xFF2C6BB3),
                                onTap: () => setState(
                                  () => _selectedLoginRole = UserRole.user,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(
                              _selectedLoginRole,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getRoleColor(
                                _selectedLoginRole,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 15,
                                color: _getRoleColor(_selectedLoginRole),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getRoleHelpText(_selectedLoginRole),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getRoleColor(_selectedLoginRole),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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

  Color _getRoleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => BrandConfig.primary,
      UserRole.staff => const Color(0xFFC97A2E),
      UserRole.user => const Color(0xFF2C6BB3),
    };
  }

  String _getRoleHelpText(UserRole role) {
    return switch (role) {
      UserRole.admin =>
        'व्यवस्थापक (Admin) पोर्टल — सम्पूर्ण प्रशासनिक नियंत्रण एवं सेटिंग्स',
      UserRole.staff =>
        'कर्मचारी (Staff) पोर्टल — दैनिक गौसेवा, चारा वितरण व पशु रिकॉर्ड',
      UserRole.user =>
        'श्रद्धालु (User) पोर्टल — ऑनलाइन गौ-सेवा दान, दर्शन व सामान्य जानकारी',
    };
  }
}

class _RoleSelectCard extends StatelessWidget {
  const _RoleSelectCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.09)
              : const Color(0xFFF7FAF6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E7DE),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? color : BrandConfig.muted),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : BrandConfig.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : BrandConfig.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
