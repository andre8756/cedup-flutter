import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AccountsCard extends StatefulWidget {
  final double totalBalance;
  final List<Map<String, dynamic>> accounts;
  final VoidCallback onManageAccounts; // Adicione este callback

  const AccountsCard({
    super.key,
    required this.totalBalance,
    required this.accounts,
    required this.onManageAccounts, // Adicione este parâmetro
  });

  @override
  State<AccountsCard> createState() => _AccountsCardState();
}

class _AccountsCardState extends State<AccountsCard> {
  bool _isBalanceVisible = true;

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Saldo Geral ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Saldo geral", style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: _toggleBalanceVisibility,
                  child: Icon(
                    _isBalanceVisible 
                      ? Icons.visibility_outlined 
                      : Icons.visibility_off_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              _isBalanceVisible 
                ? "R\$ ${widget.totalBalance.toStringAsFixed(2)}"
                : "*******",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              "Minhas contas",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const Divider(height: 24),

            // --- Lista de contas ---
            ...widget.accounts.map((acc) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: acc['icon'],
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(acc['name']),
                      ],
                    ),
                    Text(
                      _isBalanceVisible
                        ? "R\$ ${acc['balance'].toStringAsFixed(2)}"
                        : "*******"
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            Center(
              child: OutlinedButton(
                onPressed: widget.onManageAccounts, // Use o callback aqui
                child: const Text("Gerenciar contas"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}