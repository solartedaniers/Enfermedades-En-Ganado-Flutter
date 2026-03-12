import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart'; // 👈 Importamos LoginPage

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  bool hasUpper = false;
  bool hasNumber = false;
  bool hasSymbol = false;
  bool hasMinLength = false;
  bool hasMaxLength = true;

  void checkPassword(String value) {
    setState(() {
      hasUpper = value.contains(RegExp(r'[A-Z]'));
      hasNumber = value.contains(RegExp(r'[0-9]'));
      hasSymbol = value.contains(RegExp(r'[!@#\$&*~]'));
      hasMinLength = value.length >= 8;
      hasMaxLength = value.length <= 20;
    });
  }

  bool isStrongPassword() {
    return hasUpper && hasNumber && hasSymbol && hasMinLength && hasMaxLength;
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    if (!isStrongPassword()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La contraseña no cumple los requisitos de seguridad"),
        ),
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    if (userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione tipo de usuario")),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cuenta creada correctamente. Revisa tu correo."),
        ),
      );

      // 👇 Después de registrarse, enviamos al LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      String message = e.toString();

      if (message.contains("over_email_send_rate_limit")) {
        message =
            "Debes esperar unos segundos antes de solicitar otro correo de verificación.";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Widget passwordRule(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: valid ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: valid ? Colors.green : Colors.grey,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: firstName,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su nombre" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: lastName,
                decoration: const InputDecoration(labelText: "Apellido"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su apellido" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: username,
                decoration:
                    const InputDecoration(labelText: "Nombre de usuario"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese un usuario" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: "Correo"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese un correo" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phone,
                decoration: const InputDecoration(labelText: "Teléfono"),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: location,
                decoration: const InputDecoration(labelText: "Ubicación"),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: userType,
                items: const [
                  DropdownMenuItem(
                      value: "ganadero", child: Text("Ganadero")),
                  DropdownMenuItem(
                      value: "veterinario", child: Text("Veterinario")),
                ],
                onChanged: (value) => setState(() => userType = value),
                decoration:
                    const InputDecoration(labelText: "Tipo de usuario"),
                validator: (value) =>
                    value == null ? "Seleccione tipo de usuario" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: password,
                obscureText: !showPassword,
                maxLength: 20,
                onChanged: checkPassword,
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
              passwordRule("Mínimo 8 caracteres", hasMinLength),
              passwordRule("Máximo 20 caracteres", hasMaxLength),
              passwordRule("Una mayúscula", hasUpper),
              passwordRule("Un número", hasNumber),
              passwordRule("Un símbolo (!@#\$&*~)", hasSymbol),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmPassword,
                obscureText: !showConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirmar contraseña",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        showConfirmPassword = !showConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Crear cuenta"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}