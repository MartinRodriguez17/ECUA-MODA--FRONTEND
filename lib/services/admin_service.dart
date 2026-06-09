// Archivo: lib/services/admin_service.dart
// Este servicio es el puente entre tu app y el backend para todo lo relacionado con la administración de pedidos.
// Aquí es donde el Jefe de Ventas puede ver todos los pedidos, aprobarlos o rechazarlos.
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  final String _baseUrl = 'http://localhost:4000/api/pedidos/admin';

  // --- OBTENER TODOS LOS PEDIDOS DE HUB MODA ---
  Future<List<dynamic>> obtenerTodosPedidosAdmin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) throw 'No tienes sesión de Jefe bro';

      final response = await http.get(
        Uri.parse('$_baseUrl/todos'),
        headers: {
          'Content-Type': 'application/json', 
          'x-auth-token': token
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; 
      } else {
        throw data['msg'] ?? 'Error al cargar el panel maestro';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión con la base de datos 😅';
    }
  }

  // --- APROBAR O RECHAZAR UN PEDIDO ---
  Future<void> actualizarEstadoPedido(String pedidoId, String nuevoEstado) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) throw 'No tienes sesión de Jefe bro';

      final response = await http.put(
        Uri.parse('$_baseUrl/$pedidoId/estado'),
        headers: {
          'Content-Type': 'application/json', 
          'x-auth-token': token
        },
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        return; 
      } else {
        final data = jsonDecode(response.body);
        throw data['msg'] ?? 'Error al cambiar estado';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }
}