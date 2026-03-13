import 'package:dotenv/dotenv.dart';

class Env {
  static late final DotEnv _env;

  static void load() {
    _env = DotEnv(includePlatformEnvironment: true)..load();
  }

  static String get weatherApiKey =>
      _env['OPENWEATHER_API_KEY'] ?? (throw Exception('OPENWEATHER_API_KEY not set'));

  static int get port => int.tryParse(_env['PORT'] ?? '8080') ?? 8080;
}