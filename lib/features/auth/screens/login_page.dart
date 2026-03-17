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
  final Color backgroundColor = const Color(0xFFF8F9FA);

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
        throw Exception("Debes confirmar tu correo antes de iniciar sesión.");
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      String message = e.toString().replaceAll("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
                // --- CORRECCIÓN DE LA ADVERTENCIA AQUÍ ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Cambiamos withOpacity(0.1) por withValues(alpha: 0.1)
                    color: primaryGreen.withValues(alpha: 0.1), 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology_outlined, size: 80, color: primaryGreen),
                ),
                const SizedBox(height: 20),
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
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),
                
                Card(
                  elevation: 5,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
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
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                            child: Text("¿Olvidaste tu contraseña?", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: loading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("INICIAR SESIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}