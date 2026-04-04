import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/repository_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // 사용자가 취소

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (result.additionalUserInfo?.isNewUser == true && result.user != null) {
        await ref.read(userRepositoryProvider).initializeUser(result.user!);
      }
      // GoRouter redirect가 자동으로 '/'로 이동
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google 로그인 실패');
    } catch (e) {
      _showError('로그인 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEmailForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final result =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (result.user != null) {
          await ref.read(userRepositoryProvider).initializeUser(result.user!);
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // GoRouter redirect가 자동으로 '/'로 이동
    } on FirebaseAuthException catch (e) {
      _showError(_authErrorMessage(e.code));
    } catch (e) {
      _showError('로그인 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.body(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다';
      case 'too-many-requests':
        return '잠시 후 다시 시도해주세요';
      default:
        return '로그인 실패: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildGoogleButton(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildEmailForm(),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.accent,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'TodoStory',
          style: AppTextStyles.display(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          '오늘의 할 일을 정리하세요',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          : const Icon(
              Icons.g_mobiledata_rounded,
              color: AppColors.accent,
              size: 22,
            ),
      label: Text(
        'Google로 계속하기',
        style: AppTextStyles.body(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '또는',
            style: AppTextStyles.label(color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: AppTextStyles.body(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '이메일',
              hintStyle: AppTextStyles.body(color: AppColors.textMuted),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요';
              if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitEmailForm(),
            style: AppTextStyles.body(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '비밀번호',
              hintStyle: AppTextStyles.body(color: AppColors.textMuted),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
              if (_isSignUp && v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
              return null;
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submitEmailForm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            child: Text(
              _isSignUp ? '회원가입' : '로그인',
              style: AppTextStyles.body(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp ? '이미 계정이 있어요 → 로그인' : '처음이에요 → 회원가입',
              style: AppTextStyles.body(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
