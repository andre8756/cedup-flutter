import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/accounts_card.dart';
import '../../widgets/recent_transactions_card.dart';
import '../manage_accounts/manage_accounts_screen.dart';
import '../transaction_screen/transaction_screen.dart';
import '../statement/statement_screen.dart';
import '../todos/todos_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../login/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  bool _isLoading = true;

  // Dados do Usuário
  String userName = "Usuário";
  String userAvatar =
      "https://marketplace.canva.com/A5alg/MAESXCA5alg/1/tl/canva-user-icon-MAESXCA5alg.png";
  double totalBalance = 0.0;

  // Listas de dados
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> allTransactions = [];

  // Variável para passar para a tela de perfil (TodosScreen)
  Map<String, dynamic>? userFullData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Buscar dados da conta ATUAL
      final userResponse = await ApiService.get(
        'conta/atual',
      ); // CORREÇÃO: Endpoint correto

      print('Resposta da API conta/atual: ${userResponse}'); // Debug

      if (userResponse['success'] == true) {
        final data = userResponse['data'];
        print('Dados do usuário: $data'); // Debug

        // Configurar dados básicos
        setState(() {
          userName = data['titular'] ?? "Usuário";
          userAvatar =
              data['avatarUrl'] ??
              "https://marketplace.canva.com/A5alg/MAESXCA5alg/1/tl/canva-user-icon-MAESXCA5alg.png";
          totalBalance = (data['saldoTotal'] ?? 0.0).toDouble();
          userFullData = data;
        });

        // Mapear Bancos para o formato do Widget AccountsCard
        List<dynamic> bancosApi = data['bancos'] ?? [];
        List<Map<String, dynamic>> mappedAccounts = [];

        for (var banco in bancosApi) {
          mappedAccounts.add({
            "id": banco['id'],
            "name": banco['nomeBanco'] ?? "Banco",
            "balance": (banco['saldo'] ?? 0.0).toDouble(),
            "icon":
                (banco['bancoUrl'] == null ||
                    banco['bancoUrl'].toString().isEmpty ||
                    banco['bancoUrl'].toString().toLowerCase() == 'null')
                ? null
                : banco['bancoUrl'].toString(),
            "permitirTransacao": banco['permitirTransacao'] ?? true,
            "chavePix":
                banco['chavePix'] ??
                '', // ADICIONE ESTA LINHA - NOME DO CAMPO EXATO DA API
          });

          // Debug: imprima os dados mapeados
          print(
            'Banco mapeado: ${banco['nomeBanco']}, ChavePix: ${banco['chavePix']}',
          );
        }

        setState(() {
          accounts = mappedAccounts;
        });

        // 2. Buscar Transações (se necessário)
        if (mappedAccounts.isNotEmpty) {
          await _fetchTransactions(mappedAccounts);
        } else {
          setState(() {
            recentTransactions = [];
            allTransactions = [];
          });
        }
      } else {
        String errorMsg = userResponse['error'] ?? "Erro ao carregar dados.";
        _showErrorSnackBar(errorMsg);

        // Se for erro de autenticação, redireciona para login
        if (userResponse['unauthorized'] == true) {
          await AuthService.logout();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      }
    } catch (e) {
      print('Erro no _fetchData: $e'); // Debug
      _showErrorSnackBar("Erro de conexão: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTransactions(List<Map<String, dynamic>> myAccounts) async {
    List<Map<String, dynamic>> tempTransactions = [];

    try {
      final response = await ApiService.get('conta/banco/transacao/filtros');

      if (response['success'] == true && response['data'] != null) {
        List<dynamic> txList = response['data'];

        for (var tx in txList) {
          // Formatar data
          DateTime? date;
          try {
            if (tx['dataTransacao'] != null) {
              final parts = tx['dataTransacao'].split(' - ');
              if (parts.length == 2) {
                final datePart = parts[0];
                final timePart = parts[1];
                final dateParts = datePart.split('/');
                final timeParts = timePart.split(':');

                if (dateParts.length == 3 && timeParts.length == 2) {
                  date = DateTime(
                    int.parse(dateParts[2]),
                    int.parse(dateParts[1]),
                    int.parse(dateParts[0]),
                    int.parse(timeParts[0]),
                    int.parse(timeParts[1]),
                  );
                }
              }
            }
          } catch (e) {
            print('Erro ao parsear data: ${tx['dataTransacao']}');
            date = DateTime.now();
          }

          // Verificar se é uma transação de saída (origem é uma das contas do usuário)
          bool isExpense = myAccounts.any(
            (acc) => acc['id'] == tx['contaOrigemId'],
          );

          // Determinar valor (negativo para saídas, positivo para entradas)
          double amount = (tx['valor'] ?? 0.0).toDouble();
          if (isExpense) {
            amount = -amount;
          }

          // Adicionar à lista de transações formatadas
          tempTransactions.add({
            'id': tx['id'],
            'contaOrigemId': tx['contaOrigemId'],
            'bancoOrigemNome': tx['bancoOrigemNome'],
            'bancoOrigemTitular': tx['bancoOrigemTitular'],
            'bancoOrigemChavePix': tx['bancoOrigemChavePix'],
            'contaDestinoId': tx['contaDestinoId'],
            'bancoDestinoNome': tx['bancoDestinoNome'],
            'bancoDestinoTitular': tx['bancoDestinoTitular'],
            'bancoDestinoChavePix': tx['bancoDestinoChavePix'],
            'valor': amount,
            'descricao': tx['descricao'] ?? 'Transação',
            'dataTransacao': tx['dataTransacao'],
            'date': date ?? DateTime.now(),
            'amount': amount, // Mantido para compatibilidade
            'description':
                tx['descricao'] ?? 'Transação', // Mantido para compatibilidade
          });
        }

        // Ordenar por data (mais recente primeiro)
        tempTransactions.sort((a, b) => b['date'].compareTo(a['date']));

        if (mounted) {
          setState(() {
            allTransactions = tempTransactions;
            recentTransactions = tempTransactions.take(5).toList();
          });
        }
      } else {
        _showErrorSnackBar("Erro ao carregar transações.");
      }
    } catch (e) {
      print('Erro no _fetchTransactions: $e');
      _showErrorSnackBar("Erro de conexão: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Passando o nome dinâmico para o Header
          AppHeader(userName: userName),
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
        return StatementScreen();
      case 3:
        return TodosScreen(userData: userFullData ?? {}, onLogout: _logout);
      default:
        return _buildHomeContent();
    }
  }

  // CONTEÚDO DA HOME
  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            AccountsCard(
              totalBalance: totalBalance,
              accounts: accounts,
              onManageAccounts: _navigateToManageAccounts,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToManageAccounts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageAccountsScreen(accounts: accounts),
      ),
    ).then((value) {
      if (mounted) _fetchData();
    });
  }

  void _navigateToStatement() {
    setState(() {
      selectedIndex = 2;
    });
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
