import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppHeader extends StatefulWidget {
  final String userName;

  const AppHeader({super.key, required this.userName});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  bool _hasUnreadNotification = true;

  void _showNotificationsDialog() {
    setState(() {
      _hasUnreadNotification = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                "Notificações",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationItem(
                  "Boas-vindas ao Solvian",
                  "Agora",
                  Icons.celebration,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Seja muito bem-vindo ao aplicativo Solvian!\n\n"
                  "Estamos profundamente gratos pela sua preferência e confiança em nossa plataforma. "
                  "Aqui você poderá gerenciar e controlar todas as suas contas bancárias em um único ambiente integrado, "
                  "oferecendo praticidade e segurança para suas operações financeiras.\n\n"
                  "Recursos disponíveis:\n"
                  "• Acesso rápido ao resumo das contas vinculadas na página inicial\n"
                  "• Realização de transferências via PIX, com seleção da conta bancária desejada na seção de transações\n"
                  "• Emissão de extratos com filtros personalizados na página dedicada\n"
                  "• Gestão completa das informações e configurações da sua conta na seção 'Todos'\n\n"
                  "Estamos à disposição para proporcionar a melhor experiência em gestão financeira pessoal.",
                  style: TextStyle(fontSize: 14, height: 1.4),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E88E5),
      padding: const EdgeInsets.only(top: 40, bottom: 10, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl:
                        "https://marketplace.canva.com/A5alg/MAESXCA5alg/1/tl/canva-user-icon-MAESXCA5alg.png",
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bem vindo,",
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                onPressed: _showNotificationsDialog,
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              if (_hasUnreadNotification)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
