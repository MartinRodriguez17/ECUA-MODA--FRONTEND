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
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
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
  Future<void> actualizarEstadoPedido(
    String pedidoId,
    String nuevoEstado,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) throw 'No tienes sesión de Jefe bro';

      final response = await http.put(
        Uri.parse('$_baseUrl/$pedidoId/estado'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
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

  final String _baseUrlAuth = 'http://localhost:4000/api/auth';

  // --- OBTENER TODOS LOS USUARIOS ---
  Future<Map<String, dynamic>> obtenerTodosUsuarios() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      if (token == null) throw 'No tienes sesión bro';

      final response = await http.get(
        Uri.parse('$_baseUrlAuth/admin/usuarios'),
        headers: {'x-auth-token': token},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data;
      throw data['msg'] ?? 'Error al obtener usuarios';
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }

  // --- CAMBIAR ESTADO DE USUARIO ---
  Future<void> cambiarEstadoUsuario(
    String tipo,
    String id,
    String estado,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      if (token == null) throw 'No tienes sesión bro';

      final response = await http.put(
        Uri.parse('$_baseUrlAuth/admin/usuarios/$tipo/$id/estado'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({'estado': estado}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw data['msg'] ?? 'Error al cambiar estado';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }

  final String _baseUrlProductos = 'http://localhost:4000/api/productos';

  Future<List<dynamic>> obtenerTodosProductosAdmin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('http://localhost:4000/api/productos/admin/todos'),
        headers: {'x-auth-token': token ?? ''},
      );
      print('Status productos: ${response.statusCode}');
      print('Body: ${response.body.substring(0, 100)}');

      if (response.statusCode == 200) return jsonDecode(response.body);
      throw 'Error al obtener productos';
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }

  Future<void> ocultarProducto(String id, bool oculto) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final url = '$_baseUrlProductos/admin/$id/ocultar';
      print('URL ocultar: $url');

      final response = await http.put(
        Uri.parse('$_baseUrlProductos/admin/$id/ocultar'), 
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({'oculto': oculto}),
      );

      print('Status ocultar: ${response.statusCode}'); 
      print('Body ocultar: ${response.body}'); 

      if (response.statusCode != 200) throw 'Error al ocultar producto';
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }

  Future<void> eliminarProductoAdmin(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse('$_baseUrlProductos/$id'), // 👈 corregido
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode != 200) throw 'Error al eliminar producto';
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión bro 😅';
    }
  }
}
