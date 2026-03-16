import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:weatherfy_api/models/responses.dart';

class MoodService {
  final String _assetsPath;

  MoodService({String? assetsPath})
      : _assetsPath = assetsPath ?? _resolveAssetsPath();

  // 🔧 Находим правильный путь к assets
  static String _resolveAssetsPath() {
    // Вариант 1: Относительно текущего скрипта (server.dart)
    try {
      final scriptDir = path.dirname(Platform.script.toFilePath());
      final candidate = path.join(scriptDir, '..', '..', 'assets', 'config', 'mood');
      final normalized = path.normalize(candidate);
      
      if (Directory(normalized).existsSync()) {
        print('✅ Assets found at: $normalized');
        return normalized;
      }
    } catch (_) {}

    // Вариант 2: Относительно текущей рабочей директории
    final fromCwd = path.join(Directory.current.path, 'assets', 'config', 'mood');
    if (Directory(fromCwd).existsSync()) {
      print('✅ Assets found at: $fromCwd');
      return fromCwd;
    }

    // Вариант 3: Абсолютный путь (для отладки)
    throw Exception(
      'Не удалось найти папку assets/config/mood!\n'
      'Current directory: ${Directory.current.path}\n'
      'Script location: ${Platform.script.toFilePath()}\n'
      'Проверьте, что файлы существуют в проекте.',
    );
  }

  Future<MoodResponse> calculateMood({
    required WeatherResponse weather,
    required double latitude,
    required String climateZone,
  }) async {
    print(' Calculating mood for zone: $climateZone');
    print('📁 Assets path: $_assetsPath');

    try {
      final baseConfig = await _loadJson('base.json');
      print('✅ base.json loaded');

      final zoneFileName = '$climateZone.json';
      final zoneConfig = await _loadJson('zones/$zoneFileName');
      print('✅ zones/$zoneFileName loaded');

      double energy = _toDouble(baseConfig['initial']?['energy'] ?? 0.5);
      double valence = _toDouble(baseConfig['initial']?['valence'] ?? 0.5);

      final sensitivity = zoneConfig['zone_sensitivity'] ?? {};

      // 1️⃣ Температура
      final tempCategory = _getTemperatureCategory(weather.temp, zoneConfig);
      final tempRanges = zoneConfig['temperature_ranges'] as Map<String, dynamic>?;
      if (tempRanges != null && tempRanges.containsKey(tempCategory)) {
        final tempRange = tempRanges[tempCategory] as List<dynamic>?;
        if (tempRange != null && tempRange.length >= 2) {
          final mid = (_toDouble(tempRange[0]) + _toDouble(tempRange[1])) / 2;
          final span = (_toDouble(tempRange[1]) - _toDouble(tempRange[0])) / 2;
          final tempFactor = span > 0 ? ((weather.temp - mid).abs()) / span : 0.0;
          final tempWeights = (baseConfig['factors']?['temperature']
              as Map<String, dynamic>?)?[tempCategory] as Map<String, dynamic>?;
          if (tempWeights != null) {
            final factor = _toDouble(sensitivity['temperature']?[tempCategory] ?? 1.0);
            energy += _toDouble(tempWeights['energy'] ?? 0.0) * tempFactor * factor;
            valence += _toDouble(tempWeights['valence'] ?? 0.0) * tempFactor * factor;
          }
        }
      }

      // 2️⃣ Облачность
      final cloudFactor = weather.cloudiness / 100.0;
      final cloudWeights = baseConfig['factors']?['cloudiness'] as Map<String, dynamic>?;
      if (cloudWeights != null) {
        energy += cloudFactor * _toDouble(cloudWeights['overcast']?['energy'] ?? 0.0);
        valence += cloudFactor * _toDouble(cloudWeights['overcast']?['valence'] ?? 0.0);
      }

      // 3️⃣ Осадки
      final precipType = _getPrecipitationType(weather.description);
      final precipWeights = (baseConfig['factors']?['precipitation']
          as Map<String, dynamic>?)?[precipType] as Map<String, dynamic>?;
      final precipFactor = _toDouble(sensitivity['precipitation']?[precipType] ?? 1.0);
      if (precipWeights != null) {
        final combinedFactor = 1 + (weather.windSpeed / 10);
        energy += _toDouble(precipWeights['energy'] ?? 0.0) * precipFactor * combinedFactor;
        valence += _toDouble(precipWeights['valence'] ?? 0.0) * precipFactor * combinedFactor;
      }

      // 4️⃣ Ветер
      final windWeights = baseConfig['factors']?['wind'] as Map<String, dynamic>?;
      if (windWeights != null) {
        final ws = weather.windSpeed;
        final windEnergy = ws < 3
            ? _toDouble(windWeights['calm']?['energy'] ?? 0.0)
            : ws < 7
                ? _toDouble(windWeights['breezy']?['energy'] ?? 0.0) * (ws / 7)
                : ws < 12
                    ? _toDouble(windWeights['windy']?['energy'] ?? 0.0) * (ws / 12)
                    : _toDouble(windWeights['storm']?['energy'] ?? 0.0);
        final windValence = ws < 3
            ? _toDouble(windWeights['calm']?['valence'] ?? 0.0)
            : ws < 7
                ? _toDouble(windWeights['breezy']?['valence'] ?? 0.0) * (ws / 7)
                : ws < 12
                    ? _toDouble(windWeights['windy']?['valence'] ?? 0.0) * (ws / 12)
                    : _toDouble(windWeights['storm']?['valence'] ?? 0.0);
        energy += windEnergy;
        valence += windValence;
      }

      // 5️⃣ Время суток
      final now = DateTime.now().toUtc();
      final dayProgress = _getDayProgress(now, weather.sunrise, weather.sunset);
      energy += 0.2 * math.sin(dayProgress * math.pi);
      valence += 0.15 * math.sin(dayProgress * math.pi);

      // 6️⃣ Сезонное отклонение
      final season = _getSeason(now, latitude);
      final seasonalNorm =
          zoneConfig['norms']?['temperature']?[season] as Map<String, dynamic>?;
      if (seasonalNorm != null) {
        final normTemp = _toDouble(seasonalNorm['expected'] ?? weather.temp);
        final tolerance = _toDouble(seasonalNorm['tolerance'] ?? 10.0);
        if (tolerance > 0) {
          final delta = (weather.temp - normTemp) / tolerance;
          final clamped = math.min(math.max(delta, -1.0), 1.0);
          final deltaFactor = math.pow(clamped.abs(), 1.5).toDouble();
          energy += deltaFactor * 0.1;
          valence += clamped > 0 ? deltaFactor * 0.05 : -deltaFactor * 0.15;
        }
      }

      // 7️⃣ Нормализация
      energy = math.min(math.max(energy, 0.0), 1.0);
      valence = math.min(math.max(valence, 0.0), 1.0);

      print('✅ Mood calculated: energy=${energy.toStringAsFixed(2)}, valence=${valence.toStringAsFixed(2)}');
      return MoodResponse(energy: energy, valence: valence);
      
    } catch (e, stack) {
      print('❌ Error in calculateMood: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadJson(String relativePath) async {
    final fullPath = path.join(_assetsPath, relativePath);
    final file = File(fullPath);
    
    print('📄 Loading: $fullPath');
    
    if (!file.existsSync()) {
      final availableFiles = Directory(_assetsPath).listSync(recursive: true);
      print('❌ File not found: $fullPath');
      print('📁 Available files in $_assetsPath:');
      for (final f in availableFiles) {
        print('   - ${f.path}');
      }
      throw Exception('Config not found: $relativePath\nResolved path: $fullPath');
    }
    
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      print('✅ Successfully loaded: $relativePath');
      return json;
    } catch (e) {
      print('❌ Error parsing JSON: $fullPath');
      print('Error: $e');
      rethrow;
    }
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return 0.0;
  }

  static String _getPrecipitationType(String description) {
    final d = description.toLowerCase();
    if (d.contains('дождь') || d.contains('ливень') || d.contains('морось')) return 'light_rain';
    if (d.contains('снег')) return 'light_snow';
    return 'none';
  }

  static String _getTemperatureCategory(double temp, Map<String, dynamic> zoneConfig) {
    final ranges = zoneConfig['temperature_ranges'] as Map<String, dynamic>?;
    if (ranges == null || ranges.isEmpty) {
      if (temp < -10) return 'freezing';
      if (temp < 5) return 'cold';
      if (temp < 15) return 'cool';
      if (temp < 25) return 'mild';
      if (temp < 35) return 'warm';
      return 'very_hot';
    }
    for (final entry in ranges.entries) {
      final range = entry.value;
      if (range is List && range.length >= 2) {
        if (temp >= _toDouble(range[0]) && temp < _toDouble(range[1])) return entry.key;
      }
    }
    return 'very_hot';
  }

  static double _getDayProgress(DateTime now, DateTime sunrise, DateTime sunset) {
    final adjustedSunset =
        sunset.isBefore(sunrise) ? sunset.add(const Duration(days: 1)) : sunset;
    if (now.isBefore(sunrise)) return 0.0;
    if (now.isAfter(adjustedSunset)) return 1.0;
    final total = adjustedSunset.difference(sunrise).inSeconds.toDouble();
    if (total <= 0) return 0.5;
    return now.difference(sunrise).inSeconds.toDouble() / total;
  }

  static String _getSeason(DateTime date, double latitude) {
    final m = date.month;
    final north = latitude >= 0;
    if (north) {
      if (m == 12 || m <= 2) return 'winter';
      if (m <= 5) return 'spring';
      if (m <= 8) return 'summer';
      return 'autumn';
    } else {
      if (m == 12 || m <= 2) return 'summer';
      if (m <= 5) return 'autumn';
      if (m <= 8) return 'winter';
      return 'spring';
    }
  }
}