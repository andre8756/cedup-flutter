import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/accounts_card.dart';
import '../../widgets/recent_transactions_card.dart';
import '../manage_accounts/manage_accounts_screen.dart';
import '../transaction_screen/transaction_screen.dart';
import '../statement/statement_screen.dart';
import '../todos/todos_screen.dart'; // ← IMPORTANTE PARA A TELA "TODOS"

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  List<Map<String, dynamic>> accounts = [
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
  ];

  // Extrato completo
  final List<Map<String, dynamic>> statementTransactions = [
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
  ];

  // Transações recentes
  final List<Map<String, dynamic>> recentTransactions = [
    {
      "description": "Transferência recebida",
      "amount": 150.00,
      "date": DateTime(2024, 1, 15),
      "bankIcon":
          "https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-2-1.png",
    },
    {
      "description": "Pagamento de conta",
      "amount": -89.90,
      "date": DateTime(2024, 1, 14),
      "bankIcon":
          "https://altarendablog.com.br/wp-content/uploads/2023/12/3afb1b054f7646acabdcd1e953f77c7d_thumb1.jpg",
    },
    {
      "description": "Depósito salário",
      "amount": 2500.00,
      "date": DateTime(2024, 1, 10),
      "bankIcon":
          "https://www.publicitarioscriativos.com/wp-content/uploads/2018/09/nova-identidade-visual-da-caixa-pode-custar-ate-800-milhoes.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(userName: "Jorge"),
          Expanded(child: _buildCurrentScreen()),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }

  // TROCA ENTRE AS TELAS
  Widget _buildCurrentScreen() {
    switch (selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return TransactionScreen(accounts: accounts);
      case 2:
        return StatementScreen(transactions: statementTransactions);
      case 3:
        return TodosScreen(
          userData: {
            "titular": "Nicolas Rotta",
            "cpf": "12345678900",
            "email": "nicolas@email.com",
            "telefone": "47999999999",
            "saldoTotal": 1500.75,
            "status": true,
            "dataCadastro": "2025-11-23T20:00:00",
            "avatarUrl": "https://exemplo.com/avatar.png",
            "bancos": [
              {
                "id": 1,
                "nome": "Banco do Brasil",
                "agencia": "1234",
                "conta": "56789-0",
              },
            ],
          },
        );
      default:
        return _buildHomeContent();
    }
  }

  // CONTEÚDO DA HOME
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AccountsCard(
            totalBalance: _calculateTotalBalance(),
            accounts: accounts,
            onManageAccounts: _navigateToManageAccounts,
          ),
          RecentTransactionsCard(
            transactions: recentTransactions,
            onViewAll: _navigateToStatement,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  double _calculateTotalBalance() {
    return accounts.fold(0.0, (sum, account) => sum + account['balance']);
  }

  void _navigateToManageAccounts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageAccountsScreen(accounts: accounts),
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          accounts = value;
        });
      }
    });
  }

  void _navigateToStatement() {
    setState(() {
      selectedIndex = 2;
    });
  }
}
