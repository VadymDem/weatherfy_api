import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weatherfy_api/models/responses.dart';

class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherResponse> getWeather(double lat, double lon) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'surface_pressure',
        'wind_speed_10m',
        'cloud_cover',
        'precipitation',
        'weather_code',
        'is_day',
      ].join(','),
      'hourly': [
        'temperature_2m',
        'apparent_temperature',
        'precipitation_probability',
        'precipitation',
        'weather_code',
        'wind_speed_10m',
        'is_day',
      ].join(','),
      'daily': [
        'weather_code',
        'temperature_2m_max',
        'temperature_2m_min',
        'sunrise',
        'sunset',
        'precipitation_sum',
        'wind_speed_10m_max',
      ].join(','),
      'forecast_days': '7',
      'timezone': 'auto',
      'wind_speed_unit': 'ms',
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Open-Meteo error [${response.statusCode}]: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherResponse.fromOpenMeteoJson(json);
  }
}