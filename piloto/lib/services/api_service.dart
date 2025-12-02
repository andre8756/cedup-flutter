import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'http://cedup-back-deploy.onrender.com/api';

  // Método genérico para requisições GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 401) {
        // Token inválido ou expirado
        await AuthService.logout();
        return {
          'success': false,
          'error': 'Sessão expirada. Faça login novamente.',
          'unauthorized': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: $e',
      };
    }
  }

  // Método genérico para requisições POST
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        return {
          'success': false,
          'error': 'Sessão expirada. Faça login novamente.',
          'unauthorized': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: $e',
      };
    }
  }

  // Método genérico para requisições PUT
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        return {
          'success': false,
          'error': 'Sessão expirada. Faça login novamente.',
          'unauthorized': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: $e',
      };
    }
  }

  // Método genérico para requisições DELETE
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        return {
          'success': false,
          'error': 'Sessão expirada. Faça login novamente.',
          'unauthorized': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: $e',
      };
    }
  }
}