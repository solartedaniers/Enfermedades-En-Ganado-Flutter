import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final email = TextEditingController();
  final authService = AuthService();

  Future<void> reset() async {

    if (email.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese su correo")),
      );
      return;
    }

    try {

      await authService.resetPassword(email.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Se envió un enlace a tu correo para recuperar tu contraseña."
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      String message = e.toString().replaceAll("Exception: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: "Correo",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: reset,
              child: const Text("Enviar correo de recuperación"),
            ),

          ],
        ),
      ),
    );
  }
}