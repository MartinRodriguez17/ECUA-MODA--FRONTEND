// Archivo: lib/services/product_service.dart
// Este servicio se encarga de manejar la lógica de conexión con el backend para obtener los productos
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductService {
  // La ruta de tu Node.js para los productos
  final String _url = 'http://localhost:4000/api/productos';

  Future<List<dynamic>> obtenerRopa() async {
    try {
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode == 200) {
        // Si todo sale bien, devolvemos la lista decodificada
        return jsonDecode(response.body);
      } else {
        // Si el backend responde con error (ej: 500)
        throw 'Error del servidor: ${response.statusCode}';
      }
    } catch (e) {
      // Si el backend está apagado o falla el internet
      throw 'Error de conexión. ¿Prendiste el backend con nodemon, bro? 😅';
    }
  }
}