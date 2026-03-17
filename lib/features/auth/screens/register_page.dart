import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores de texto
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();

  String? userType;
  final authService = AuthService();
  final formKey = GlobalKey<FormState>();

  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  // Reglas de Validación de Contraseña
  bool hasUpper = false;
  bool hasNumber = false;
  bool hasSymbol = false;
  bool hasMinLength = false;
  bool hasMaxLength = true;

  // --- PALETA DE COLORES AGRO-TECH ---
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final Color darkGreen = const Color(0xFF1B4332);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  void checkPassword(String value) {
    setState(() {
      hasUpper = value.contains(RegExp(r'[A-Z]'));
      hasNumber = value.contains(RegExp(r'[0-9]'));
      hasSymbol = value.contains(RegExp(r'[!@#\$&*~]'));
      hasMinLength = value.length >= 8;
      hasMaxLength = value.length <= 20;
    });
  }

  bool isStrongPassword() => hasUpper && hasNumber && hasSymbol && hasMinLength && hasMaxLength;

  // Estilo de Input Profesional Reutilizable
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

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    if (!isStrongPassword()) {
      _showSnackBar("La contraseña no cumple los requisitos de seguridad");
      return;
    }
    if (password.text != confirmPassword.text) {
      _showSnackBar("Las contraseñas no coinciden");
      return;
    }
    if (userType == null) {
      _showSnackBar("Seleccione tipo de usuario");
      return;
    }

    setState(() => loading = true);
    try {
      await authService.signUpUser(
        email: email.text.trim(),
        password: password.text.trim(),
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        username: username.text.trim(),
        phone: phone.text.trim(),
        location: location.text.trim(),
        userType: userType!,
      );
      if (!mounted) return;
      _showSnackBar("Cuenta creada correctamente. Revisa tu correo.");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().contains("over_email_send_rate_limit") 
          ? "Espera unos segundos para solicitar otro correo." 
          : e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget passwordRule(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel_outlined,
            color: valid ? Colors.green : Colors.grey.withValues(alpha: 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: valid ? Colors.green : Colors.grey,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Crear Cuenta", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Text("Únete a AgroVet AI", 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
              const SizedBox(height: 8),
              const Text("Gestiona la salud de tu ganado con IA", 
                style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),
              
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: firstName,
                        decoration: _inputStyle("Nombre", Icons.person_outline),
                        validator: (value) => value!.isEmpty ? "Ingrese su nombre" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: lastName,
                        decoration: _inputStyle("Apellido", Icons.person_outline),
                        validator: (value) => value!.isEmpty ? "Ingrese su apellido" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: username,
                        decoration: _inputStyle("Usuario", Icons.alternate_email),
                        validator: (value) => value!.isEmpty ? "Ingrese un usuario" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputStyle("Correo", Icons.email_outlined),
                        validator: (value) => value!.isEmpty ? "Ingrese un correo" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: _inputStyle("Teléfono", Icons.phone_android_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: location,
                        decoration: _inputStyle("Ubicación", Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 16),
                      
                      // Dropdown corregido
                      DropdownButtonFormField<String>(
                        initialValue: userType,
                        items: const [
                          DropdownMenuItem(value: "ganadero", child: Text("Ganadero")),
                          DropdownMenuItem(value: "veterinario", child: Text("Veterinario")),
                        ],
                        onChanged: (value) => setState(() => userType = value),
                        decoration: _inputStyle("Tipo de usuario", Icons.badge_outlined),
                        validator: (value) => value == null ? "Seleccione tipo" : null,
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de Contraseña
                      TextFormField(
                        controller: password,
                        obscureText: !showPassword,
                        onChanged: checkPassword,
                        decoration: _inputStyle("Contraseña", Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => showPassword = !showPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Panel de reglas de contraseña
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            passwordRule("Mínimo 8 caracteres", hasMinLength),
                            passwordRule("Una mayúscula y un número", hasUpper && hasNumber),
                            passwordRule("Un símbolo (!@#\$&*~)", hasSymbol),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPassword,
                        obscureText: !showConfirmPassword,
                        decoration: _inputStyle("Confirmar contraseña", Icons.lock_reset_outlined).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: loading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: loading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("REGISTRARSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Ya tienes cuenta?"),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Inicia sesión", style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}