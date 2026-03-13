// ─── Weather ──────────────────────────────────────────────────────────────────

class WeatherResponse {
  final double temp;
  final double feelsLike;
  final int humidity;
  final int cloudiness;
  final double windSpeed;
  final String description;
  final String icon;
  final DateTime sunrise;
  final DateTime sunset;

  WeatherResponse({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.cloudiness,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.sunrise,
    required this.sunset,
  });

  Map<String, dynamic> toJson() => {
        'temp': temp,
        'feels_like': feelsLike,
        'humidity': humidity,
        'cloudiness': cloudiness,
        'wind_speed': windSpeed,
        'description': description,
        'icon': icon,
        'sunrise': sunrise.toIso8601String(),
        'sunset': sunset.toIso8601String(),
      };

  factory WeatherResponse.fromJson(Map<String, dynamic> j) => WeatherResponse(
        temp: (j['temp'] as num).toDouble(),
        feelsLike: (j['feels_like'] as num).toDouble(),
        humidity: (j['humidity'] as num).toInt(),
        cloudiness: (j['cloudiness'] as num).toInt(),
        windSpeed: (j['wind_speed'] as num).toDouble(),
        description: j['description'] as String,
        icon: j['icon'] as String,
        sunrise: DateTime.parse(j['sunrise'] as String),
        sunset: DateTime.parse(j['sunset'] as String),
      );

  factory WeatherResponse.fromOwmJson(Map<String, dynamic> j) {
    final main = j['main'] as Map<String, dynamic>;
    final wind = j['wind'] as Map<String, dynamic>;
    final clouds = j['clouds'] as Map<String, dynamic>;
    final sys = j['sys'] as Map<String, dynamic>;
    final weather = (j['weather'] as List).first as Map<String, dynamic>;
    return WeatherResponse(
      temp: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
      cloudiness: (clouds['all'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (sys['sunrise'] as int) * 1000,
          isUtc: true),
      sunset: DateTime.fromMillisecondsSinceEpoch(
          (sys['sunset'] as int) * 1000,
          isUtc: true),
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
      externalUrl: j['link'] as String? ?? 'https://www.deezer.com/track/${j['id']}',
      durationSeconds: (j['duration'] as num?)?.toInt() ?? 0,
    );
  }
}