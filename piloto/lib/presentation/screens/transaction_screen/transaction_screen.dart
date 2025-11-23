import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TransactionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;

  const TransactionScreen({super.key, required this.accounts});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String? _selectedAccount;
  final TextEditingController _pixKeyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  double _selectedBalance = 0.0;

  @override
  void initState() {
    super.initState();
    // Seleciona a primeira conta por padrão
    if (widget.accounts.isNotEmpty) {
      _selectedAccount = widget.accounts[0]['name'];
      _selectedBalance = widget.accounts[0]['balance'];
    }
  }

  void _onAccountSelected(String? accountName) {
    setState(() {
      _selectedAccount = accountName;
      if (accountName != null) {
        final account = widget.accounts.firstWhere(
          (acc) => acc['name'] == accountName,
          orElse: () => {'balance': 0.0},
        );
        _selectedBalance = account['balance'];
      }
    });
  }

  void _performPayment() {
    final value = double.tryParse(_valueController.text) ?? 0.0;

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um banco'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_pixKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe a chave Pix'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe um valor válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (value > _selectedBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo insuficiente. Saldo disponível: R\$${_selectedBalance.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simulação de pagamento bem-sucedido
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                // Limpa os campos após transferência bem-sucedida
                _pixKeyController.clear();
                _valueController.clear();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _cancelTransaction() {
    _pixKeyController.clear();
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Saldo em conta - SEM CARD E CENTRALIZADO
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'SALDO EM CONTA',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'R\$${_selectedBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card do Formulário
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Campo Chave Pix
                              TextField(
                                controller: _pixKeyController,
                                decoration: const InputDecoration(
                                  labelText: 'Chave Pix',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText:
                                      'CPF, e-mail, telefone ou chave aleatória',
                                  prefixIcon: Icon(Icons.key),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Campo Valor
                              TextField(
                                controller: _valueController,
                                decoration: const InputDecoration(
                                  labelText: 'Valor da Transferência',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  prefixText: 'R\$ ',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Banco Selecionado
                              const Text(
                                'Banco Selecionado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Dropdown para seleção de banco
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedAccount,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items: widget.accounts.map((account) {
                                    return DropdownMenuItem<String>(
                                      value: account['name'],
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.transparent,
                                            child: ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: account['icon'],
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 1,
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(
                                                          Icons.account_balance,
                                                          size: 16,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            account['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
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
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
