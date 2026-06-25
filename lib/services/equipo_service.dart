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

  Future<List<Equipo>> obtenerEquipos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Equipo.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los equipos');
    }
  }

  Future<List<Equipo>> obtenerAlertas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos/alertas'),
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

  Future<bool> registrarCalibracion(String codigo, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/equipos/$codigo/calibracion'),
      headers: _headers,
      body: jsonEncode(datos),
    );

    return response.statusCode == 200;
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
}