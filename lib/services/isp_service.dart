import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class IspService {
  /// Fetches ISP information from ipwhois.app
  /// Returns a map with 'name' and 'type' keys if successful, or null if it fails.
  Future<Map<String, String>?> fetchISPInfo() async {
    try {
      final response = await http.get(Uri.parse('https://ipwhois.app/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'name': data['isp'] ?? 'Unknown ISP',
            'type': data['type'] ?? 'Broadband',
          };
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch ISP: $e");
    }
    return null;
  }
}
