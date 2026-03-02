import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/secure_storage.dart';
import 'package:frontend/services/cache_service.dart';
import 'package:frontend/utils/app_snackbar.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({super.key});

  @override
  State<MyLogin> createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  // for role based login
  String _selectedRole = "normal_user";

  final List<String> _roles = ["normal_user", "doctor"];

  /// 🔹 Login with validation
  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 🔴 Validation
    if (email.isEmpty || password.isEmpty) {
      _showError("Email and password are required");
      return;
    }

    if (!email.contains('@')) {
      _showError("Enter a valid email");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('https://skin-buddy.onrender.com/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": _selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SecureStorage.saveToken(data['token']);
        await SecureStorage.saveUserId(data['user']['id']);
        await SecureStorage.saveUserRole(data['user']['role']);
        await SecureStorage.saveIsProfileCompleted(
          data['user']['is_profile_completed'] ?? false,
        );

        // 🔹 GET USER ID
        final userId = data['user']['id'];
        final role = data['user']['role'];

        // 🔹 GET PROFILE COMPLETION STATUS
        final is_profile_completed =
            data['user']['is_profile_completed'] ?? false;

        // 🔹 OPEN USER-SPECIFIC CHAT BOX
        await CacheService.openUserChatBox(userId);

        if (role == "doctor") {
          if (is_profile_completed) {
            Navigator.pushReplacementNamed( context,'doctor_main',arguments: 0,);
            AppSnackbar.showSuccess(context, "Login successfull");
          } else {
            Navigator.pushReplacementNamed(context,'doctor_main', arguments: 1,);
            AppSnackbar.showInfo(context, "Please complete your profile first!");
          }
        } else {
          if (is_profile_completed) {
            Navigator.pushReplacementNamed(context, 'main', arguments: 0);
            AppSnackbar.showSuccess(context, "Login successfull");
          } else {
            Navigator.pushReplacementNamed(context, 'main', arguments: 2);
            AppSnackbar.showInfo(context, "Please complete your profile first!");
          }
        }
      } else {
        // _showError(data['error'] ?? 'Login failed');
        AppSnackbar.showError(context, "Login failed");
      }
    } catch (e) {
      _showError("Server not reachable");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome\nBack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 48 : 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _glassCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  /// Role Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: _inputDecoration("Select Role"),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.replaceAll("_", " ").toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  /// Email
                  TextField(
                    controller: emailController,
                    decoration: _inputDecoration("Email"),
                  ),
                  const SizedBox(height: 20),

                  /// Password (eye button)
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      "Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// Login Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xff4c505b),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                color: Colors.white,
                                onPressed: loginUser,
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// Bottom Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'register');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
