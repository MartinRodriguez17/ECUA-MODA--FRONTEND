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

  // --- SELECTOR DE TIPO ---
  bool _esVendedor = false;

  // Campos cliente
  final emailController = TextEditingController();

  // Campos vendedor
  final correoVendedorController = TextEditingController();
  final rucController = TextEditingController();

  // Campos comunes
  final codigoController = TextEditingController();
  final nuevaPasswordController = TextEditingController();

  bool _codigoEnviado = false;
  bool _cargando = false;
  bool _verPassword = false;
  String? _errorEmail;
  String? _errorRuc;
  String? _errorCodigo;
  String? _errorPassword;

  Future<void> _solicitarCodigo() async {
    setState(() { _errorEmail = null; _errorRuc = null; });

    if (_esVendedor) {
      final correo = correoVendedorController.text.trim();
      final ruc = rucController.text.trim();

      if (correo.isEmpty) { setState(() => _errorEmail = 'Ingresa tu correo'); return; }
      if (ruc.isEmpty) { setState(() => _errorRuc = 'Ingresa tu RUC'); return; }
      if (ruc.length != 13) { setState(() => _errorRuc = 'El RUC debe tener 13 dígitos'); return; }

      setState(() => _cargando = true);
      try {
        await _authService.solicitarCodigoRecuperacionMarca(correo, ruc);
        setState(() => _codigoEnviado = true);
      } catch (e) {
        setState(() => _errorEmail = e.toString().replaceAll('Exception: ', ''));
      } finally {
        setState(() => _cargando = false);
      }
    } else {
      final email = emailController.text.trim();
      if (email.isEmpty) { setState(() => _errorEmail = 'Ingresa tu correo'); return; }

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
  }

  Future<void> _restablecerPassword() async {
    final codigo = codigoController.text.trim();
    final nuevaPassword = nuevaPasswordController.text;

    setState(() { _errorCodigo = null; _errorPassword = null; });

    if (codigo.length != 6) { setState(() => _errorCodigo = 'El código tiene 6 dígitos'); return; }
    if (nuevaPassword.length < 8) { setState(() => _errorPassword = 'Mínimo 8 caracteres'); return; }

    setState(() => _cargando = true);
    try {
      if (_esVendedor) {
        await _authService.restablecerPasswordMarca(
          correoVendedorController.text.trim(), codigo, nuevaPassword);
      } else {
        await _authService.restablecerPassword(
          emailController.text.trim(), codigo, nuevaPassword);
      }

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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                      ? 'Ingresa el código que enviamos a tu correo'
                      : 'Te enviaremos un código de 6 dígitos a tu correo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // --- SELECTOR CLIENTE / VENDEDOR ---
                if (!_codigoEnviado)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _esVendedor = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_esVendedor ? Colors.black : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'SOY CLIENTE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: !_esVendedor ? Colors.white : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _esVendedor = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _esVendedor ? Colors.black : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'SOY VENDEDOR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _esVendedor ? Colors.white : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // --- CAMPOS SEGÚN TIPO ---
                if (!_codigoEnviado) ...[
                  if (!_esVendedor)
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        errorText: _errorEmail,
                      ),
                    ),

                  if (_esVendedor) ...[
                    TextField(
                      controller: correoVendedorController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo de tu marca',
                        errorText: _errorEmail,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: rucController,
                      keyboardType: TextInputType.number,
                      maxLength: 13,
                      decoration: InputDecoration(
                        labelText: 'RUC de tu empresa (13 dígitos)',
                        errorText: _errorRuc,
                        counterText: '',
                      ),
                    ),
                  ],
                ],

                if (_codigoEnviado) ...[
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54 : Colors.black54,
                        ),
                        onPressed: () => setState(() => _verPassword = !_verPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cargando ? null : () => setState(() {
                      _codigoEnviado = false;
                      codigoController.clear();
                    }),
                    child: Text(
                      '¿No recibiste el código? Reenviar',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _cargando ? null : _codigoEnviado
                      ? _restablecerPassword
                      : _solicitarCodigo,
                  child: _cargando
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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