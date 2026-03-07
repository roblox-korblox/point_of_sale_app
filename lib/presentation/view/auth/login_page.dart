import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginEvent(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Navigation will be handled by main.dart based on user role
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const LoadingWidget();
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.point_of_sale,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSizes.paddingXL),
                      Text(
                        AppStrings.appName,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeXXXL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.paddingXL),
                      CustomTextField(
                        label: AppStrings.username,
                        hint: AppStrings.enterUsername,
                        controller: _usernameController,
                        prefixIcon: const Icon(Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.fieldRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingM),
                      CustomTextField(
                        label: AppStrings.password,
                        hint: AppStrings.enterPassword,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.fieldRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingXL),
                      CustomButton(
                        text: AppStrings.login,
                        onPressed: _handleLogin,
                        icon: Icons.login,
                      ),
                      const SizedBox(height: AppSizes.paddingL),
                      const Text(
                        'Dummy Credentials:\nAdmin: admin / admin123\nUser: user / user123',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

