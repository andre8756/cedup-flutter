import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AccountsCard extends StatefulWidget {
  final double totalBalance;
  final List<Map<String, dynamic>> accounts;
  final VoidCallback onManageAccounts;

  const AccountsCard({
    super.key,
    required this.totalBalance,
    required this.accounts,
    required this.onManageAccounts,
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

  // Widget para exibir o ícone do banco
  Widget _buildBankIcon(String? iconUrl, String bankName) {
    // Se a URL for nula, vazia ou "null", mostra o ícone padrão
    if (iconUrl == null || iconUrl.isEmpty || iconUrl.toLowerCase() == 'null') {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.blueGrey[100],
        child: Icon(
          Icons.account_balance_wallet,
          color: Colors.blueGrey[800],
          size: 24,
        ),
      );
    }

    // Se tiver URL válida, tenta carregar a imagem
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: iconUrl,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.blueGrey[50],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) {
            // Se falhar ao carregar, mostra o ícone padrão
            return Container(
              color: Colors.blueGrey[50],
              child: Center(
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.blueGrey[600],
                  size: 24,
                ),
              ),
            );
          },
        ),
      ),
    );
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
                const Text(
                  "Saldo geral",
                  style: TextStyle(color: Colors.black54),
                ),
                GestureDetector(
                  onTap: _toggleBalanceVisibility,
                  child: Icon(
                    _isBalanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey[700],
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
            if (widget.accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Nenhuma conta cadastrada",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...widget.accounts.map((acc) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildBankIcon(acc['icon'], acc['name']),
                          const SizedBox(width: 12),
                          Text(
                            acc['name'],
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      Text(
                        _isBalanceVisible
                            ? "R\$ ${acc['balance'].toStringAsFixed(2)}"
                            : "*******",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            Center(
              child: OutlinedButton(
                onPressed: widget.onManageAccounts,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Gerenciar contas"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
