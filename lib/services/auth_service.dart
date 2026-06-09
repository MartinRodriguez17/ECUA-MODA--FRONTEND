// Archivo: lib/services/auth_service.dart
// Este servicio se encarga de manejar la lógica de conexión con el backend para el login
// Archivo: lib/services/auth_service.dart
// Archivo: lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; 
import 'dart:typed_data'; // <-- PARA MANEJAR LOS BYTES DE LA IMAGEN EN EL PERFIL
class AuthService {
  final String _urlLogin = 'http://localhost:4000/api/auth/login';
  final String _urlRegistro = 'http://localhost:4000/api/auth/registrar';
  final String _urlOtp = 'http://localhost:4000/api/auth/enviar-otp'; // <-- NUEVA RUTA

  Future<String> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_urlLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String token = data['token'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        String rol = decodedToken['usuario']['rol']; 

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_rol', rol);

        return token;
      } else {
        throw data['msg'] ?? 'Error desconocido al iniciar sesión';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión con el servidor';
    }
  }

  // --- NUEVA FUNCIÓN: PEDIR EL CÓDIGO AL CORREO ---
  Future<void> enviarCodigoOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse(_urlOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return; 
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['msg'] ?? 'Error al pedir código';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }

  // --- FUNCIÓN REGISTRAR ACTUALIZADA (AHORA EXIGE CÓDIGO) ---
  Future<String> registrar(String nombre, String email, String password, String codigoOtp) async {
    try {
      final response = await http.post(
        Uri.parse(_urlRegistro),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'codigoOtp': codigoOtp, // <-- MANDAMOS EL CÓDIGO
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        String token = data['token'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        String rol = decodedToken['usuario']['rol'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_rol', rol);

        return token;
      } else {
        throw data['msg'] ?? 'Error desconocido al registrar';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión con el servidor';
    }
  }

  Future<String?> obtenerRolGuardado() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_rol');
  }
  

  // --- NUEVA FUNCIÓN: OBTENER LOS DATOS REALES DEL PERFIL ---
  Future<Map<String, dynamic>> obtenerDatosPerfil() async {
    final String urlPerfil = 'http://localhost:4000/api/auth/perfil';
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) throw 'No tienes sesión activa bro';

      final response = await http.get(
        Uri.parse(urlPerfil),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token, // ¡Mandamos el Pase VIP al guardia de Node!
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // Retornamos el JSON con {nombre, email, rol, etc}
      } else {
        throw data['msg'] ?? 'Error al obtener tu perfil';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión con el servidor 😅';
    }
  }

  // --- NUEVA FUNCIÓN: ACTUALIZAR PERFIL (FOTO Y NOMBRE) ---
  Future<void> actualizarPerfil({String? nombre, Uint8List? fotoBytes, String? nombreArchivo}) async {
    final String urlActualizar = 'http://localhost:4000/api/auth/perfil';
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) throw 'No tienes sesión activa bro';

      var request = http.MultipartRequest('PUT', Uri.parse(urlActualizar));
      
      // Le mandamos tu Pase VIP al guardia
      request.headers['x-auth-token'] = token;

      // Si escribiste un nombre nuevo, lo metemos al formulario
      if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombre'] = nombre;
      }

      // Si elegiste una foto nueva, la adjuntamos
      if (fotoBytes != null && nombreArchivo != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'fotoPerfil', // <-- ¡TIENE QUE LLAMARSE ASÍ PARA QUE MULTER LO ATRAPE!
          fotoBytes,
          filename: nombreArchivo,
        );
        request.files.add(multipartFile);
      }

      // Disparamos el misil a Node.js
      var response = await request.send();
      
      if (response.statusCode == 200) {
        return; // ¡Éxito bro!
      } else {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        throw data['msg'] ?? 'Error al actualizar perfil';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }

  // RECUPERACION DE CONTRASEÑA
  Future<void> solicitarCodigoRecuperacion(String email) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:4000/api/auth/recuperar-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw data['msg'] ?? 'Error al enviar el código';
    }
  } catch (e) {
    if (e is String) throw e;
    throw 'Error de conexión con el servidor';
  }
}

Future<void> restablecerPassword(String email, String codigo, String nuevaPassword) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:4000/api/auth/restablecer-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'codigoOtp': codigo,
        'nuevaPassword': nuevaPassword,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw data['msg'] ?? 'Error al restablecer la contraseña';
    }
  } catch (e) {
    if (e is String) throw e;
    throw 'Error de conexión con el servidor';
  }
}
}