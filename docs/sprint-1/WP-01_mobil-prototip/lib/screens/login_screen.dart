import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Brand colors shared across the app
  static const Color ikuRed = Color(0xFFD31018);
  static const Color ikuGrey = Color(0xFF4A4A49);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          // ConstrainedBox + IntrinsicHeight allows Spacer to work
          // while still permitting scroll on small screens
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // University logo
                  Center(
                    child: Image.asset(
                      'assets/logooom.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(),

                  // Login form
                  Column(
                    children: [
                      // Department label
                      const Text(
                        "Department of Computer Engineering",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ikuGrey,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // App title
                      const Text(
                        "Capstone Project Evaluation",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: ikuRed,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Username field
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Username',
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.person_outline, color: ikuRed),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Password field
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.lock_outline, color: ikuRed),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Login button — auth logic to be wired to backend
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ikuRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "LOG IN",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
