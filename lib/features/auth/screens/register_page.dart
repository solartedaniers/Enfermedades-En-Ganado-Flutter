import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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

  String? userType; // ganadero o veterinario

  final authService = AuthService();
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  bool isStrongPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

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
        const SnackBar(content: Text("Cuenta creada correctamente")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
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
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese una contraseña";
                  }
                  if (!isStrongPassword(value)) {
                    return "Debe tener 8 caracteres, 1 mayúscula, 1 número y 1 símbolo";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmPassword,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Confirmar contraseña"),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}