import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StatementScreen extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const StatementScreen({super.key, required this.transactions});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  String _selectedFilter = 'Últimos 30 dias';
  final List<String> _filterOptions = [
    'Últimos 7 dias',
    'Últimos 30 dias',
    'Últimos 3 meses',
    'Últimos 6 meses',
    'Este ano',
    'Ano passado',
    'Tudo',
  ];

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  void _printStatement() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.print, color: Colors.blue),
              SizedBox(width: 8),
              Text('Extrato Gerado'),
            ],
          ),
          content: const Text(
            'Extrato impresso com sucesso! Você pode salvar ou compartilhar o arquivo PDF.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Botão Imprimir Extrato e Filtro
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _printStatement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Imprimir',
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
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: _filterOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedFilter = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de transações
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Header da lista
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transações',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Valor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 20),

                            // Lista de transações
                            Expanded(
                              child: widget.transactions.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Nenhuma transação encontrada',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: widget.transactions.length,
                                      itemBuilder: (context, index) {
                                        final transaction =
                                            widget.transactions[index];
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                            leading: CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      transaction['bankIcon'] ??
                                                      '',
                                                  width: 40,
                                                  height: 40,
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
                                                        Icons.account_balance,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              transaction['bankName'] ??
                                                  transaction['description'] ??
                                                  'Transação',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            subtitle: Text(
                                              _formatDate(
                                                transaction['date'] ??
                                                    DateTime.now(),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            trailing: Text(
                                              'R\$${(transaction['amount'] ?? 0).abs().toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    (transaction['amount'] ??
                                                            0) >=
                                                        0
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
