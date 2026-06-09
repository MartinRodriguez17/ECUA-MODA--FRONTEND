// Archivo: lib/services/brand_service.dart
// Este servicio es el encargado de manejar todo lo relacionado con las marcas, 
//como enviar la solicitud de registro al backend. 
//Aquí es donde se hace la magia de conectar nuestra app con el servidor 
//para que las marcas puedan registrarse y empezar a usar la plataforma.
import 'package:http/http.dart' as http;
import 'dart:convert';

class BrandService {
  final String _url = 'http://localhost:4000/api/marcas/registro';

  Future<void> solicitarRegistro(String nombre, String ruc, String identificacion, String instagram, String correo, String password, String codigoOtp) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'x-app-source': 'hub_moda_app_2026' // ¡El candado anti-bots!
        },
        // ¡Aquí va toda la info que el backend necesita para registrar la marca! Ojo que el backend espera estos campos exactos, así que no los cambies sin revisar el backend primero.
        body: jsonEncode({
          'nombreMarca': nombre,
          'ruc': ruc,
          'identificacion': identificacion,
          'instagram': instagram,
          'correo': correo,
          'password': password,
          'codigoOtp': codigoOtp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; // Todo salió perfecto
      } else {
        // Si el backend nos frena (ej: el correo ya existe), leemos el error
        final errorData = jsonDecode(response.body);
        throw errorData['msg'] ?? 'Error al enviar solicitud: ${response.statusCode}';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión con el servidor bro 😅';
    }
  }

  // --- NUEVA FUNCIÓN: Pedir el código al correo ---
  Future<void> enviarCodigoOtp(String correo) async {
    final String urlOtp = 'http://localhost:4000/api/marcas/enviar-otp';
    try {
      final response = await http.post(
        Uri.parse(urlOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );

      if (response.statusCode == 200) {
        return; // Código enviado exitosamente
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['msg'] ?? 'Error al pedir código';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }
}