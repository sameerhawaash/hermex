import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/config/env.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  final client = Supabase.instance.client;

  try {
    final res = await client.from('shipments').select().limit(1);
    print('DATA: $res');
  } catch (e) {
    print('ERROR: $e');
  }
}
