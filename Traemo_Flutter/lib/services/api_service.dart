import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = "http://192.168.18.23:8000/api";
  // NOTE:
  // emulator → pakai 10.0.2.2
  // HP asli → pakai IP laptop (contoh: 192.168.x.x)

  static Future<Map<String, dynamic>> sendMessage(
    String message,
    int userId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "message": message,
        "user_id": userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send message");
    }
  }

  static Future<List<dynamic>> getTransactions(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/transactions?user_id=$userId"),
      headers: {
        "Accept": "application/json",
      },
    );

    developer.log(
      "TRANSACTION RESPONSE: ${response.body}",
      name: 'ApiService.getTransactions',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      throw Exception("Invalid transaction response");
    } else {
      throw Exception("Failed to load transactions");
    }
  }

  static Future<String> exportTransactionsToExcel(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/transactions/export/excel"),
      headers: {
        "Accept":
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final fileName = _extractDownloadFileName(response.headers) ??
          _buildExportFileName(DateTime.now());
      final directory = await _resolveDownloadDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      try {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file.path;
      } on FileSystemException {
        final fallbackDirectory = await _resolveFallbackDirectory();
        final fallbackFile = File(
          '${fallbackDirectory.path}${Platform.pathSeparator}$fileName',
        );
        await fallbackFile.writeAsBytes(response.bodyBytes, flush: true);
        return fallbackFile.path;
      }
    }

    String message = "Gagal export transaksi";
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded["message"] is String &&
          (decoded["message"] as String).isNotEmpty) {
        message = decoded["message"] as String;
      }
    } on FormatException {
      if (response.statusCode == 401) {
        message = "Sesi login berakhir. Silakan login ulang.";
      }
    }

    throw ApiException(message);
  }

  static String _buildExportFileName(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'traemo_transactions_${year}_${month}_$day.xlsx';
  }

  static String? _extractDownloadFileName(Map<String, String> headers) {
    final disposition = headers['content-disposition'];
    if (disposition == null || disposition.isEmpty) return null;

    final fileNameMatch = RegExp("filename\\*?=(?:UTF-8'')?\"?([^\";]+)\"?")
        .firstMatch(disposition);
    return fileNameMatch?.group(1);
  }

  static Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        return downloads;
      }
    }

    return _resolveFallbackDirectory();
  }

  static Future<Directory> _resolveFallbackDirectory() async {
    final fallback = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}Traemo',
    );
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  static Future<Map<String, dynamic>> getDashboardSummary(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/dashboard-summary?user_id=$userId"),
      headers: {
        "Accept": "application/json",
      },
    );

    developer.log(
      "DASHBOARD RESPONSE: ${response.body}",
      name: 'ApiService.getDashboardSummary',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid dashboard response");
    } else {
      throw Exception("Failed to load dashboard data");
    }
  }

  static Future<List<dynamic>> getChats(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/chats?user_id=$userId"),
      headers: {
        "Accept": "application/json",
      },
    );

    developer.log("CHAT RESPONSE: ${response.body}",
        name: 'ApiService.getChats');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      throw Exception("Invalid chat response");
    } else {
      throw Exception("Failed to load chats");
    }
  }

  static Future<Map<String, dynamic>> clearChats(int userId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/chats/clear?user_id=$userId"),
      headers: {
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid clear chat response");
    } else {
      throw Exception("Failed to clear chats");
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    developer.log("RAW RESPONSE: ${response.body}", name: 'ApiService.login');

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        throw const ApiException("Server error");
      }
    } on FormatException {
      if (response.statusCode == 200) {
        throw const ApiException("Invalid response from server");
      }
      throw const ApiException("Server error");
    }

    if (response.statusCode == 200) {
      return data;
    }

    final message = data["message"];
    if (message is String && message.isNotEmpty) {
      throw ApiException(message);
    }

    throw ApiException("Request failed with status ${response.statusCode}");
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        throw const ApiException("Server error");
      }
    } on FormatException {
      throw const ApiException("Invalid response from server");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data["message"];
    if (message is String && message.isNotEmpty) {
      throw ApiException(message);
    }

    throw ApiException("Request failed with status ${response.statusCode}");
  }
}
