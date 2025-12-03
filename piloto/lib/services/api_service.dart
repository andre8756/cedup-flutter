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
  // No arquivo api_service.dart
  // No arquivo api_service.dart

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      // 1. Limpeza da URL para evitar barras duplicadas
      final cleanEndpoint = endpoint.startsWith('/')
          ? endpoint.substring(1)
          : endpoint;
      final urlString = '$_baseUrl/$cleanEndpoint';
      final uri = Uri.parse(urlString);

      print('-------------------------------------------');
      print('🚀 [API DELETE] Iniciando requisição');
      print('🔗 URL: $urlString');
      print('🔑 Headers: $headers');
      print('-------------------------------------------');

      final response = await http.delete(uri, headers: headers);

      print('📥 [API DELETE] Resposta Recebida');
      print('🔢 Status Code: ${response.statusCode}');
      print('📦 Body: "${response.body}"');
      print('-------------------------------------------');

      // Sucesso (200 OK ou 204 No Content)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          try {
            return {'success': true, 'data': json.decode(response.body)};
          } catch (_) {
            return {'success': true, 'message': response.body};
          }
        } else {
          return {'success': true, 'message': 'Item deletado com sucesso'};
        }
      }
      // Erro de Autenticação
      else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sessão expirada.',
          'unauthorized': true,
        };
      }
      // Outros Erros (Backend recusou)
      else {
        String erroMsg = 'Erro ${response.statusCode}';
        try {
          final bodyJson = json.decode(response.body);
          // Tenta pegar a mensagem de erro do Spring Boot
          erroMsg = bodyJson['message'] ?? bodyJson['error'] ?? erroMsg;
        } catch (_) {
          // Se não for JSON, pega o texto puro
          if (response.body.isNotEmpty) erroMsg = response.body;
        }
        return {'success': false, 'error': erroMsg};
      }
    } catch (e) {
      print('❌ [API ERROR]: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Adicione este método dentro da classe ApiService

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final cleanEndpoint = endpoint.startsWith('/')
          ? endpoint.substring(1)
          : endpoint;

      final response = await http.put(
        Uri.parse('$_baseUrl/$cleanEndpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return {'success': true, 'data': json.decode(response.body)};
        }
        return {'success': true, 'data': {}};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sessão expirada.',
          'unauthorized': true,
        };
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Erro ao atualizar',
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
