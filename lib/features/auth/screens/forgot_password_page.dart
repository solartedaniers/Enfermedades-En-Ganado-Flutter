import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final authService = AuthService();
  bool loading = false;

  // --- PALETA DE COLORES AGRO-TECH ---
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final Color darkGreen = const Color(0xFF1B4332);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  // Estilo de Input Reutilizable
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

  Future<void> reset() async {
    if (emailController.text.isEmpty) {
      _showSnackBar("Por favor, ingrese su correo electrónico");
      return;
    }

    setState(() => loading = true);

    try {
      await authService.resetPassword(emailController.text.trim());
      if (!mounted) return;

      _showSnackBar("Se envió un enlace a tu correo para recuperar tu contraseña.");
      
      // Opcional: Volver al login después de enviar
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
      
    } catch (e) {
      if (!mounted) return;
      String message = e.toString().replaceAll("Exception: ", "");
      _showSnackBar(message);
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
      appBar: AppBar(
        title: const Text("Recuperar Acceso", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono decorativo con el nuevo estándar de opacidad
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_email_read_outlined, size: 70, color: primaryGreen),
                ),
                const SizedBox(height: 32),
                
                Text(
                  "¿Olvidaste tu contraseña?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "No te preocupes. Ingresa tu correo y te enviaremos instrucciones para restablecerla.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 40),

                Card(
                  elevation: 4,
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
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: loading ? null : reset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 24, 
                                    width: 24, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : const Text("ENVIAR INSTRUCCIONES", 
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Volver al inicio de sesión",
                    style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}