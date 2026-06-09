// Archivo: lib/screens/brand_register_screen.dart
// Esta pantalla es para que las marcas puedan solicitar su registro en el Hub de Moda.
// Aquí las marcas llenan un formulario con su información, y al enviar se conecta con el BrandService para mandar la solicitud al backend.
// Además, implementamos validaciones para asegurarnos de que los datos ingresados sean correctos
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/brand_service.dart';

class BrandRegisterScreen extends StatefulWidget {
  const BrandRegisterScreen({super.key});

  @override
  State<BrandRegisterScreen> createState() => _BrandRegisterScreenState();
}

class _BrandRegisterScreenState extends State<BrandRegisterScreen> {
  final TextEditingController _nombreMarcaController = TextEditingController();
  final TextEditingController _rucController = TextEditingController(); 
  final TextEditingController _identificacionController = TextEditingController(); 
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // <-- NUEVA CAJA
  
  final BrandService _brandService = BrandService(); 
  bool _estaCargando = false;

  // --- NUEVAS VARIABLES PARA LOS OJITOS 👀 ---
  bool _ocultarPassword = true;
  bool _ocultarConfirmPassword = true;

  String? errorNombre;
  String? errorRuc; 
  String? errorIdentificacion;
  String? errorInstagram;
  String? errorCorreo;
  String? errorPassword;
  String? errorConfirmPassword; // <-- NUEVO ERROR

  // --- Validador de RUC Ecuatoriano ---
  bool _validarRucEcuador(String ruc) {
    if (ruc.length != 13) return false;
    final int provincia = int.tryParse(ruc.substring(0, 2)) ?? 0;
    if ((provincia < 1 || provincia > 24) && provincia != 30) return false;
    if (ruc.substring(10, 13) == '000') return false;

    final int tercerDigito = int.tryParse(ruc.substring(2, 3)) ?? 0;

    if (tercerDigito == 9) { 
      final coeficientes = [4, 3, 2, 7, 6, 5, 4, 3, 2];
      final int verificador = int.tryParse(ruc.substring(9, 10)) ?? 0;
      int suma = 0;
      for (int i = 0; i < 9; i++) {
        suma += (int.tryParse(ruc.substring(i, i + 1)) ?? 0) * coeficientes[i];
      }
      final int residuo = suma % 11;
      final int resultado = residuo == 0 ? 0 : 11 - residuo;
      return resultado == verificador;
    }

    if (tercerDigito == 6) { 
      final coeficientes = [3, 2, 7, 6, 5, 4, 3, 2];
      final int verificador = int.tryParse(ruc.substring(8, 9)) ?? 0;
      int suma = 0;
      for (int i = 0; i < 8; i++) {
        suma += (int.tryParse(ruc.substring(i, i + 1)) ?? 0) * coeficientes[i];
      }
      final int residuo = suma % 11;
      final int resultado = residuo == 0 ? 0 : 11 - residuo;
      return resultado == verificador;
    }

    if (tercerDigito < 6) { 
      final int verificador = int.tryParse(ruc.substring(9, 10)) ?? 0;
      int suma = 0;
      for (int i = 0; i < 9; i++) {
        int valor = int.tryParse(ruc.substring(i, i + 1)) ?? 0;
        if (i % 2 == 0) {
          valor = valor * 2;
          if (valor > 9) valor -= 9;
        }
        suma += valor;
      }
      int primerDigitoSuma = int.parse(suma.toString().substring(0, 1));
      int decenaSuperior = (primerDigitoSuma + 1) * 10;
      if (suma % 10 == 0) decenaSuperior = suma; 
      int resultado = decenaSuperior - suma;
      if (resultado == 10) resultado = 0;
      return resultado == verificador;
    }
    return false;
  }

  // --- Validador de Cédula Ecuatoriana ---
  bool _validarCedulaEcuatoriana(String cedula) {
    if (cedula.length != 10) return false;
    
    final int provincia = int.tryParse(cedula.substring(0, 2)) ?? 0;
    if (provincia < 1 || provincia > 24) return false;

    final int tercerDigito = int.tryParse(cedula.substring(2, 3)) ?? 0;
    if (tercerDigito >= 6) return false;

    final coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;

    for (int i = 0; i < 9; i++) {
      int valor = (int.tryParse(cedula.substring(i, i + 1)) ?? 0) * coeficientes[i];
      if (valor > 9) valor -= 9;
      suma += valor;
    }

    int digitoEsperado = 10 - (suma % 10);
    if (digitoEsperado == 10) digitoEsperado = 0;

    final int verificador = int.tryParse(cedula.substring(9, 10)) ?? 0;
    return digitoEsperado == verificador;
  }
// --- FUNCIÓN PARA MOSTRAR LA VENTANITA DEL CÓDIGO ---
 
  Future<void> _mostrarVentanaOtp(String nombre, String ruc, String identificacion, String instagram, String correo, String password) async {
    final TextEditingController _otpController = TextEditingController();
    bool isCargandoOtp = false;
    String? errorOtp; // <-- NUEVA VARIABLE: Solo vive dentro de este Pop-up

    await showDialog(
      context: context,
      barrierDismissible: false, // No deja cerrar picando afuera
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setStateDialog) { // setStateDialog actualiza solo la ventanita
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Verifica tu correo 📩', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ingresa el código de 6 dígitos que enviamos a:\n$correo', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration( // Le quitamos el 'const' porque ahora es dinámico
                      hintText: '000000',
                      border: const OutlineInputBorder(),
                      counterText: '',
                      errorText: errorOtp, // <-- MAGIA: El error sale debajo de esta caja
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
                    // 1. Validación si la caja está vacía o incompleta
                    if (_otpController.text.length != 6) {
                      setStateDialog(() {
                        errorOtp = 'Ingresa los 6 dígitos exactos bro 🛑';
                      });
                      return;
                    }

                    // 2. Apagamos errores previos y prendemos el cargando
                    setStateDialog(() {
                      isCargandoOtp = true;
                      errorOtp = null; 
                    });

                    try {
                      // LLAMADA FINAL: Mandamos todo + el código al backend
                      await _brandService.solicitarRegistro(
                        nombre, ruc, identificacion, instagram, correo, password, _otpController.text
                      );

                      if (!mounted) return;
                      Navigator.pop(context); // Cerramos el Pop-up
                      
                      // Si todo sale bien, este es el único SnackBar que sale (el verde)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Te avisaremos si cumples con los requisitos 🏢✨'), backgroundColor: Colors.green),
                      );
                      
                      if (Navigator.canPop(context)) Navigator.pop(context); // Volvemos a la pantalla anterior

                    } catch (error) {
                      // 3. ¡EL ATAJE DEL ERROR! Si Node.js rechaza el código, lo pintamos en la caja
                      setStateDialog(() {
                        errorOtp = error.toString();
                      });
                    } finally {
                      setStateDialog(() => isCargandoOtp = false);
                    }
                  },
                  child: isCargandoOtp 
                      ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verificar y Enviar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _enviarSolicitud() async {
    final nombre = _nombreMarcaController.text.trim();
    final ruc = _rucController.text.trim();
    final identificacion = _identificacionController.text.trim();
    final instagram = _instagramController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hayErrores = false;

    setState(() {
      errorNombre = null;
      errorRuc = null;
      errorIdentificacion = null;
      errorInstagram = null;
      errorCorreo = null;
      errorPassword = null;
      errorConfirmPassword = null; // <-- LIMPIAMOS ERROR

      if (nombre.isEmpty) {
        errorNombre = 'Bro, dinos cómo se llama tu marca';
        hayErrores = true;
      }

      if (ruc.isEmpty) {
        errorRuc = 'El RUC de la empresa es obligatorio';
        hayErrores = true;
      } else if (ruc.length != 13) {
        errorRuc = 'El RUC debe tener exactamente 13 dígitos bro';
        hayErrores = true;
      } else if (!_validarRucEcuador(ruc)) {
        errorRuc = 'El RUC ingresado no es válido en Ecuador 🛑';
        hayErrores = true;
      }

      if (identificacion.isEmpty) {
        errorIdentificacion = 'Falta la cédula del representante';
        hayErrores = true;
      } else if (identificacion.length != 10) {
        errorIdentificacion = 'La cédula debe tener exactamente 10 dígitos bro';
        hayErrores = true;
      } else if (!_validarCedulaEcuatoriana(identificacion)) {
        errorIdentificacion = 'Esa cédula no es válida matemáticamente 🛑';
        hayErrores = true;
      }

      if (instagram.isEmpty) {
        errorInstagram = 'Déjanos tu usuario para ver tu ropa';
        hayErrores = true;
      } else if (!instagram.startsWith('@')) {
        errorInstagram = 'Debe empezar con @ (Ej: @tu_marca)';
        hayErrores = true;
      }

      final bool emailValido = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(correo);
      if (correo.isEmpty) {
        errorCorreo = 'Ingresa un correo de contacto';
        hayErrores = true;
      } else if (!emailValido) {
        errorCorreo = 'Ese formato de correo no convence bro';
        hayErrores = true;
      }

      if (password.isEmpty) {
        errorPassword = 'Crea una contraseña para tu cuenta';
        hayErrores = true;
      } else if (password.length < 6) {
        errorPassword = 'Pon algo más seguro, mínimo 6 caracteres';
        hayErrores = true;
      } else {
        final tieneMayuscula = RegExp(r'[A-Z]').hasMatch(password);
        final tieneNumero = RegExp(r'[0-9]').hasMatch(password);

        if (!tieneMayuscula || !tieneNumero) {
          errorPassword = 'Debe tener al menos una letra mayúscula y un número bro';
          hayErrores = true;
        }
      }

      // --- NUEVA VALIDACIÓN: COMPARAR CONTRASEÑAS ---
      if (confirmPassword.isEmpty) {
        errorConfirmPassword = 'Confirma tu contraseña bro';
        hayErrores = true;
      } else if (password != confirmPassword) {
        errorConfirmPassword = 'Las contraseñas no coinciden 🛑';
        hayErrores = true;
      }
    });

    if (hayErrores) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      // 1. PRIMERO PEDIMOS EL CÓDIGO AL BACKEND
      await _brandService.enviarCodigoOtp(correo);
      
      if (!mounted) return;
      
      // 2. SI LLEGÓ BIEN, ABRIMOS LA VENTANITA PARA QUE LO ESCRIBA
      _mostrarVentanaOtp(nombre, ruc, identificacion, instagram, correo, password);

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error ❌'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ZONA B2B',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storefront_outlined, size: 60, color: Colors.black),
                const SizedBox(height: 10),
                const Text(
                  'ÚNETE AL HUB',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vende tu ropa en nuestra plataforma. \nLlena tus datos para evaluar tu solicitud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: _nombreMarcaController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Comercial de la Marca',
                    hintText: 'Ej: Streetwear EC',
                    border: const OutlineInputBorder(),
                    errorText: errorNombre,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _rucController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 13,
                  decoration: InputDecoration(
                    labelText: 'RUC de la Empresa',
                    hintText: 'Tus 13 dígitos fiscales',
                    border: const OutlineInputBorder(),
                    errorText: errorRuc,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _identificacionController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Cédula del Representante Legal',
                    hintText: 'Tus 10 dígitos',
                    border: const OutlineInputBorder(),
                    errorText: errorIdentificacion,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    labelText: 'Instagram Oficial',
                    hintText: 'Ej: @tu_marca',
                    border: const OutlineInputBorder(),
                    errorText: errorInstagram,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo de Contacto',
                    hintText: 'contacto@tumarca.com',
                    border: const OutlineInputBorder(),
                    errorText: errorCorreo,
                  ),
                ),
                const SizedBox(height: 16),

                // --- CAJA 1: CONTRASEÑA CON OJITO ---
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword, // Usamos la variable booleana
                  decoration: InputDecoration(
                    labelText: 'Crea una contraseña segura',
                    border: const OutlineInputBorder(),
                    errorText: errorPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _ocultarPassword = !_ocultarPassword; // Invertimos el valor
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- CAJA 2: CONFIRMAR CONTRASEÑA CON OJITO ---
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _ocultarConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirma tu contraseña',
                    border: const OutlineInputBorder(),
                    errorText: errorConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _ocultarConfirmPassword = !_ocultarConfirmPassword; 
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _estaCargando ? null : _enviarSolicitud,
                    child: _estaCargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'ENVIAR SOLICITUD DE MARCA',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
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