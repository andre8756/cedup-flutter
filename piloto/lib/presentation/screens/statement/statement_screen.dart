import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart'; // Não é estritamente necessário se usar SAF, mas pode manter
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../../../services/baixar_pdf_service.dart'; // Seu serviço atualizado

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  // Estados de filtro
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFilter = 'Últimos 30 dias';

  // Estados de carregamento
  bool _isLoading = false;
  bool _isDownloadingPdf = false;

  // Listas
  List<Map<String, dynamic>> _transactions = [];
  final List<String> _filterOptions = [
    'Últimos 7 dias',
    'Últimos 30 dias',
    'Últimos 3 meses',
    'Últimos 6 meses',
    'Este ano',
    'Ano passado',
    'Personalizado',
    'Tudo',
  ];

  @override
  void initState() {
    super.initState();
    // Configurar datas padrão (últimos 30 dias)
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));

    // Buscar transações iniciais
    _fetchTransactions();
  }

  // --- NOVO MÉTODO AUXILIAR PARA GERAR A QUERY STRING ---
  // Isso garante que o PDF e a Lista usem exatamente os mesmos filtros
  String _getQueryParams() {
    String query = '';

    // Adicionar filtro de data
    if (_selectedFilter == 'Personalizado' &&
        _startDate != null &&
        _endDate != null) {
      query += 'dataInicio=${_formatApiDate(_startDate!)}T00:00:00';
      query += '&dataFim=${_formatApiDate(_endDate!)}T23:59:59';
    } else if (_selectedFilter != 'Tudo') {
      // Aplicar filtro predefinido (exceto "Tudo")
      final filterDates = _getFilterDates(_selectedFilter);
      query += 'dataInicio=${_formatApiDate(filterDates.start)}T00:00:00';
      query += '&dataFim=${_formatApiDate(filterDates.end)}T23:59:59';
    }

    return query;
  }

  // Função para buscar transações com filtros
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Usa o método auxiliar criado acima
      String query = _getQueryParams();

      final endpoint =
          'conta/banco/transacao/filtros${query.isNotEmpty ? '?$query' : ''}';

      print('🔍 Endpoint chamado: $endpoint');

      final response = await ApiService.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> transactionsData = response['data'] ?? [];

        // Converter para o formato que precisamos
        List<Map<String, dynamic>> transactions = [];

        for (var tx in transactionsData) {
          transactions.add({
            'id': tx['id'],
            'contaOrigemId': tx['contaOrigemId'],
            'bancoOrigemNome': tx['bancoOrigemNome'],
            'bancoOrigemTitular': tx['bancoOrigemTitular'],
            'bancoOrigemChavePix': tx['bancoOrigemChavePix'],
            'contaDestinoId': tx['contaDestinoId'],
            'bancoDestinoNome': tx['bancoDestinoNome'],
            'bancoDestinoTitular': tx['bancoDestinoTitular'],
            'bancoDestinoChavePix': tx['bancoDestinoChavePix'],
            'valor': (tx['valor'] ?? 0.0).toDouble(),
            'descricao': tx['descricao'] ?? 'Transação',
            'dataTransacao': tx['dataTransacao'],
            'date': _parseDate(tx['dataTransacao']),
          });
        }

        // Ordenar por data (mais recente primeiro)
        transactions.sort((a, b) => b['date'].compareTo(a['date']));

        setState(() {
          _transactions = transactions;
        });
      } else {
        if (response['unauthorized'] == true) {
          await AuthService.logout();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          _showSnack(response['error'] ?? 'Erro ao carregar transações');
        }
      }
    } catch (e, stack) {
      print('🔥 Erro completo: $e');
      print('📋 Stack trace: $stack');
      _showSnack('Erro: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- NOVA LÓGICA PARA O BOTÃO DE DOWNLOAD ---
  Future<void> _handlePdfDownload() async {
    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      // 1. Obter Token (Necessário para o Back-end)
      final token = await AuthService.getToken();

      if (token == null) {
        _showSnack('Sessão expirada. Faça login novamente.');
        // Lógica de logout se necessário
        return;
      }

      // 2. Montar a URL completa com Filtros
      final query = _getQueryParams();

      // ATENÇÃO: Verifique se esta URL base está correta (sem barra duplicada)
      const baseUrl = "https://cedup-back-deploy.onrender.com";
      final fullUrl =
          "$baseUrl/conta/banco/transacao/filtros/pdf${query.isNotEmpty ? '?$query' : ''}";

      // 3. Gerar nome do arquivo
      final fileName =
          "extrato_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";

      // 4. Chamar o Service (Passando o Token)
      // Assumindo que você alterou o pdf service para aceitar parameter nomeado {String? token}
      await salvarPdfComSAF(fullUrl, fileName, token: token);
    } catch (e) {
      print("Erro download: $e");
      _showSnack("Erro ao iniciar download: $e");
    } finally {
      setState(() {
        _isDownloadingPdf = false;
      });
    }
  }

  // Funções auxiliares para datas
  DateTime _parseDate(String dateString) {
    try {
      // Formato: "03/12/2025 - 02:19"
      final parts = dateString.split(' - ');
      if (parts.length == 2) {
        final datePart = parts[0];
        final timePart = parts[1];
        final dateParts = datePart.split('/');
        final timeParts = timePart.split(':');

        if (dateParts.length == 3 && timeParts.length == 2) {
          return DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao parsear data: $dateString, erro: $e');
    }
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  ({DateTime start, DateTime end}) _getFilterDates(String filter) {
    final now = DateTime.now();

    switch (filter) {
      case 'Últimos 7 dias':
        return (start: now.subtract(const Duration(days: 7)), end: now);
      case 'Últimos 30 dias':
        return (start: now.subtract(const Duration(days: 30)), end: now);
      case 'Últimos 3 meses':
        return (start: now.subtract(const Duration(days: 90)), end: now);
      case 'Últimos 6 meses':
        return (start: now.subtract(const Duration(days: 180)), end: now);
      case 'Este ano':
        return (start: DateTime(now.year, 1, 1), end: now);
      case 'Ano passado':
        return (
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31, 23, 59, 59),
        );
      default:
        return (start: now.subtract(const Duration(days: 30)), end: now);
    }
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

  // Método para aplicar filtro predefinido
  void _applyPredefinedFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    if (filter == 'Personalizado') {
      return; // Aguardar o usuário selecionar datas manualmente
    }

    _fetchTransactions();
  }

  // Método para aplicar filtro personalizado
  void _applyCustomFilter() {
    if (_startDate == null || _endDate == null) {
      _showSnack('Selecione as datas de início e fim');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showSnack('A data final deve ser após a data inicial');
      return;
    }

    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Filtro predefinido
                DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Período',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _applyPredefinedFilter(value);
                    }
                  },
                ),

                // Datas personalizadas (mostrar apenas se selecionado "Personalizado")
                if (_selectedFilter == 'Personalizado') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Data Inicial',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _startDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(
                            text: _startDate != null
                                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                : '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Data Final',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _endDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(
                            text: _endDate != null
                                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                : '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _applyCustomFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Aplicar Filtro Personalizado'),
                  ),
                ],
              ],
            ),
          ),

          // Botão de imprimir/download PDF
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    // ALTERADO AQUI: Chama o método que monta a URL e o Token
                    onPressed: _isDownloadingPdf ? null : _handlePdfDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isDownloadingPdf
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.print),
                              SizedBox(width: 8),
                              Text(
                                'Imprimir/Download PDF',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Indicadores
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_transactions.length} transações',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (_selectedFilter == 'Personalizado' &&
                    _startDate != null &&
                    _endDate != null)
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                if (_selectedFilter != 'Personalizado')
                  Text(
                    _selectedFilter,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Lista de transações
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma transação encontrada',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == 'Tudo'
                              ? 'Não há transações registradas'
                              : 'Não há transações no período selecionado',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTransactions,
                          child: const Text('Atualizar'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchTransactions,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final valor = (transaction['valor'] ?? 0.0).toDouble();

                        // Lógica de visualização (cor positiva ou negativa)
                        // Ajuste conforme sua necessidade de negócio
                        final isPositive = valor >= 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Valor e Data
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'R\$${valor.abs().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isPositive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(transaction['date']),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Descrição
                                Text(
                                  transaction['descricao'] ?? 'Transação',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),

                                // Origem e Destino
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'De:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              transaction['bancoOrigemNome'] ??
                                                  'Banco',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              transaction['bancoOrigemTitular'] ??
                                                  '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Para:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              transaction['bancoDestinoNome'] ??
                                                  'Banco',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              transaction['bancoDestinoTitular'] ??
                                                  '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
