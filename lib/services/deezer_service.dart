import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weatherfy_api/models/responses.dart';

const _moodGenreIds = {
  'high_energy_positive': 132,
  'high_energy_negative': 152,
  'low_energy_positive': 53,
  'low_energy_negative': 6,
};

const _moodSearchTags = {
  'high_energy_positive': 'happy upbeat',
  'high_energy_negative': 'intense dark',
  'low_energy_positive': 'chill relax',
  'low_energy_negative': 'melancholic ambient',
};

class DeezerService {
  static const _baseUrl = 'https://api.deezer.com';

  Future<List<TrackResponse>> getRecommendations({
    required double energy,
    required double valence,
    int limit = 20,
  }) async {
    final quadrant = _getQuadrant(energy, valence);
    final genreId = _moodGenreIds[quadrant]!;

    final tracks = await _fetchByGenre(genreId, limit);
    if (tracks.isNotEmpty) return tracks;

    return _fetchBySearch(_moodSearchTags[quadrant]!, limit);
  }

  Future<List<TrackResponse>> _fetchByGenre(int genreId, int limit) async {
    final radioResponse = await http.get(Uri.parse('$_baseUrl/genre/$genreId/radios'));
    if (radioResponse.statusCode != 200) return [];

    final radios = (jsonDecode(radioResponse.body)['data'] as List?) ?? [];
    if (radios.isEmpty) return [];

    final firstRadioId = (radios.first as Map<String, dynamic>)['id'];
    final tracksResponse = await http.get(
      Uri.parse('$_baseUrl/radio/$firstRadioId/tracks?limit=$limit'),
    );
    if (tracksResponse.statusCode != 200) return [];

    final data = (jsonDecode(tracksResponse.body)['data'] as List?) ?? [];
    return data.take(limit).map((j) => TrackResponse.fromDeezerJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<TrackResponse>> _fetchBySearch(String query, int limit) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'limit': limit.toString(),
      'order': 'RANKING',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Deezer search failed [${response.statusCode}]');
    }
    final data = (jsonDecode(response.body)['data'] as List?) ?? [];
    return data.map((j) => TrackResponse.fromDeezerJson(j as Map<String, dynamic>)).toList();
  }

  static String _getQuadrant(double energy, double valence) {
    if (energy >= 0.5 && valence >= 0.5) return 'high_energy_positive';
    if (energy >= 0.5 && valence < 0.5) return 'high_energy_negative';
    if (energy < 0.5 && valence >= 0.5) return 'low_energy_positive';
    return 'low_energy_negative';
  }
}