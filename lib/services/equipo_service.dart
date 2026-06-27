import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipo.dart';

class EquipoService {
  static const String baseUrl = 'https://equipos-lamyg.onrender.com';
  static const String apiKey = 'lamyg-2026-equipos-secretkey-x9k2m';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': apiKey,
  };

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al iniciar sesión');
    }
  }

  Future<Map<String, dynamic>> registro(Map<String, dynamic> datos) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registro'),
      headers: _headers,
      body: jsonEncode(datos),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al registrarse');
    }
  }

  // Equipos
  Future<List<Equipo>> obtenerEquipos(String labId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos?lab_id=$labId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Equipo.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los equipos');
    }
  }

  Future<List<Equipo>> obtenerAlertas(String labId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos/alertas?lab_id=$labId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Equipo.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar las alertas');
    }
  }

  Future<bool> crearEquipo(Map<String, dynamic> datos) async {
    final response = await http.post(
      Uri.parse('$baseUrl/equipos'),
      headers: _headers,
      body: jsonEncode(datos),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> actualizarEquipo(String codigo, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/equipos/$codigo'),
      headers: _headers,
      body: jsonEncode(datos),
    );
    return response.statusCode == 200;
  }

  Future<bool> eliminarEquipo(String codigo) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/equipos/$codigo'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  Future<http.Response> exportarExcel(String labId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos/exportar?lab_id=$labId'),
      headers: _headers,
    );
    return response;
  }
}