import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  // CORREÇÃO: Mudado de http para https
  static const String _baseUrl = 'https://cedup-back-deploy.onrender.com';

  // ... O resto do código permanece igual ...
  static Future<Map<String, dynamic>> get(String endpoint) async {
    // ... código existente
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers,
      );
      // ... continue com sua lógica
      // Lembre-se que as lógicas de json.decode aqui também devem ser protegidas se necessário
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      // ... resto do código
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
    // Adicionei este return para satisfazer o compilador caso caia fora dos ifs
    return {'success': false, 'error': 'Erro inesperado'};
  }

  // Repita a lógica para post, put, delete conforme seu arquivo original
  // Apenas certifique-se que _baseUrl está com HTTPS.
}
