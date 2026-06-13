import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ResenaService {
  final String _baseUrl = 'http://localhost:4000/api/resenas';

  Future<void> crearResena({
    required String marcaId,
    required String pedidoId,
    required int estrellas,
    String comentario = '',
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token ?? ''},
        body: jsonEncode({
          'marcaId': marcaId,
          'pedidoId': pedidoId,
          'estrellas': estrellas,
          'comentario': comentario,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 201) {
        throw data['msg'] ?? 'Error al enviar calificación';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }

  Future<bool> verificarResena(String pedidoId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$_baseUrl/verificar/$pedidoId'),
        headers: {'x-auth-token': token ?? ''},
      );

      final data = jsonDecode(response.body);
      return data['yaCalifico'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> obtenerResenasMarca(String marcaId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/marca/$marcaId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }
}