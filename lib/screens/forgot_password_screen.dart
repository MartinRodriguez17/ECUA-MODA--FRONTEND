import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  final codigoController = TextEditingController();
  final nuevaPasswordController = TextEditingController();

  bool _codigoEnviado = false;
  bool _cargando = false;
  bool _verPassword = false;
  String? _errorEmail;
  String? _errorCodigo;
  String? _errorPassword;

  Future<void> _solicitarCodigo() async {
    final email = emailController.text.trim();
    setState(() => _errorEmail = null);

    if (email.isEmpty) {
      setState(() => _errorEmail = 'Ingresa tu correo');
      return;
    }

    setState(() => _cargando = true);
    try {
      await _authService.solicitarCodigoRecuperacion(email);
      setState(() => _codigoEnviado = true);
    } catch (e) {
      setState(() => _errorEmail = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _restablecerPassword() async {
    final codigo = codigoController.text.trim();
    final nuevaPassword = nuevaPasswordController.text;

    setState(() { _errorCodigo = null; _errorPassword = null; });

    if (codigo.length != 6) {
      setState(() => _errorCodigo = 'El código tiene 6 dígitos');
      return;
    }
    if (nuevaPassword.length < 8) {
      setState(() => _errorPassword = 'Mínimo 8 caracteres');
      return;
    }

    setState(() => _cargando = true);
    try {
      await _authService.restablecerPassword(
        emailController.text.trim(),
        codigo,
        nuevaPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Contraseña actualizada! Ya puedes iniciar sesión 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorCodigo = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '¿OLVIDASTE TU\nCONTRASEÑA?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _codigoEnviado
                      ? 'Ingresa el código que enviamos a\n${emailController.text.trim()}'
                      : 'Te enviaremos un código de 6 dígitos a tu correo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // CORREO
                TextField(
                  controller: emailController,
                  enabled: !_codigoEnviado,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    errorText: _errorEmail,
                  ),
                ),

                if (_codigoEnviado) ...[
                  const SizedBox(height: 20),

                  // CÓDIGO
                  TextField(
                    controller: codigoController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Código de 6 dígitos',
                      errorText: _errorCodigo,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // NUEVA CONTRASEÑA
                  TextField(
                    controller: nuevaPasswordController,
                    obscureText: !_verPassword,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      helperText: 'Mínimo 8 caracteres, una mayúscula y un número',
                      errorText: _errorPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _verPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.black54,
                        ),
                        onPressed: () => setState(() => _verPassword = !_verPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Reenviar código
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () => setState(() {
                              _codigoEnviado = false;
                              codigoController.clear();
                            }),
                    child: const Text(
                      '¿No recibiste el código? Reenviar',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _cargando
                      ? null
                      : _codigoEnviado
                          ? _restablecerPassword
                          : _solicitarCodigo,
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_codigoEnviado ? 'CAMBIAR CONTRASEÑA' : 'ENVIAR CÓDIGO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}