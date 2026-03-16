import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:weatherfy_api/models/responses.dart';

class MoodService {
  final String _assetsPath;

  MoodService({String? assetsPath})
      : _assetsPath = assetsPath ?? _resolveAssetsPath() {
    print('⚡️ MoodService initialized. Path: $_assetsPath');
  }

  static String _resolveAssetsPath() {
    try {
      final scriptDir = path.dirname(Platform.script.toFilePath());
      // Проверяем несколько вариантов расположения assets (Docker vs Local)
      final candidates = [
        path.join(Directory.current.path, 'assets', 'config', 'mood'),
        path.join(scriptDir, '..', 'assets', 'config', 'mood'),
        path.join(scriptDir, 'assets', 'config', 'mood'),
      ];

      for (final candidate in candidates) {
        final normalized = path.normalize(candidate);
        if (Directory(normalized).existsSync()) {
          return normalized;
        }
      }
      throw Exception('Assets directory not found in: $candidates');
    } catch (e) {
      print('❌ Error resolving path: $e');
      // fallback на текущую директорию
      return path.join(Directory.current.path, 'assets', 'config', 'mood');
    }
  }

  Future<MoodResponse> calculateMood({
    required WeatherResponse weather,
    required double latitude,
    required String climateZone,
  }) async {
    try {
      // 1. Загрузка конфигов
      final baseConfig = await _loadJson('base.json');
      
      // Нормализуем имя зоны: "Temperate North" -> "temperate_north.json"
      final normalizedZone = climateZone.toLowerCase().trim().replaceAll(' ', '_');
      final zoneConfig = await _loadJson('zones/$normalizedZone.json');

      // 2. Начальные значения
      double energy = _toDouble(baseConfig['initial']?['energy'] ?? 0.5);
      double valence = _toDouble(baseConfig['initial']?['valence'] ?? 0.5);

      final factors = baseConfig['factors'] as Map<String, dynamic>? ?? {};
      final sensitivity = zoneConfig['zone_sensitivity'] as Map<String, dynamic>? ?? {};

      // --- РАСЧЕТ ФАКТОРОВ ---

      // 1️⃣ Температура
      final tempCategory = _getTemperatureCategory(weather.temp, zoneConfig);
      final tempWeights = (factors['temperature'] as Map<String, dynamic>?)?[tempCategory];
      
      if (tempWeights != null) {
        final weightMap = tempWeights as Map<String, dynamic>;
        final zoneFactor = _toDouble(sensitivity['temperature']?[tempCategory] ?? 1.0);
        
        // Плавный расчет отклонения внутри диапазона (если есть данные)
        final ranges = zoneConfig['temperature_ranges'] as Map<String, dynamic>?;
        double intensity = 1.0;
        if (ranges != null && ranges.containsKey(tempCategory)) {
          final r = ranges[tempCategory] as List;
          final mid = (_toDouble(r[0]) + _toDouble(r[1])) / 2;
          final span = (_toDouble(r[1]) - _toDouble(r[0])) / 2;
          if (span > 0) intensity = 1.0 - ((weather.temp - mid).abs() / span).clamp(0.0, 0.5);
        }

        energy += _toDouble(weightMap['energy']) * zoneFactor * intensity;
        valence += _toDouble(weightMap['valence']) * zoneFactor * intensity;
      }

      // 2️⃣ Облачность
      final cloudFactor = (weather.cloudiness / 100.0).clamp(0.0, 1.0);
      final cloudWeights = factors['cloudiness']?['overcast'] as Map<String, dynamic>?;
      if (cloudWeights != null) {
        energy += cloudFactor * _toDouble(cloudWeights['energy']);
        valence += cloudFactor * _toDouble(cloudWeights['valence']);
      }

      // 3️⃣ Осадки
      final precipType = _getPrecipitationType(weather.description, weather.weatherCode);
      final precipWeights = (factors['precipitation'] as Map<String, dynamic>?)?[precipType] as Map<String, dynamic>?;
      
      if (precipWeights != null) {
        final zoneFactor = _toDouble(sensitivity['precipitation']?[precipType] ?? 1.0);
        // Ветер усиливает неприятность осадков
        final windImpact = 1.0 + (weather.windSpeed / 15.0).clamp(0.0, 0.5);
        
        energy += _toDouble(precipWeights['energy']) * zoneFactor * windImpact;
        valence += _toDouble(precipWeights['valence']) * zoneFactor * windImpact;
      }

      // 4️⃣ Ветер
      final windWeightsMap = factors['wind'] as Map<String, dynamic>?;
      if (windWeightsMap != null) {
        final ws = weather.windSpeed;
        String windCat = ws < 3 ? 'calm' : ws < 8 ? 'breezy' : ws < 15 ? 'windy' : 'storm';
        final w = windWeightsMap[windCat] as Map<String, dynamic>?;
        if (w != null) {
          energy += _toDouble(w['energy']);
          valence += _toDouble(w['valence']);
        }
      }

      // 5️⃣ Время суток (биоритм)
      final now = DateTime.now().toUtc();
      // Учитываем смещение часового пояса города
      final localNow = now.add(Duration(seconds: weather.timezoneOffsetSeconds));
      final dayProgress = _getDayProgress(localNow, weather.sunrise, weather.sunset);
      
      // Пик энергии днем (синусоида)
      energy += 0.15 * math.sin(dayProgress * math.pi);
      valence += 0.10 * math.sin(dayProgress * math.pi);

      // 6. Финальная нормализация
      energy = energy.clamp(0.0, 1.0);
      valence = valence.clamp(0.0, 1.0);

      print('✅ Mood for $climateZone: E:${energy.toStringAsFixed(2)} V:${valence.toStringAsFixed(2)}');
      return MoodResponse(energy: energy, valence: valence);

    } catch (e, stack) {
      print('❌ Critical error in calculateMood: $e');
      print(stack);
      // Возвращаем нейтральное состояние вместо 500 ошибки, если что-то пошло не так
      return MoodResponse(energy: 0.5, valence: 0.5);
    }
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ---

  Future<Map<String, dynamic>> _loadJson(String relativePath) async {
    final fullPath = path.normalize(path.join(_assetsPath, relativePath));
    final file = File(fullPath);

    if (!await file.exists()) {
      print('⚠️ File missing: $fullPath. Using empty config.');
      return {};
    }

    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return 0.0;
  }

  static String _getPrecipitationType(String desc, int code) {
    // Приоритет по WMO кодам
    if (code >= 95) return 'heavy_rain'; // гроза
    if (code >= 71 && code <= 77) return 'light_snow';
    if (code >= 85) return 'heavy_snow';
    if (code >= 51 && code <= 67) return 'light_rain';
    
    final d = desc.toLowerCase();
    if (d.contains('дождь') || d.contains('rain')) return 'light_rain';
    if (d.contains('снег') || d.contains('snow')) return 'light_snow';
    return 'none';
  }

  static String _getTemperatureCategory(double temp, Map<String, dynamic> zoneConfig) {
    final ranges = zoneConfig['temperature_ranges'] as Map<String, dynamic>?;
    if (ranges != null) {
      for (final entry in ranges.entries) {
        final r = entry.value as List;
        if (temp >= _toDouble(r[0]) && temp < _toDouble(r[1])) return entry.key;
      }
    }
    // Fallback значения, синхронизированные с base.json
    if (temp < -10) return 'freezing';
    if (temp < 5) return 'cold';
    if (temp < 15) return 'cool';
    if (temp < 25) return 'comfortable'; // Важно: в твоем JSON именно 'comfortable'
    if (temp < 35) return 'warm';
    return 'very_hot';
  }

  static double _getDayProgress(DateTime now, DateTime sunrise, DateTime sunset) {
    if (now.isBefore(sunrise) || now.isAfter(sunset)) return 0.0;
    final total = sunset.difference(sunrise).inSeconds;
    if (total <= 0) return 0.5;
    return now.difference(sunrise).inSeconds / total;
  }
}