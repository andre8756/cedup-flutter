import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecentTransactionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onViewAll;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.onViewAll,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  // Função para determinar se é entrada ou saída
  bool _isIncome(double amount) {
    return amount >= 0;
  }

  // Função para obter o ícone baseado no tipo de transação
  IconData _getTransactionIcon(bool isIncome, String? bankName) {
    if (bankName?.toLowerCase().contains('nubank') == true) {
      return Icons.account_balance_wallet;
    } else if (bankName?.toLowerCase().contains('itau') == true) {
      return Icons.account_balance;
    } else if (bankName?.toLowerCase().contains('bradesco') == true) {
      return Icons.money;
    } else if (bankName?.toLowerCase().contains('santander') == true) {
      return Icons.payment;
    } else if (bankName?.toLowerCase().contains('banco do brasil') == true) {
      return Icons.business;
    }
    return isIncome ? Icons.trending_up : Icons.trending_down;
  }

  // Função para obter a cor do ícone
  Color _getIconColor(bool isIncome) {
    return isIncome ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Últimas Transações",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),

            const Divider(height: 20),

            // Lista de transações
            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Nenhuma transação recente",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...transactions.take(5).map((transaction) {
                final amount = (transaction['amount'] ?? 0.0).toDouble();
                final isIncome = _isIncome(amount);
                final bankName = transaction['bankName'] ?? 'Transação';
                final description = transaction['description'] ?? 'Transação';
                final date = transaction['date'] is DateTime
                    ? transaction['date'] as DateTime
                    : DateTime.now();
                final bankIconUrl = transaction['bankIcon'];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Ícone do banco ou ícone padrão
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getIconColor(isIncome).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child:
                                    bankIconUrl != null &&
                                        bankIconUrl.toString().isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: bankIconUrl.toString(),
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              CircularProgressIndicator(
                                                strokeWidth: 1,
                                                color: _getIconColor(isIncome),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                _getTransactionIcon(
                                                  isIncome,
                                                  bankName,
                                                ),
                                                color: _getIconColor(isIncome),
                                                size: 20,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        _getTransactionIcon(isIncome, bankName),
                                        color: _getIconColor(isIncome),
                                        size: 20,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        bankName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isIncome
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          isIncome ? 'Entrada' : 'Saída',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isIncome
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "R\$${amount.abs().toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            isIncome ? 'Recebido' : 'Enviado',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            // Ver todas as transações
            if (transactions.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Ver todas as transações"),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
