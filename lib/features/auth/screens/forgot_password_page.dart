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
    await authService.resetPassword(email.text.trim());

    if (!mounted) return; // seguridad extra

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Correo de recuperación enviado")),
    );
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
              decoration: const InputDecoration(labelText: "Correo"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: reset,
              child: const Text("Enviar"),
            ),
          ],
        ),
      ),
    );
  }
}