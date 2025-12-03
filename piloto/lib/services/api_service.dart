import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'https://cedup-back-deploy.onrender.com';

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return {'success': true, 'data': json.decode(response.body)};
        } else {
          return {'success': true, 'data': {}};
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sessão expirada. Faça login novamente.',
          'unauthorized': true,
        };
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Erro desconhecido',
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Erro ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // ADICIONE ESTE MÉTODO POST
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Se a resposta for vazia, retorna sucesso sem dados
        if (response.body.isNotEmpty) {
          return {'success': true, 'data': json.decode(response.body)};
        } else {
          return {'success': true, 'data': {}};
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sessão expirada. Faça login novamente.',
          'unauthorized': true,
        };
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Erro desconhecido',
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Erro ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}
