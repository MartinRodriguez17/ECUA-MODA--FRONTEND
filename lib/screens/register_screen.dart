// Archivo: lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../main_wrapper.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Variables de control de interfaz
  bool _estaCargando = false;
  bool _ocultarPassword = true;
  bool _ocultarConfirmPassword = true;

  // Variables para pintar los errores en rojo abajo de cada campo
  String? _errorNombre;
  String? _errorEmail;
  String? _errorPassword;
  String? _errorConfirmPassword;

  final AuthService _authService = AuthService(); 

  // --- VENTANA EMERGENTE PARA EL CÓDIGO ---
  Future<void> _mostrarVentanaOtp(String nombre, String email, String password) async {
    final TextEditingController _otpController = TextEditingController();
    bool isCargandoOtp = false;
    String? errorOtp; 

    await showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setStateDialog) { 
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Verifica tu correo 📩', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ingresa el código de 6 dígitos que enviamos a:\n$email', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration( 
                      hintText: '000000',
                      border: const OutlineInputBorder(),
                      counterText: '',
                      errorText: errorOtp, 
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: isCargandoOtp ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: isCargandoOtp ? null : () async {
                    if (_otpController.text.length != 6) {
                      setStateDialog(() => errorOtp = 'Ingresa los 6 dígitos bro 🛑');
                      return;
                    }

                    setStateDialog(() {
                      isCargandoOtp = true;
                      errorOtp = null; 
                    });

                    try {
                      await _authService.registrar(
                        nombre, email, password, _otpController.text
                      );

                      if (!mounted) return;
                      Navigator.pop(context); 
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Cuenta creada con éxito! 🔥'), backgroundColor: Colors.green),
                      );
                      
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MainWrapper()),
                        (Route<dynamic> route) => false,
                      );

                    } catch (error) {
                      setStateDialog(() => errorOtp = error.toString());
                    } finally {
                      setStateDialog(() => isCargandoOtp = false);
                    }
                  },
                  child: isCargandoOtp 
                      ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verificar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // --- LOGICA DE VALIDACIÓN CON ERRORES INLINE ---
  Future<void> _intentarRegistro() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Reiniciamos estados de error antes de validar
    setState(() {
      _errorNombre = null;
      _errorEmail = null;
      _errorPassword = null;
      _errorConfirmPassword = null;
    });

    bool tieneErrores = false;

    // 1. Validar Nombre / Tag de Usuario
    if (nombre.isEmpty) {
      setState(() => _errorNombre = 'Ponte un nombre único bro, cómo te van a ver todos');
      tieneErrores = true;
    } else if (nombre.length < 4) {
      setState(() => _errorNombre = 'Ese nombre es muy corto, mínimo 4 letras');
      tieneErrores = true;
    }

    // 2. Validar Correo
    final bool emailValido = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
    if (email.isEmpty) {
      setState(() => _errorEmail = 'El correo es obligatorio');
      tieneErrores = true;
    } else if (!emailValido) {
      setState(() => _errorEmail = 'Escribe un correo real (ej: tu@email.com)');
      tieneErrores = true;
    }

    // 3. Validar Contraseña
    final passwordRegex = RegExp(r"^(?=.*[A-Z])(?=.*\d).{8,}$");
    if (password.isEmpty) {
      setState(() => _errorPassword = 'La contraseña no puede estar vacía');
      tieneErrores = true;
    } else if (!passwordRegex.hasMatch(password)) {
      setState(() => _errorPassword = 'Debe tener mínimo 8 caracteres, una Mayúscula y un Número 🛑');
      tieneErrores = true;
    }

    // 4. Validar Confirmación de Contraseña
    if (confirmPassword.isEmpty) {
      setState(() => _errorConfirmPassword = 'Confirma tu contraseña bro');
      tieneErrores = true;
    } else if (password != confirmPassword) {
      setState(() => _errorConfirmPassword = 'Las contraseñas no coinciden, míralas bien');
      tieneErrores = true;
    }

    // Si encontramos algún fallo, detenemos el disparo hacia Node.js
    if (tieneErrores) return;

    setState(() => _estaCargando = true);

    try {
      // Intentamos disparar el OTP al servidor
      await _authService.enviarCodigoOtp(email);
      if (!mounted) return;
      
      _mostrarVentanaOtp(nombre, email, password);
    } catch (error) {
      if (!mounted) return;
      
      // Si el backend detecta que el nombre o correo ya existen, pintamos el error donde corresponde
      final String msg = error.toString().toLowerCase();
      setState(() {
        if (msg.contains('nombre') || msg.contains('usuario') || msg.contains('reclamado')) {
          _errorNombre = error.toString();
        } else if (msg.contains('correo') || msg.contains('email') || msg.contains('cuenta activa')) {
          _errorEmail = error.toString();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
          );
        }
      });
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('CREAR CUENTA', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                const SizedBox(height: 10),
                const Text('Únete para comprar tus hoodies favoritos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 40),

                // Caja 1: Nombre de Usuario (Ej: alexis777)
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de Usuario (Username)',
                    hintText: 'Ej: alexis777',
                    border: const OutlineInputBorder(),
                    errorText: _errorNombre, // Asignación dinámica de error inline
                  ),
                ),
                const SizedBox(height: 20),

                // Caja 2: Correo Electrónico
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: const OutlineInputBorder(),
                    errorText: _errorEmail,
                  ),
                ),
                const SizedBox(height: 20),

                // Caja 3: Contraseña con Ojo Interactivo
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    errorText: _errorPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Caja 4: Confirmación de Contraseña con Ojo Interactivo
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _ocultarConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    border: const OutlineInputBorder(),
                    errorText: _errorConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _ocultarConfirmPassword = !_ocultarConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    onPressed: _estaCargando ? null : _intentarRegistro,
                    child: _estaCargando 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('REGISTRARME', style: TextStyle(fontWeight: FontWeight.bold)),
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