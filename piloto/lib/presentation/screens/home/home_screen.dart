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
import '../../../services/api_service.dart'; // Importe seu ApiService
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
  double totalBalance = 0.0;

  // Listas de dados
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> allTransactions = []; // Para o extrato completo

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
      // 1. Buscar dados da conta (Usuário e Bancos)
      final userResponse = await ApiService.get('conta');

      if (userResponse['success'] == true) {
        final data = userResponse['data'];

        // Configurar dados básicos
        setState(() {
          userName = data['titular'] ?? "Usuário";
          totalBalance = (data['saldoTotal'] ?? 0.0).toDouble();
          userFullData = data;
        });

        // Mapear Bancos para o formato do Widget AccountsCard
        List<dynamic> bancosApi = data['bancos'] ?? [];
        List<Map<String, dynamic>> mappedAccounts = [];

        for (var banco in bancosApi) {
          mappedAccounts.add({
            "id": banco['id'], // Importante guardar o ID para buscar transações
            "name": banco['nomeBanco'] ?? "Banco",
            "balance": (banco['saldo'] ?? 0.0).toDouble(),
            // Se o bancoUrl vier nulo, usamos uma imagem genérica ou tratamos no widget
            "icon": banco['bancoUrl'] ?? "https://via.placeholder.com/50",
          });
        }

        setState(() {
          accounts = mappedAccounts;
        });

        // 2. Buscar Transações (Iterar sobre cada conta para buscar o extrato)
        await _fetchTransactions(mappedAccounts);
      } else {
        _showErrorSnackBar(userResponse['error'] ?? "Erro ao carregar dados.");
      }
    } catch (e) {
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

    // Definir período de busca (ex: últimos 90 dias)
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 90));

    // Formatar datas para o padrão esperado pela API (ISO 8601 costuma ser o padrão)
    // Ajuste o formato da string se sua API exigir algo diferente de ISO
    final String startStr = startDate.toIso8601String();
    final String endStr = now.toIso8601String();

    // Loop para buscar transações de cada banco do usuário
    // (Pode ser otimizado com Future.wait para rodar em paralelo)
    for (var acc in myAccounts) {
      final int contaId = acc['id'];
      final endpoint =
          'conta/banco/transacao/filtros?contaId=$contaId&dataInicio=$startStr&dataFim=$endStr';

      final response = await ApiService.get(endpoint);

      if (response['success'] == true) {
        // A API pode retornar uma lista ou um objeto. Assumindo lista baseada no contexto "filtros"
        List<dynamic> txList = [];
        if (response['data'] is List) {
          txList = response['data'];
        } else if (response['data'] != null) {
          // Caso retorne apenas um objeto solto (menos provável para filtro, mas possível)
          txList = [response['data']];
        }

        for (var tx in txList) {
          // Lógica para definir se é entrada (+) ou saída (-)
          // Se o titular do banco de origem for o usuário atual, é saída.
          // Como não temos o ID do usuário fácil aqui, vamos assumir pelo contexto ou valor.
          // O JSON fornecido de exemplo tem "bancoOrigemTitular": "Nicolas Rotta".
          // Vamos assumir que o backend manda o valor absoluto e nós decidimos o sinal,
          // ou usamos o ID da conta.

          double amount = (tx['valor'] ?? 0.0).toDouble();
          bool isExpense = tx['contaOrigemId'] == contaId;

          if (isExpense) {
            amount = -amount;
          }

          // Ícone: Se for despesa, mostra ícone do destino, senão da origem, ou do próprio banco
          String iconUrl = isExpense
              ? "https://cdn-icons-png.flaticon.com/512/1055/1055177.png" // Exemplo saída
              : "https://cdn-icons-png.flaticon.com/512/1055/1055180.png"; // Exemplo entrada

          // Tentar usar ícone do banco se disponível no JSON (não estava no exemplo, mas é bom prever)
          // Se não, usa o da conta atual para simplificar visualmente
          iconUrl = acc['icon'];

          tempTransactions.add({
            "bankName": isExpense
                ? tx['bancoDestinoNome']
                : tx['bancoOrigemNome'],
            "description": tx['descricao'] ?? "Transação",
            "amount": amount,
            "date": DateTime.tryParse(tx['dataTransacao']) ?? DateTime.now(),
            "bankIcon": iconUrl,
          });
        }
      }
    }

    // Ordenar por data (mais recente primeiro)
    tempTransactions.sort((a, b) => b['date'].compareTo(a['date']));

    if (mounted) {
      setState(() {
        allTransactions = tempTransactions;
        // Pega apenas as 5 primeiras para a home
        recentTransactions = tempTransactions.take(5).toList();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        return StatementScreen(
          transactions: allTransactions,
        ); // Passa lista completa
      case 3:
        return TodosScreen(
          // Passa os dados reais do usuário para a tela de perfil/todos
          userData: userFullData ?? {},
          onLogout: _logout,
        );
      default:
        return _buildHomeContent();
    }
  }

  // CONTEÚDO DA HOME
  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _fetchData, // Permite puxar para atualizar
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            AccountsCard(
              totalBalance: totalBalance,
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
      // Se voltarmos da tela de gerenciar, recarrega os dados para atualizar saldos
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
