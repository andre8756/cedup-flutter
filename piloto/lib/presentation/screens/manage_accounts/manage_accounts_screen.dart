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
        'id': acc['id'],
        'name': acc['name']?.toString() ?? 'Conta',
        'icon':
            (acc['icon']?.toString().isNotEmpty == true &&
                acc['icon'].toString() != 'null')
            ? acc['icon'].toString()
            : null,
        'balance': (acc['balance'] ?? 0.0).toDouble(),
      };
    }).toList();
  }

  // ===========================================================================
  // FUNÇÃO DE ADICIONAR CONTA (POST)
  // ===========================================================================
  void _showAddAccountDialog() {
    final _formKey = GlobalKey<FormState>();

    // Controllers
    final TextEditingController titularController = TextEditingController();
    final TextEditingController nomeBancoController = TextEditingController();
    final TextEditingController chavePixController = TextEditingController();
    final TextEditingController saldoController = TextEditingController(
      text: '0.00',
    );
    final TextEditingController urlController = TextEditingController();

    // Estado inicial do Switch
    bool permitirTransacao = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible:
          false, // Evita fechar clicando fora se estiver salvando
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Adicionar Nova Conta'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TITULAR (Obrigatório)
                        TextFormField(
                          controller: titularController,
                          decoration: const InputDecoration(
                            labelText: 'Titular da Conta *',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // NOME DO BANCO (Obrigatório)
                        TextFormField(
                          controller: nomeBancoController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Banco *',
                            hintText: 'Ex: Nubank, Inter...',
                            prefixIcon: Icon(Icons.account_balance),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // CHAVE PIX (Obrigatório)
                        TextFormField(
                          controller: chavePixController,
                          decoration: const InputDecoration(
                            labelText: 'Chave Pix *',
                            prefixIcon: Icon(Icons.qr_code),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // SALDO (Opcional - Default 0)
                        TextFormField(
                          controller: saldoController,
                          decoration: const InputDecoration(
                            labelText: 'Saldo Inicial',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // URL DA IMAGEM (Opcional)
                        TextFormField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            labelText: 'URL da Logo (Opcional)',
                            hintText: 'https://...',
                            prefixIcon: Icon(Icons.image),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SWITCH - PERMITIR TRANSAÇÃO
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SwitchListTile(
                            title: const Text(
                              "Permitir Transações",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              permitirTransacao ? "Ativado" : "Desativado",
                              style: TextStyle(
                                fontSize: 12,
                                color: permitirTransacao
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            value: permitirTransacao,
                            activeColor: const Color(0xFF1E88E5),
                            onChanged: (bool value) {
                              setStateDialog(() {
                                permitirTransacao = value;
                              });
                            },
                          ),
                        ),

                        // MENSAGEM DE CARREGAMENTO
                        if (isSaving)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text("Salvando banco..."),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: isSaving
                  ? [] // Esconde botões enquanto salva
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setStateDialog(() => isSaving = true);

                            // Tratamento do saldo (troca vírgula por ponto)
                            double saldo = 0.0;
                            try {
                              String saldoText = saldoController.text
                                  .replaceAll(',', '.');
                              saldo = double.parse(saldoText);
                            } catch (_) {
                              saldo = 0.0;
                            }

                            // Montagem do JSON
                            final Map<String, dynamic> novoBanco = {
                              "titular": titularController.text.trim(),
                              "nomeBanco": nomeBancoController.text.trim(),
                              "saldo": saldo,
                              "chavePix": chavePixController.text.trim(),
                              "status": true, // Padrão
                              "permitirTransacao": permitirTransacao,
                              "bancoUrl": urlController.text.trim().isEmpty
                                  ? null
                                  : urlController.text.trim(),
                            };

                            try {
                              final response = await ApiService.post(
                                'conta/banco',
                                novoBanco,
                              );

                              if (!mounted) return;

                              if (response['success'] == true) {
                                Navigator.of(context).pop(); // Fecha Dialog

                                final data = response['data'];

                                // Adiciona na lista local para feedback imediato
                                setState(() {
                                  _accounts.add({
                                    'id': data['id'],
                                    'name':
                                        data['nomeBanco'] ??
                                        novoBanco['nomeBanco'],
                                    'icon':
                                        data['bancoUrl'] ??
                                        novoBanco['bancoUrl'],
                                    'balance': (data['saldo'] ?? saldo)
                                        .toDouble(),
                                  });
                                });

                                _showSnack(
                                  'Banco cadastrado com sucesso!',
                                  Colors.green,
                                );
                              } else {
                                setStateDialog(() => isSaving = false);
                                if (response['unauthorized'] == true) {
                                  Navigator.of(context).pop();
                                  _handleUnauthorized();
                                } else {
                                  _showSnack(
                                    response['error'] ?? 'Erro ao cadastrar.',
                                    Colors.red,
                                  );
                                }
                              }
                            } catch (e) {
                              setStateDialog(() => isSaving = false);
                              _showSnack('Erro de conexão: $e', Colors.red);
                            }
                          }
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // FUNÇÃO DE DELETAR CONTA (MANTIDA IGUAL)
  // ===========================================================================
  Future<void> _deleteAccount(int index) async {
    final account = _accounts[index];
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
                          final response = await ApiService.delete(
                            'conta/banco/$accountId',
                          );

                          if (!mounted) return;
                          Navigator.of(context).pop();

                          if (response['success'] == true) {
                            setState(() {
                              // Remove usando removeWhere para garantir integridade
                              _accounts.removeWhere(
                                (acc) => acc['id'].toString() == accountId,
                              );
                            });
                            _showSnack(
                              'Conta excluída com sucesso!',
                              Colors.green,
                            );
                          } else {
                            if (response['unauthorized'] == true) {
                              _handleUnauthorized();
                            } else {
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
                // Usamos ValueKey com ID para evitar bugs visuais ao deletar
                final accountIdKey =
                    account['id']?.toString() ?? index.toString();

                return Card(
                  key: ValueKey(accountIdKey),
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
      // BOTÃO FLUTUANTE QUE ABRE O MODAL
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
