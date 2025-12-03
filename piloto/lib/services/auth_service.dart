import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // CORREÇÃO: Mudado de http para https
  static const String _baseUrl =
      'https://cedup-back-deploy.onrender.com/api/auth';
  static String? _token;

  // Método para fazer login
  static Future<Map<String, dynamic>> login(
    String identificador,
    String senha,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identificador': identificador, 'senha': senha}),
      );

      // Verificação de debug (opcional, ajuda a ver o que o servidor respondeu)
      // print('Status Code: ${response.statusCode}');
      // print('Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'error': 'Servidor retornou resposta vazia.',
          };
        }

        final Map<String, dynamic> data = json.decode(response.body);
        _token = data['token'];

        // Salvar o token localmente
        if (_token != null) {
          await _saveToken(_token!);
          return {'success': true, 'token': _token};
        } else {
          return {
            'success': false,
            'error': 'Token não fornecido pelo servidor.',
          };
        }
      } else {
        // Tenta decodificar o erro, mas se falhar, retorna mensagem genérica
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Erro ao fazer login',
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Erro ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // ... (Mantenha os outros métodos _saveToken, getToken, isLoggedIn, logout, getAuthHeaders iguais)

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Método para registrar usuário
  static Future<Map<String, dynamic>> register(
    String titular,
    String cpf,
    String email,
    String telefone,
    String senha,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/register');

      final Map<String, dynamic> userData = {
        "titular": titular,
        "cpf": cpf.replaceAll(RegExp(r'[^0-9]'), ''),
        "email": email,
        "telefone": telefone.replaceAll(RegExp(r'[^0-9]'), ''),
        "senha": senha,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // CORREÇÃO DO BUG FORMAT EXCEPTION:
        // Verifica se o corpo começa com '{', indicando JSON.
        // Se não começar, é texto puro (ex: "Usuário registrado com sucesso!")
        if (response.body.trim().startsWith('{')) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('token') && data['token'] != null) {
            _token = data['token'];
            await _saveToken(_token!);
            return {'success': true, 'token': _token};
          } else {
            // Retornou JSON mas sem token, faz login
            return await login(email, senha);
          }
        } else {
          // É TEXTO PURO (O caso do seu erro).
          // Significa sucesso, então fazemos login automático.
          return await login(email, senha);
        }
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Erro ao cadastrar usuário',
          };
        } catch (_) {
          // Se der erro e não for JSON, retorna o corpo como mensagem
          return {
            'success': false,
            'error': response.body.isNotEmpty
                ? response.body
                : 'Erro ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}
