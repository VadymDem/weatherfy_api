import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weatherfy_api/config/env.dart';
import 'package:weatherfy_api/models/responses.dart';

class WeatherService {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherResponse> getWeather(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/weather').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'appid': Env.weatherApiKey,
      'units': 'metric',
      'lang': 'ru',
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('OpenWeatherMap error [${response.statusCode}]: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherResponse.fromOwmJson(json);
  }
}