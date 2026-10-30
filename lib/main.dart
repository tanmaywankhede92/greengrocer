import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.warmUpServer();
  runApp(const ProviderScope(child: GreengrocerApp()));
}
