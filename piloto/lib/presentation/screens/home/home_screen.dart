import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/accounts_card.dart';
import '../../widgets/recent_transactions_card.dart';
import '../manage_accounts/manage_accounts_screen.dart';
import '../transaction_screen/transaction_screen.dart';

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

  final List<Map<String, dynamic>> transactions = [
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
    {
      "description": "Compra supermercado",
      "amount": -156.43,
      "date": DateTime(2024, 1, 8),
      "bankIcon":
          "https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-2-1.png",
    },
    {
      "description": "Transferência PIX",
      "amount": -300.00,
      "date": DateTime(2024, 1, 5),
      "bankIcon":
          "https://altarendablog.com.br/wp-content/uploads/2023/12/3afb1b054f7646acabdcd1e953f77c7d_thumb1.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(userName: "Jorge"),
          Expanded(
            child: _buildCurrentScreen(),
          ),
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

  Widget _buildCurrentScreen() {
    switch (selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return TransactionScreen(accounts: accounts);
      case 2:
        return _buildPlaceholderScreen("Extrato");
      case 3:
        return _buildPlaceholderScreen("Todos");
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AccountsCard(
            totalBalance: _calculateTotalBalance(),
            accounts: accounts,
            onManageAccounts: _navigateToManageAccounts,
          ),
          RecentTransactionsCard(transactions: transactions),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlaceholderScreen(String title) {
    return Center(
      child: Text(
        "Tela de $title - Em desenvolvimento",
        style: const TextStyle(fontSize: 18, color: Colors.grey),
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
}