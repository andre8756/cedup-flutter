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
  // 1. FUNÇÃO DE DETALHES E EDIÇÃO (GET + PUT)
  // ===========================================================================
  Future<void> _fetchAndShowAccountDetails(int index) async {
    final accountSummary = _accounts[index];
    final accountId = accountSummary['id'].toString();

    // Mostra loading enquanto busca
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // BUSCA OS DADOS DETALHADOS (GET)
      final response = await ApiService.get('conta/banco/id/$accountId');

      if (!mounted) return;
      Navigator.of(context).pop(); // Fecha o loading

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        _showEditDetailsDialog(index, data);
      } else {
        _showSnack(
          response['error'] ?? 'Erro ao carregar detalhes',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fecha loading
      _showSnack('Erro de conexão: $e', Colors.red);
    }
  }

  void _showEditDetailsDialog(int index, Map<String, dynamic> data) {
    // Controladores para edição
    final chavePixController = TextEditingController(
      text: data['chavePix'] ?? '',
    );
    final urlController = TextEditingController(text: data['bancoUrl'] ?? '');

    // Variáveis de estado
    bool permitirTransacao = data['permitirTransacao'] ?? false;
    bool isSaving = false;

    // Dados somente leitura (para exibição)
    final String titular = data['titular'] ?? '-';
    final String nomeBanco = data['nomeBanco'] ?? '-';
    final double saldo = (data['saldo'] ?? 0.0).toDouble();
    final String dataCadastro = data['dataCadastro'] ?? '-';
    final int idBanco = data['id']; // Necessário para o PUT

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  // Ícone do banco no título
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 16,
                    child: ClipOval(
                      child:
                          (data['bancoUrl'] != null &&
                              data['bancoUrl'].toString().isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: data['bancoUrl'],
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.account_balance),
                            )
                          : const Icon(Icons.account_balance),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nomeBanco,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SEÇÃO: DADOS NÃO EDITÁVEIS
                    const Text(
                      "Informações Gerais",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Titular", titular),
                    _buildReadOnlyField(
                      "Saldo Atual",
                      "R\$ ${saldo.toStringAsFixed(2)}",
                    ),
                    _buildReadOnlyField("Data Cadastro", dataCadastro),

                    const Divider(height: 24),

                    // SEÇÃO: DADOS EDITÁVEIS
                    const Text(
                      "Editar Informações",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chave Pix
                    TextField(
                      controller: chavePixController,
                      decoration: const InputDecoration(
                        labelText: 'Chave Pix',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // URL do Banco
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL da Logo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Switch Permitir Transação
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          "Permitir Transações",
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          permitirTransacao ? "Sim" : "Não",
                          style: TextStyle(
                            color: permitirTransacao
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        value: permitirTransacao,
                        activeColor: const Color(0xFF1E88E5),
                        onChanged: (val) {
                          setStateDialog(() => permitirTransacao = val);
                        },
                      ),
                    ),

                    if (isSaving)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              actions: isSaving
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Fechar"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                        ),
                        onPressed: () async {
                          setStateDialog(() => isSaving = true);

                          // Monta objeto para atualização (Mantendo dados originais obrigatórios se o backend exigir)
                          final Map<String, dynamic> updateData = {
                            "id": idBanco,
                            "titular":
                                titular, // Envia de volta mesmo sem editar
                            "nomeBanco": nomeBanco, // Envia de volta
                            "saldo": saldo, // Envia de volta
                            "chavePix": chavePixController.text
                                .trim(), // Editado
                            "status": data['status'] ?? true,
                            "permitirTransacao": permitirTransacao, // Editado
                            "bancoUrl": urlController.text.trim(), // Editado
                          };

                          try {
                            // PUT para atualizar
                            final response = await ApiService.put(
                              'conta/banco/$idBanco',
                              updateData,
                            );

                            if (!mounted) return;
                            Navigator.of(context).pop(); // Fecha Dialog

                            if (response['success'] == true) {
                              // Atualiza lista local
                              setState(() {
                                _accounts[index]['icon'] = urlController.text
                                    .trim();
                                // Outros campos visíveis na lista não mudaram, mas o ícone pode ter mudado
                              });
                              _showSnack(
                                "Dados atualizados com sucesso!",
                                Colors.green,
                              );
                            } else {
                              _showSnack(
                                response['error'] ?? "Erro ao atualizar",
                                Colors.red,
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            _showSnack("Erro: $e", Colors.red);
                          }
                        },
                        child: const Text(
                          "Salvar Alterações",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  // Widget auxiliar para campos somente leitura
  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. FUNÇÃO DE ADICIONAR CONTA (POST) - (Mantida do passo anterior)
  // ===========================================================================
  void _showAddAccountDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController titularController = TextEditingController();
    final TextEditingController nomeBancoController = TextEditingController();
    final TextEditingController chavePixController = TextEditingController();
    final TextEditingController saldoController = TextEditingController(
      text: '0.00',
    );
    final TextEditingController urlController = TextEditingController();

    bool permitirTransacao = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                        TextFormField(
                          controller: titularController,
                          decoration: const InputDecoration(
                            labelText: 'Titular da Conta *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nomeBancoController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Banco *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: chavePixController,
                          decoration: const InputDecoration(
                            labelText: 'Chave Pix *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: saldoController,
                          decoration: const InputDecoration(
                            labelText: 'Saldo Inicial',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            labelText: 'URL da Logo (Opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text("Permitir Transações"),
                          value: permitirTransacao,
                          onChanged: (val) =>
                              setStateDialog(() => permitirTransacao = val),
                        ),
                        if (isSaving)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              ),
              actions: isSaving
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setStateDialog(() => isSaving = true);
                            double saldo =
                                double.tryParse(
                                  saldoController.text.replaceAll(',', '.'),
                                ) ??
                                0.0;

                            final Map<String, dynamic> novoBanco = {
                              "titular": titularController.text.trim(),
                              "nomeBanco": nomeBancoController.text.trim(),
                              "saldo": saldo,
                              "chavePix": chavePixController.text.trim(),
                              "status": true,
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
                                Navigator.of(context).pop();
                                final data = response['data'];
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
                                  'Cadastrado com sucesso!',
                                  Colors.green,
                                );
                              } else {
                                setStateDialog(() => isSaving = false);
                                _showSnack(
                                  response['error'] ?? 'Erro',
                                  Colors.red,
                                );
                              }
                            } catch (e) {
                              setStateDialog(() => isSaving = false);
                              _showSnack('Erro: $e', Colors.red);
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
  // 3. DELETAR E OUTROS (Mantidos)
  // ===========================================================================
  Future<void> _deleteAccount(int index) async {
    final account = _accounts[index];
    final accountId = account['id'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: Text('Deseja excluir "${account['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // fecha confirm
              // Loading simples
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final response = await ApiService.delete(
                'conta/banco/$accountId',
              );
              if (!mounted) return;
              Navigator.pop(context); // fecha loading

              if (response['success'] == true) {
                setState(
                  () => _accounts.removeWhere(
                    (acc) => acc['id'].toString() == accountId,
                  ),
                );
                _showSnack('Excluído com sucesso', Colors.green);
              } else {
                _showSnack(response['error'] ?? 'Erro ao excluir', Colors.red);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
              child: Text(
                'Nenhuma conta cadastrada',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return Card(
                  key: ValueKey(account['id']),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    // ADIÇÃO IMPORTANTE: Ao clicar no item, abre os detalhes
                    onTap: () => _fetchAndShowAccountDetails(index),
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: account['icon'] != null
                            ? CachedNetworkImage(
                                imageUrl: account['icon'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
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
        onPressed: _showAddAccountDialog,
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
