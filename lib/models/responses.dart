// ─── WMO Weather Code helpers ─────────────────────────────────────────────────

String wmoDescription(int code) {
  if (code == 0) return 'Ясно';
  if (code <= 2) return 'Малооблачно';
  if (code == 3) return 'Пасмурно';
  if (code <= 49) return 'Туман';
  if (code <= 57) return 'Морось';
  if (code <= 67) return 'Дождь';
  if (code <= 77) return 'Снег';
  if (code <= 82) return 'Ливень';
  if (code <= 86) return 'Снегопад';
  if (code <= 99) return 'Гроза';
  return 'Неизвестно';
}

String wmoIconCode(int code, {bool isDay = true}) {
  if (code == 0) return isDay ? 'clear_day' : 'clear_night';
  if (code <= 2) return isDay ? 'partly_cloudy_day' : 'partly_cloudy_night';
  if (code == 3) return 'cloudy';
  if (code <= 49) return 'fog';
  if (code <= 57) return 'drizzle';
  if (code <= 67) return 'rain';
  if (code <= 77) return 'snow';
  if (code <= 82) return 'rain';
  if (code <= 86) return 'snow';
  if (code <= 99) return 'thunderstorm';
  return 'cloudy';
}

// ─── Hourly Forecast ──────────────────────────────────────────────────────────

class HourlyForecast {
  final DateTime time;
  final double temp;
  final double apparentTemp;
  final int precipitationProbability;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;
  final bool isDay;

  HourlyForecast({
    required this.time,
    required this.temp,
    required this.apparentTemp,
    required this.precipitationProbability,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
    required this.isDay,
  });

  String get description => wmoDescription(weatherCode);
  String get iconCode => wmoIconCode(weatherCode, isDay: isDay);

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temp': temp,
        'apparent_temp': apparentTemp,
        'precip_prob': precipitationProbability,
        'precipitation': precipitation,
        'weather_code': weatherCode,
        'wind_speed': windSpeed,
        'is_day': isDay,
        'icon_code': iconCode,
        'description': description,
      };

  factory HourlyForecast.fromJson(Map<String, dynamic> j) => HourlyForecast(
        time: DateTime.parse(j['time'] as String),
        temp: (j['temp'] as num).toDouble(),
        apparentTemp: (j['apparent_temp'] as num).toDouble(),
        precipitationProbability: (j['precip_prob'] as num).toInt(),
        precipitation: (j['precipitation'] as num).toDouble(),
        weatherCode: (j['weather_code'] as num).toInt(),
        windSpeed: (j['wind_speed'] as num).toDouble(),
        isDay: j['is_day'] as bool,
      );
}

// ─── Daily Forecast ───────────────────────────────────────────────────────────

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final DateTime sunrise;
  final DateTime sunset;
  final double precipitationSum;
  final double windSpeedMax;

  DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.sunrise,
    required this.sunset,
    required this.precipitationSum,
    required this.windSpeedMax,
  });

  String get description => wmoDescription(weatherCode);
  String get iconCode => wmoIconCode(weatherCode, isDay: true);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weather_code': weatherCode,
        'temp_max': tempMax,
        'temp_min': tempMin,
        'sunrise': sunrise.toIso8601String(),
        'sunset': sunset.toIso8601String(),
        'precip_sum': precipitationSum,
        'wind_max': windSpeedMax,
        'icon_code': iconCode,
        'description': description,
      };

  factory DailyForecast.fromJson(Map<String, dynamic> j) => DailyForecast(
        date: DateTime.parse(j['date'] as String),
        weatherCode: (j['weather_code'] as num).toInt(),
        tempMax: (j['temp_max'] as num).toDouble(),
        tempMin: (j['temp_min'] as num).toDouble(),
        sunrise: DateTime.parse(j['sunrise'] as String),
        sunset: DateTime.parse(j['sunset'] as String),
        precipitationSum: (j['precip_sum'] as num).toDouble(),
        windSpeedMax: (j['wind_max'] as num).toDouble(),
      );
}

// ─── Weather ──────────────────────────────────────────────────────────────────

class WeatherResponse {
  final double temp;
  final double feelsLike;
  final int humidity;
  final int cloudiness;
  final double windSpeed;
  final double precipitation;
  final int weatherCode;
  final bool isDay;
  final int pressure;
  final DateTime sunrise;
  final DateTime sunset;
  final double tempMin;
  final double tempMax;
  final int timezoneOffsetSeconds;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  WeatherResponse({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.cloudiness,
    required this.windSpeed,
    required this.precipitation,
    required this.weatherCode,
    required this.isDay,
    required this.pressure,
    required this.sunrise,
    required this.sunset,
    required this.tempMin,
    required this.tempMax,
    required this.timezoneOffsetSeconds,
    required this.hourly,
    required this.daily,
  });

  String get description => wmoDescription(weatherCode);
  String get iconCode => wmoIconCode(weatherCode, isDay: isDay);

  Map<String, dynamic> toJson() => {
        'temp': temp,
        'feels_like': feelsLike,
        'humidity': humidity,
        'cloudiness': cloudiness,
        'wind_speed': windSpeed,
        'precipitation': precipitation,
        'weather_code': weatherCode,
        'is_day': isDay,
        'pressure': pressure,
        'sunrise': sunrise.toIso8601String(),
        'sunset': sunset.toIso8601String(),
        'temp_min': tempMin,
        'temp_max': tempMax,
        'timezone_offset_seconds': timezoneOffsetSeconds,
        'description': description,
        'icon': iconCode,
        'hourly': hourly.map((h) => h.toJson()).toList(),
        'daily': daily.map((d) => d.toJson()).toList(),
      };

  factory WeatherResponse.fromJson(Map<String, dynamic> j) => WeatherResponse(
        temp: (j['temp'] as num).toDouble(),
        feelsLike: (j['feels_like'] as num).toDouble(),
        humidity: (j['humidity'] as num).toInt(),
        cloudiness: (j['cloudiness'] as num).toInt(),
        windSpeed: (j['wind_speed'] as num).toDouble(),
        precipitation: (j['precipitation'] as num? ?? 0).toDouble(),
        weatherCode: (j['weather_code'] as num? ?? 0).toInt(),
        isDay: j['is_day'] as bool? ?? true,
        pressure: (j['pressure'] as num? ?? 1013).toInt(),
        sunrise: DateTime.parse(j['sunrise'] as String),
        sunset: DateTime.parse(j['sunset'] as String),
        tempMin: (j['temp_min'] as num? ?? j['temp'] as num).toDouble(),
        tempMax: (j['temp_max'] as num? ?? j['temp'] as num).toDouble(),
        timezoneOffsetSeconds: (j['timezone_offset_seconds'] as num? ?? 0).toInt(),
        hourly: (j['hourly'] as List? ?? [])
            .map((e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
            .toList(),
        daily: (j['daily'] as List? ?? [])
            .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory WeatherResponse.fromOpenMeteoJson(Map<String, dynamic> j) {
    final current = j['current'] as Map<String, dynamic>;
    final hourlyData = j['hourly'] as Map<String, dynamic>;
    final dailyData = j['daily'] as Map<String, dynamic>;
    final utcOffsetSeconds = (j['utc_offset_seconds'] as num).toInt();

    final weatherCode = (current['weather_code'] as num).toInt();
    final isDay = (current['is_day'] as num).toInt() == 1;

    final tempMax = (dailyData['temperature_2m_max'] as List).first as num;
    final tempMin = (dailyData['temperature_2m_min'] as List).first as num;
    final sunrise = DateTime.parse((dailyData['sunrise'] as List).first as String);
    final sunset = DateTime.parse((dailyData['sunset'] as List).first as String);

    // ─── Hourly — ближайшие 48 часов ────────────────────────────────────────
    final times = hourlyData['time'] as List;
    final hourlyTemps = hourlyData['temperature_2m'] as List;
    final hourlyApparent = hourlyData['apparent_temperature'] as List;
    final hourlyPrecipProb = hourlyData['precipitation_probability'] as List;
    final hourlyPrecip = hourlyData['precipitation'] as List;
    final hourlyCodes = hourlyData['weather_code'] as List;
    final hourlyWind = hourlyData['wind_speed_10m'] as List;
    final hourlyIsDay = hourlyData['is_day'] as List;

    final now = DateTime.now();
    final hourlyForecasts = <HourlyForecast>[];

    for (int i = 0; i < times.length && hourlyForecasts.length < 48; i++) {
      final t = DateTime.parse(times[i] as String);
      if (t.isBefore(now.subtract(const Duration(hours: 1)))) continue;
      hourlyForecasts.add(HourlyForecast(
        time: t,
        temp: (hourlyTemps[i] as num).toDouble(),
        apparentTemp: (hourlyApparent[i] as num).toDouble(),
        precipitationProbability: (hourlyPrecipProb[i] as num? ?? 0).toInt(),
        precipitation: (hourlyPrecip[i] as num? ?? 0).toDouble(),
        weatherCode: (hourlyCodes[i] as num).toInt(),
        windSpeed: (hourlyWind[i] as num).toDouble(),
        isDay: (hourlyIsDay[i] as num).toInt() == 1,
      ));
    }

    // ─── Daily ───────────────────────────────────────────────────────────────
    final dailyTimes = dailyData['time'] as List;
    final dailyCodes = dailyData['weather_code'] as List;
    final dailyMax = dailyData['temperature_2m_max'] as List;
    final dailyMin = dailyData['temperature_2m_min'] as List;
    final dailySunrise = dailyData['sunrise'] as List;
    final dailySunset = dailyData['sunset'] as List;
    final dailyPrecip = dailyData['precipitation_sum'] as List;
    final dailyWind = dailyData['wind_speed_10m_max'] as List;

    final dailyForecasts = <DailyForecast>[];
    for (int i = 0; i < dailyTimes.length; i++) {
      dailyForecasts.add(DailyForecast(
        date: DateTime.parse(dailyTimes[i] as String),
        weatherCode: (dailyCodes[i] as num).toInt(),
        tempMax: (dailyMax[i] as num).toDouble(),
        tempMin: (dailyMin[i] as num).toDouble(),
        sunrise: DateTime.parse(dailySunrise[i] as String),
        sunset: DateTime.parse(dailySunset[i] as String),
        precipitationSum: (dailyPrecip[i] as num? ?? 0).toDouble(),
        windSpeedMax: (dailyWind[i] as num).toDouble(),
      ));
    }

    return WeatherResponse(
      temp: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      cloudiness: (current['cloud_cover'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num? ?? 0).toDouble(),
      weatherCode: weatherCode,
      isDay: isDay,
      pressure: (current['surface_pressure'] as num).toInt(),
      sunrise: sunrise,
      sunset: sunset,
      tempMin: tempMin.toDouble(),
      tempMax: tempMax.toDouble(),
      timezoneOffsetSeconds: utcOffsetSeconds,
      hourly: hourlyForecasts,
      daily: dailyForecasts,
    );
  }
}

// ─── Mood ─────────────────────────────────────────────────────────────────────

class MoodResponse {
  final double energy;
  final double valence;

  MoodResponse({required this.energy, required this.valence});

  Map<String, dynamic> toJson() => {'energy': energy, 'valence': valence};

  factory MoodResponse.fromJson(Map<String, dynamic> j) => MoodResponse(
        energy: (j['energy'] as num).toDouble(),
        valence: (j['valence'] as num).toDouble(),
      );
}

// ─── Track ────────────────────────────────────────────────────────────────────

class TrackResponse {
  final int id;
  final String title;
  final String artist;
  final String? previewUrl;
  final String? albumCoverUrl;
  final String externalUrl;
  final int durationSeconds;

  TrackResponse({
    required this.id,
    required this.title,
    required this.artist,
    this.previewUrl,
    this.albumCoverUrl,
    required this.externalUrl,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'preview_url': previewUrl,
        'album_cover_url': albumCoverUrl,
        'external_url': externalUrl,
        'duration_seconds': durationSeconds,
      };

  factory TrackResponse.fromDeezerJson(Map<String, dynamic> j) {
    final album = j['album'] as Map<String, dynamic>?;
    final artist = j['artist'] as Map<String, dynamic>?;
    return TrackResponse(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String,
      artist: artist?['name'] as String? ?? '',
      previewUrl: j['preview'] as String?,
      albumCoverUrl: album?['cover_medium'] as String?,
      externalUrl:
          j['link'] as String? ?? 'https://www.deezer.com/track/${j['id']}',
      durationSeconds: (j['duration'] as num?)?.toInt() ?? 0,
    );
  }
}