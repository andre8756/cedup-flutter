import 'package:flutter/material.dart';
import '../manage_accounts/manage_accounts_screen.dart';
import '../statement/statement_screen.dart';

class TodosScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout; // Adicione este parâmetro

  const TodosScreen({
    super.key,
    required this.userData,
    required this.onLogout, // Adicione este parâmetro
  });

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  // Lista de transações de exemplo para o extrato
  final List<Map<String, dynamic>> _statementTransactions = [
    {
      "bankName": "Nubank",
      "description": "Transferência recebida",
      "amount": 900.03,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-2-1.png",
    },
    {
      "bankName": "Inter",
      "description": "Pagamento efetuado",
      "amount": 23.73,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://altarendablog.com.br/wp-content/uploads/2023/12/3afb1b054f7646acabdcd1e953f77c7d_thumb1.jpg",
    },
    {
      "bankName": "Caixa",
      "description": "Taxa de serviço",
      "amount": -50.03,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://www.publicitarioscriativos.com/wp-content/uploads/2018/09/nova-identidade-visual-da-caixa-pode-custar-ate-800-milhoes.png",
    },
    {
      "bankName": "Viacredit",
      "description": "Depósito",
      "amount": 900.03,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-2-1.png",
    },
    {
      "bankName": "Caixa",
      "description": "Transferência recebida",
      "amount": 90.03,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://www.publicitarioscriativos.com/wp-content/uploads/2018/09/nova-identidade-visual-da-caixa-pode-custar-ate-800-milhoes.png",
    },
    {
      "bankName": "Inter",
      "description": "Depósito",
      "amount": 150.03,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://altarendablog.com.br/wp-content/uploads/2023/12/3afb1b054f7646acabdcd1e953f77c7d_thumb1.jpg",
    },
    {
      "bankName": "Nubank",
      "description": "Compra online",
      "amount": 5.33,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-2-1.png",
    },
    {
      "bankName": "Nubank",
      "description": "Transferência",
      "amount": 10.03,
      "date": DateTime(2024, 1, 23),
      "bankIcon":
          "https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-2-1.png",
    },
  ];

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
            _infoTile("Titular", user["titular"]),
            _infoTile("CPF", user["cpf"]),
            _infoTile("Email", user["email"]),
            _infoTile("Telefone", user["telefone"]),
            _infoTile("Saldo total", "R\$ ${user['saldoTotal']}"),
            _infoTile("Status", user["status"] ? "Ativo" : "Inativo"),
            _infoTile(
              "Data de cadastro",
              user["dataCadastro"].toString().substring(0, 10),
            ),

            const SizedBox(height: 20),

            // ======== LINKS MAIS PRÓXIMOS ========
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageAccountsScreen(
                          accounts: [
                            {
                              "name": "Nubank",
                              "balance": 900.03,
                              "icon":
                                  "https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-2-1.png",
                            },
                            {
                              "name": "Inter",
                              "balance": 400.02,
                              "icon":
                                  "https://altarendablog.com.br/wp-content/uploads/2023/12/3afb1b054f7646acabdcd1e953f77c7d_thumb1.jpg",
                            },
                            {
                              "name": "Caixa",
                              "balance": 96.03,
                              "icon":
                                  "https://www.publicitarioscriativos.com/wp-content/uploads/2018/09/nova-identidade-visual-da-caixa-pode-custar-ate-800-milhoes.png",
                            },
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "Gerenciar Contas Bancárias",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatementScreen(
                          transactions: _statementTransactions,
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "Extrato Bancário",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ======== LOGOUT ========
            Center(
              child: GestureDetector(
                onTap: widget.onLogout, // Use o callback aqui
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
