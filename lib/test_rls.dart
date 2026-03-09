import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(
    fileName:
        "e:/Antigrafity projects/New Gimni/tayarakanti v 1/tayarak_app/.env",
  );
  // ignore: avoid_print
  print("Anon Key: ${dotenv.env['SUPABASE_ANON_KEY']}");
}
