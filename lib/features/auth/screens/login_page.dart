import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../../auth/home/screens/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool loading = false;
  bool showPassword = false;

  Future<void> login() async {

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese correo y contraseña")),
      );
      return;
    }

    setState(() => loading = true);

    try {

      await authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = Supabase.instance.client.auth.currentUser;

      if (user?.emailConfirmedAt == null) {
        throw Exception(
            "Debes confirmar tu correo antes de iniciar sesión. Revisa tu email.");
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );

    } catch (e) {

      if (!mounted) return;

      String message = e.toString().replaceAll("Exception: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "AgroVet AI",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Correo",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Iniciar sesión"),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage()),
                  );
                },
                child: const Text("¿Olvidaste tu contraseña?"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text("Crear cuenta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}