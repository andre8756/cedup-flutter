import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../login/login_screen.dart';

class ManageAccountsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;

  const ManageAccountsScreen({super.key, required this.accounts});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  late List<Map<String, dynamic>> _accounts;

  @override
  void initState() {
    super.initState();
    _initializeAccounts();
  }

  void _initializeAccounts() {
    _accounts = widget.accounts.map((acc) {
      return {
        'id': acc['id'], // Mantém o tipo original (int ou string)
        'name': acc['name']?.toString() ?? 'Conta',
        'icon':
            (acc['icon']?.toString().isNotEmpty == true &&
                acc['icon'].toString() != 'null')
            ? acc['icon'].toString()
            : null, // Deixe null para cair no placeholder da UI
        'balance': (acc['balance'] ?? 0.0).toDouble(),
      };
    }).toList();
  }

  // No arquivo manage_accounts_screen.dart

  Future<void> _deleteAccount(int index) async {
    final account = _accounts[index];

    // LOG CRÍTICO: Veja isso no console quando clicar em deletar
    print('🛑 Tentando deletar conta na posição $index');
    print('📄 Dados da conta: $account');

    // Garante que pegamos o ID, seja ele int ou String
    final accountId = account['id'].toString();

    if (accountId == 'null' || accountId.isEmpty) {
      _showSnack('Erro: ID da conta não encontrado.', Colors.red);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Confirmar Exclusão'),
              content: isDeleting
                  ? Row(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text("Aguarde..."),
                      ],
                    )
                  : Text(
                      'Tem certeza que deseja excluir "${account['name']}"?\n\n'
                      '⚠️ Se houver transações vinculadas, a exclusão pode falhar.',
                    ),
              actions: isDeleting
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          setStateDialog(() => isDeleting = true);

                          // Chamada para a API
                          final response = await ApiService.delete(
                            'conta/banco/$accountId',
                          );

                          if (!mounted) return;
                          Navigator.of(context).pop(); // Fecha dialog

                          if (response['success'] == true) {
                            setState(() {
                              _accounts.removeAt(index);
                            });
                            _showSnack(
                              'Conta excluída com sucesso!',
                              Colors.green,
                            );
                          } else {
                            // Se falhar, mostra o erro exato que veio do log
                            if (response['unauthorized'] == true) {
                              _handleUnauthorized();
                            } else {
                              // Aqui você vai ver o motivo real (ex: Foreign Key Constraint)
                              _showSnack(
                                'Falha: ${response['error']}',
                                Colors.red,
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Excluir',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _handleUnauthorized() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ... (Mantenha o _showAddAccountDialog e o build como estavam)
  // Vou reimplementar o build apenas para garantir a chamada correta do ícone

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Contas'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: _accounts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma conta cadastrada',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final iconUrl = account['icon'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: iconUrl != null
                            ? CachedNetworkImage(
                                imageUrl: iconUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.account_balance),
                              )
                            : const Icon(
                                Icons.account_balance,
                                color: Colors.blue,
                              ),
                      ),
                    ),
                    title: Text(account['name']),
                    subtitle: Text(
                      'R\$ ${(account['balance'] as double).toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAccount(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Sua função de adicionar aqui
        },
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
