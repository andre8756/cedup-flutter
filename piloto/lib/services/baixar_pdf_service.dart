import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

Future<void> salvarPdfComSAF(
  String urlPdf,
  String nomeArquivo, {
  String? token,
}) async {
  try {
    final dio = Dio();

    // ADICIONADO: Configura o Header com o Token se ele existir
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    // 1. Baixa o PDF
    print("Baixando PDF de: $urlPdf");

    final response = await dio.get(
      urlPdf,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200) {
      print("ERRO HTTP: ${response.statusCode}");
      return;
    }

    final bytes = Uint8List.fromList(response.data);

    if (bytes.isEmpty) {
      print("ERRO: A API não enviou bytes.");
      return;
    }

    // 2. Validar se é realmente PDF
    final header = String.fromCharCodes(bytes.take(4));
    if (!header.startsWith('%PDF')) {
      print("ERRO: O arquivo não é PDF! Cabeçalho recebido: $header");
      return;
    }

    print("PDF recebido com ${bytes.length} bytes.");

    // 3. Salvar via SAF
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar Extrato',
      fileName: nomeArquivo,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );

    if (savePath == null) {
      print("Usuário cancelou o salvamento.");
      return;
    }

    print("PDF salvo com sucesso em: $savePath");
  } catch (e) {
    print("Erro ao salvar PDF: $e");
    rethrow; // Repassa o erro para ser tratado na tela
  }
}
