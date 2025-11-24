import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecentTransactionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onViewAll; // Adicione este callback

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.onViewAll, // Adicione este parâmetro
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
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
                  onPressed: onViewAll, // Use o callback aqui também
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Ícone do banco
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: transaction['bankIcon'],
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                        strokeWidth: 1,
                                      ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.account_balance,
                                        size: 16,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction['description'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(transaction['date']),
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
                      Text(
                        "R\$ ${transaction['amount'].abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction['amount'] >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            // Ver todas as transações
            if (transactions.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed: onViewAll, // Use o callback aqui
                  child: const Text("Ver todas as transações"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
