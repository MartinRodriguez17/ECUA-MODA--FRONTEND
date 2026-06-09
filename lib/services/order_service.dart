// Archivo: lib/services/order_service.dart
// Este servicio es el puente entre tu app y el backend para todo lo relacionado con las compras.
// Aquí es donde vamos a mandar la información del carrito al backend para crear un pedido.


import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // <-- MAGIA PURA: Compatible con Web y Celular
import '../services/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
class OrderService {
  final String _url = 'http://localhost:4000/api/pedidos';

  Future<void> crearOrden({
    required List<CartItem> items,
    required double subtotal,
    required double iva,
    required double total,
    required String correo,
    required String direccion,
    required String telefono,
    required Uint8List comprobanteBytes, // <-- Recibimos los Bytes de la imagen
    required String nombreArchivo,       // <-- Recibimos el nombre del archivo
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_url));

      request.headers.addAll({
        'x-app-source': 'hub_moda_app_2026',
      });

      request.fields['correoComprador'] = correo;
      request.fields['direccionEnvio'] = direccion;
      request.fields['telefonoComprador'] = telefono;
      request.fields['subtotal'] = subtotal.toString();
      request.fields['iva'] = iva.toString();
      request.fields['total'] = total.toString();

      List<Map<String, dynamic>> productosMapeados = items.map((item) {
        String productoIdPuro = item.id.split('_')[0];
        return {
          'productoId': productoIdPuro,
          'cantidad': item.cantidad,
          'talla': item.talla,
          'precio': item.precio,
        };
      }).toList();

      request.fields['productos'] = jsonEncode(productosMapeados);

      // --- EL PARCHE MULTIPLATAFORMA ---
      // Subimos el archivo directamente desde la memoria, sin tocar el disco duro
      var multipartFile = http.MultipartFile.fromBytes(
        'comprobante', 
        comprobanteBytes,
        filename: nombreArchivo,
      );
      
      request.files.add(multipartFile);

      var response = await request.send();

      if (response.statusCode == 201) {
        return; 
      } else {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        throw data['msg'] ?? 'Error al procesar la compra en el servidor';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión con el Hub bro 😅';
    }
  }

  
// --- FUNCIÓN 2: OBTENER EL HISTORIAL DE COMPRAS ---
  // ¡Ahora sí está ADENTRO de la clase OrderService!
  Future<List<dynamic>> obtenerHistorialPedidos() async {
    final String urlHistorial = 'http://localhost:4000/api/pedidos/mis-pedidos';
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) throw 'No tienes sesión activa bro';

      final response = await http.get(
        Uri.parse(urlHistorial),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token, 
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; 
      } else {
        throw data['msg'] ?? 'Error al obtener tu historial';
      }
    } catch (e) {
      if (e is String) throw e;
      throw 'Error de conexión con el Hub bro 😅';
    }
  }


  }