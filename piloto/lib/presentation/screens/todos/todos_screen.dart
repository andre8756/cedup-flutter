import 'package:flutter/material.dart';
import '../manage_accounts/manage_accounts_screen.dart';
import '../../../services/api_service.dart'; // Certifique-se que o caminho do import está correto

class TodosScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const TodosScreen({
    super.key,
    required this.userData,
    required this.onLogout,
  });

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  // Função para processar o Logout no servidor e depois localmente
  Future<void> _handleLogout() async {
    try {
      // Chama o endpoint para invalidar o token no backend (Blacklist)
      // O ApiService já injeta o Header "Authorization: Bearer ..."
      await ApiService.post('api/auth/logout', {});
    } catch (e) {
      // Se der erro (ex: internet caiu), apenas loga o erro,
      // mas permite que o usuário saia do app mesmo assim.
      print("Erro ao comunicar logout ao servidor: $e");
    } finally {
      // Executa a callback que limpa o token local e navega para o Login
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ======== INFORMAÇÕES DO USUÁRIO ========
            _infoTile("Titular", user["titular"] ?? ""),
            _infoTile("CPF", user["cpf"] ?? ""),
            _infoTile("Email", user["email"] ?? ""),
            _infoTile("Telefone", user["telefone"] ?? ""),
            _infoTile("Saldo total", "R\$ ${user['saldoTotal'] ?? 0.0}"),
            _infoTile("Status", (user["status"] == true) ? "Ativo" : "Inativo"),
            _infoTile(
              "Data de cadastro",
              user["dataCadastro"] != null
                  ? user["dataCadastro"].toString().substring(0, 10)
                  : "",
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 30),

            // ======== LOGOUT ========
            Center(
              child: GestureDetector(
                onTap:
                    _handleLogout, // Alterado para chamar a função com a lógica da API
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "fazer logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }
}
