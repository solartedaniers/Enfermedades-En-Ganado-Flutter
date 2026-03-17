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

  // --- PALETA DE COLORES ---
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final Color darkGreen = const Color(0xFF1B4332);
  final Color backgroundColor = const Color(0xFFF1F8F5);

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryGreen),
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
    );
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar("Ingrese correo y contraseña");
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
        throw Exception("Debes confirmar tu correo antes de iniciar sesión.");
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de la aplicación (Ruta corregida a lib/images/)
                Image.asset(
                  'lib/images/logo.webp', 
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Si la imagen no carga, muestra un icono estético
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        // CORRECCIÓN AQUÍ: .withValues en lugar de .withOpacity
                        border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
                      ),
                      child: Icon(Icons.pets, size: 60, color: primaryGreen),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  "AgroVet AI",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "Inteligencia Artificial para tu ganado",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 40),
                
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputStyle("Correo electrónico", Icons.email_outlined),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: _inputStyle("Contraseña", Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const ForgotPasswordPage())
                    ),
                    child: Text("¿Olvidaste tu contraseña?", 
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("INICIAR SESIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿No tienes una cuenta?"),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                      child: Text("Regístrate aquí", style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}