import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../login/login_screen.dart';

class TransactionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;

  const TransactionScreen({super.key, required this.accounts});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String? _selectedAccountId;
  double _selectedBalance = 0.0;
  final TextEditingController _pixKeyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false; // Para controlar o estado de carregamento

  // Método para filtrar apenas bancos que permitem transação
  List<Map<String, dynamic>> get _filteredAccounts {
    if (widget.accounts.isEmpty) return [];

    return widget.accounts
        .where((account) => account['permitirTransacao'] == true)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Seleciona a primeira conta disponível da lista filtrada, se houver
    if (_filteredAccounts.isNotEmpty) {
      _selectedAccountId = _filteredAccounts[0]['id'].toString();
      _selectedBalance = (_filteredAccounts[0]['balance'] ?? 0.0).toDouble();

      // Debug: veja o que tem na primeira conta
      print('Primeira conta disponível: ${_filteredAccounts[0]}');
      print('ChavePix da primeira conta: ${_filteredAccounts[0]['chavePix']}');
    }

    // Debug: veja todas as contas filtradas
    print('Contas filtradas (permitem transação): ${_filteredAccounts.length}');
    for (var i = 0; i < _filteredAccounts.length; i++) {
      print(
        'Conta $i: ${_filteredAccounts[i]['name']} - ChavePix: ${_filteredAccounts[i]['chavePix']}',
      );
    }
  }

  @override
  void dispose() {
    _pixKeyController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAccountSelected(String? id) {
    if (id == null) return;
    setState(() {
      _selectedAccountId = id;
      final account = _filteredAccounts.firstWhere(
        (acc) => acc['id'].toString() == id,
        orElse: () => {'balance': 0.0},
      );
      _selectedBalance = (account['balance'] ?? 0.0).toDouble();
    });
  }

  Future<void> _performPayment() async {
    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0;
    final description = _descriptionController.text.trim();
    final pixKeyDestino = _pixKeyController.text.trim();

    if (_selectedAccountId == null) {
      _showSnack('Selecione um banco para realizar o pagamento.');
      return;
    }
    if (pixKeyDestino.isEmpty) {
      _showSnack('Informe a chave Pix.');
      return;
    }
    if (value <= 0) {
      _showSnack('Informe um valor válido.');
      return;
    }
    if (value > _selectedBalance) {
      _showSnack(
        'Saldo insuficiente. Saldo disponível: R\$${_selectedBalance.toStringAsFixed(2)}',
      );
      return;
    }
    if (description.isEmpty) {
      _showSnack('Informe uma descrição para a transação.');
      return;
    }
    if (description.length > 50) {
      _showSnack('A descrição não pode ter mais que 50 caracteres.');
      return;
    }

    try {
      // Encontrar a conta selecionada para obter informações
      final contaSelecionada = _filteredAccounts.firstWhere(
        (acc) => acc['id'].toString() == _selectedAccountId,
      );

      // Debug: verifique o que está na conta selecionada
      print('Conta selecionada: ${contaSelecionada}');
      print('ChavePix da conta: ${contaSelecionada['chavePix']}');
      print('ChavePix destino: $pixKeyDestino');
      print('Valor: $value');
      print('Descrição: $description');

      final chavePixOrigem = contaSelecionada['chavePix'] ?? '';

      if (chavePixOrigem.isEmpty) {
        _showSnack('Não foi possível obter a chave Pix da conta de origem.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Preparar os dados para a requisição
      final Map<String, dynamic> transacaoData = {
        "valor": value,
        "descricao": description,
        "chavePixBancoOrigem": chavePixOrigem,
        "chavePixBancoDestino": pixKeyDestino,
      };

      print('Dados da transação: $transacaoData');

      // Fazer a requisição POST
      final response = await ApiService.post(
        'conta/banco/transacao',
        transacaoData,
      );

      setState(() {
        _isLoading = false;
      });

      print('Resposta da API: $response');

      if (response['success'] == true) {
        // Transação bem-sucedida
        _showSuccessDialog(value, pixKeyDestino, description);
      } else {
        // Tratar erro
        if (response['unauthorized'] == true) {
          // Sessão expirada
          await AuthService.logout();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          _showSnack(response['error'] ?? 'Erro ao realizar transação.');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Erro na transação: $e');
      _showSnack('Erro: $e');
    }
  }

  void _showSuccessDialog(double value, String pixKey, String description) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transferência Realizada',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'PIX de R\$${value.toStringAsFixed(2)} enviado com sucesso!',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Destino:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  pixKey,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'Descrição:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _cancelTransaction();
                      // Atualizar o saldo após a transação
                      setState(() {
                        _selectedBalance -= value;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _cancelTransaction() {
    _pixKeyController.clear();
    _valueController.clear();
    _descriptionController.clear();
  }

  void _showSnack(String message) {
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
    final hasAccounts = _filteredAccounts.isNotEmpty;

    return Scaffold(
      body: hasAccounts
          ? Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saldo em conta
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'SALDO EM CONTA',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'R\$${_selectedBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Formulário
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              TextField(
                                controller: _pixKeyController,
                                decoration: const InputDecoration(
                                  labelText: 'Chave Pix do Destino',
                                  hintText:
                                      'CPF, e-mail, telefone ou chave aleatória',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.key),
                                ),
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _valueController,
                                decoration: const InputDecoration(
                                  labelText: 'Valor da Transferência',
                                  border: OutlineInputBorder(),
                                  prefixText: 'R\$ ',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Descrição',
                                  hintText:
                                      'Digite uma descrição (máx. 50 caracteres)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                ),
                                maxLength: 50,
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 16),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Banco de Origem',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedAccountId,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items: _filteredAccounts.map((account) {
                                    return DropdownMenuItem<String>(
                                      value: account['id'].toString(),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.transparent,
                                            child: ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: account['icon'] ?? '',
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 1,
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => const Icon(
                                                      Icons
                                                          .account_balance_wallet,
                                                      size: 25,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(account['name'] ?? ''),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isLoading
                                      ? null
                                      : _onAccountSelected,
                                ),
                              ),
                              if (widget.accounts.isNotEmpty &&
                                  widget.accounts.length >
                                      _filteredAccounts.length)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${widget.accounts.length - _filteredAccounts.length} banco(s) não disponível(is) para transações',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _performPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.payment,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Pagar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _cancelTransaction,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.accounts.isEmpty
                          ? 'Nenhuma conta cadastrada.'
                          : 'Nenhuma conta disponível para realizar transações.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    if (widget.accounts.isNotEmpty)
                      Text(
                        '${widget.accounts.length} banco(s) encontrado(s), mas nenhum permite transações no momento.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
