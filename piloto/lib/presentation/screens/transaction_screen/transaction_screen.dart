import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    // Seleciona a primeira conta disponível, se houver
    if (widget.accounts.isNotEmpty) {
      _selectedAccountId = widget.accounts[0]['id'].toString();
      _selectedBalance = (widget.accounts[0]['balance'] ?? 0.0).toDouble();
    }
  }

  void _onAccountSelected(String? id) {
    if (id == null) return;
    setState(() {
      _selectedAccountId = id;
      final account = widget.accounts.firstWhere(
        (acc) => acc['id'].toString() == id,
        orElse: () => {'balance': 0.0},
      );
      _selectedBalance = (account['balance'] ?? 0.0).toDouble();
    });
  }

  void _performPayment() {
    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0;

    if (_selectedAccountId == null) {
      _showSnack('Selecione um banco para realizar o pagamento.');
      return;
    }
    if (_pixKeyController.text.isEmpty) {
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

    // Simula pagamento bem-sucedido
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Transferência Realizada'),
          ],
        ),
        content: Text(
          'PIX de R\$${value.toStringAsFixed(2)} enviado com sucesso para:\n${_pixKeyController.text}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pixKeyController.clear();
              _valueController.clear();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelTransaction() {
    _pixKeyController.clear();
    _valueController.clear();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAccounts = widget.accounts.isNotEmpty;

    return Scaffold(
      body: hasAccounts
          ? SingleChildScrollView(
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
                              labelText: 'Chave Pix',
                              hintText:
                                  'CPF, e-mail, telefone ou chave aleatória',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.key),
                            ),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Banco Selecionado',
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
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedAccountId,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down),
                              items: widget.accounts.map((account) {
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
                                                  Icons.account_balance_wallet,
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
                              onChanged: _onAccountSelected,
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
                          onPressed: _performPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, color: Colors.white),
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
                          onPressed: _cancelTransaction,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
            )
          : Center(
              child: Text(
                'Nenhuma conta disponível para realizar transações.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),
    );
  }
}
