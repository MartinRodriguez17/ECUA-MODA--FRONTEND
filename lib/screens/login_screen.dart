// Archivo: lib/screens/login_screen.dart
// Esta pantalla es para que los usuarios puedan iniciar sesión en el Hub de Moda Urbana. Aquí vamos a conectar con el
//AuthService que creamos para enviar las credenciales al backend y manejar la respuesta (token VIP o errores).
//También vamos a tener un botón para navegar a la pantalla de registro de usuarios,
// y otro para que las marcas puedan ir a su propio formulario de registro.

import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // ¡Importamos el nuevo puente!
import 'brand_register_screen.dart'; // Esta es la pantalla de registro de marcas, que por ahora es un placeholder pero ya la tenemos lista para cuando empecemos a hacer el formulario de registro de marcas.
import 'register_screen.dart';
import '../main_wrapper.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Instanciamos el servicio
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorEmail;
  String? errorPassword;
  bool estaCargando = false; // Para que el botón muestre que está pensando
  bool _verPassword = false;

  Future<void> intentarLogin() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    setState(() {
      errorEmail = null;
      errorPassword = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) errorEmail = 'El correo es obligatorio';
        if (password.isEmpty) errorPassword = 'La contraseña es obligatoria';
      });
      return;
    }

    setState(() {
      estaCargando = true;
    });

    try {
      // 1. LLAMAMOS AL SERVICIO
      await _authService.login(email, password);

      if (!mounted) return;

      // 2. MOSTRAMOS ÉXITO
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido a Hub Moda Urbana! 🚀'),
          backgroundColor:
              Colors.green, // Lo puse verde para que combine con el registro
          duration: Duration(seconds: 2),
        ),
      );

      // 3. ¡EL PARCHE FINAL! Lo mandamos directo al inicio y borramos el login del historial
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainWrapper(),
        ), // Asegúrate de importar main_wrapper.dart arriba
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      final String mensajeError = error.toString().toLowerCase();

      setState(() {
        if (mensajeError.contains('usuario') ||
            mensajeError.contains('correo') ||
            mensajeError.contains('email')) {
          errorEmail = error.toString();
        } else if (mensajeError.contains('contraseña') ||
            mensajeError.contains('clave') ||
            mensajeError.contains('password')) {
          errorPassword = error.toString();
        } else {
          errorEmail = error.toString();
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          estaCargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ECUA MODA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 50),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    errorText: errorEmail,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: !_verPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    errorText: errorPassword,
                    suffixIcon: IconButton(
                      // 👈 IconButton, no Icon
                      icon: Icon(
                        _verPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        // 👈 onPressed va aquí dentro
                        setState(() {
                          _verPassword = !_verPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: estaCargando
                      ? null
                      : intentarLogin, // Se desactiva si está cargando
                  child: estaCargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('INICIAR SESIÓN'),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    // ¡Revivimos el botón!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'CREAR CUENTA NUEVA',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- NUEVA SECCIÓN PARA VENDEDORES ---
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black26)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.black26)),
                  ],
                ),
                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BrandRegisterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront, color: Colors.black),
                  label: const Text(
                    '¿Eres una marca? Vende aquí.',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                // -------------------------------------
              ],
            ),
          ),
        ),
      ),
    );
  }
}
