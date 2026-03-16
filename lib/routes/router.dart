import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:weatherfy_api/models/responses.dart';
import 'package:weatherfy_api/services/weather_service.dart';
import 'package:weatherfy_api/services/mood_service.dart';
import 'package:weatherfy_api/services/deezer_service.dart';

final _weatherService = WeatherService();
final _moodService = MoodService();
final _deezerService = DeezerService();

Router buildRouter() {
  final router = Router();

  // ── GET /weather?lat=&lon= ────────────────────────────────────────────────
  router.get('/weather', (Request request) async {
    final params = request.url.queryParameters;
    final lat = double.tryParse(params['lat'] ?? '');
    final lon = double.tryParse(params['lon'] ?? '');

    if (lat == null || lon == null) {
      return _badRequest('lat and lon are required');
    }

    try {
      final weather = await _weatherService.getWeather(lat, lon);
      return _ok(weather.toJson());
    } catch (e) {
      return _serverError(e.toString());
    }
  });

  // ── POST /mood ────────────────────────────────────────────────────────────
  // Body: { weather: {...}, latitude: 0.0, climate_zone: "temperate_north" }
  router.post('/mood', (Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final weatherJson = body['weather'] as Map<String, dynamic>?;
      final latitude = (body['latitude'] as num?)?.toDouble();
      final climateZone = body['climate_zone'] as String?;

      if (weatherJson == null || latitude == null || climateZone == null) {
        return _badRequest('weather, latitude and climate_zone are required');
      }

      final weather = WeatherResponse.fromJson(weatherJson);
      final mood = await _moodService.calculateMood(
        weather: weather,
        latitude: latitude,
        climateZone: climateZone,
      );
      return _ok(mood.toJson());
    } catch (e, stack) {
      print('❌ /mood error: $e\n$stack');
      return _serverError(e.toString());
    }
  });
  router.get('/music', (Request request) async {
    final params = request.url.queryParameters;
    final energy = double.tryParse(params['energy'] ?? '');
    final valence = double.tryParse(params['valence'] ?? '');
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;

    if (energy == null || valence == null) {
      return _badRequest('energy and valence are required');
    }

    try {
      final tracks = await _deezerService.getRecommendations(
        energy: energy,
        valence: valence,
        limit: limit,
      );
      return _ok({'tracks': tracks.map((t) => t.toJson()).toList()});
    } catch (e) {
      return _serverError(e.toString());
    }
  });

  // ── GET /health ───────────────────────────────────────────────────────────
  router.get('/health', (Request _) => _ok({'status': 'ok'}));

  return router;
}

Response _ok(Map<String, dynamic> body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response _badRequest(String message) => Response(
      400,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

Response _serverError(String message) => Response(
      500,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );