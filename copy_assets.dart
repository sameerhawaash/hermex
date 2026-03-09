import 'dart:io';

void main() {
  final mappings = {
    'C:/Users/hp/.gemini/antigravity/brain/bf80a4e8-8dfd-4df0-8337-ccf21ab4cd4d/media__1772084044177.png':
        'e:/Antigrafity projects/New Gimni/tayarakanti v 1/tayarak_app/assets/images/hero.png',
    'C:/Users/hp/.gemini/antigravity/brain/bf80a4e8-8dfd-4df0-8337-ccf21ab4cd4d/media__1772086210190.png':
        'e:/Antigrafity projects/New Gimni/tayarakanti v 1/tayarak_app/assets/images/logo.png',
    'C:/Users/hp/.gemini/antigravity/brain/bf80a4e8-8dfd-4df0-8337-ccf21ab4cd4d/media__1772084050939.png':
        'e:/Antigrafity projects/New Gimni/tayarakanti v 1/tayarak_app/assets/images/home.png',
  };

  for (final entry in mappings.entries) {
    final source = File(entry.key);
    final target = File(entry.value);
    if (source.existsSync()) {
      source.copySync(target.path);
      print('Copied: ${entry.key} -> ${entry.value}');
    } else {
      print('Source not found: ${entry.key}');
    }
  }
}
