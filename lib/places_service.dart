import 'dart:convert';
import 'package:http/http.dart' as http;
import 'place_model.dart';

class PlacesService {
  // Change to 10.0.2.2 when using Android emulator
  static const String _baseUrl = 'http://localhost:3000/api/v1';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── GET /places ────────────────────────────────────────────────────────
  static Future<List<Place>> fetchPlaces() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/places'),
      headers: _headers,
    );
    _checkStatus(response);
    final body = _decode(response);
    if (body['status'] == true) {
      return (body['data'] as List)
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to fetch places');
  }

  // ── GET /places/:id ────────────────────────────────────────────────────
  static Future<Place> fetchPlace(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/places/$id'),
      headers: _headers,
    );
    _checkStatus(response);
    return Place.fromJson(_decode(response));
  }

  // ── POST /places ───────────────────────────────────────────────────────
  static Future<Place> createPlace(Place place) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/places'),
      headers: _headers,
      body: jsonEncode({'place': place.toJson()}),
    );
    _checkStatus(response);
    return Place.fromJson(_decode(response));
  }

  // ── PUT /places/:id ────────────────────────────────────────────────────
  static Future<Place> updatePlace(int id, Place place) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/places/$id'),
      headers: _headers,
      body: jsonEncode({'place': place.toJson()}),
    );
    _checkStatus(response);
    return Place.fromJson(_decode(response));
  }

  // ── DELETE /places/:id ─────────────────────────────────────────────────
  static Future<void> deletePlace(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/places/$id'),
      headers: _headers,
    );
    _checkStatus(response);
    final body = _decode(response);
    if (body['status'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete place');
    }
  }

  // ── DELETE /places/:placeId/images/:imageId ────────────────────────────
  // TODO: update path once you share the actual endpoint
  static Future<void> deleteImage(int placeId, int imageId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/places/$placeId/images/$imageId'),
      headers: _headers,
    );
    _checkStatus(response);
    final body = _decode(response);
    if (body['status'] == false) {
      throw Exception(body['message'] ?? 'Failed to delete image');
    }
  }

  // ── POST /places/:placeId/images ───────────────────────────────────────
  // TODO: update with multipart/form-data once you share the actual endpoint
  static Future<PlaceImage> addImage(int placeId, String imageUrl) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/places/$placeId/images'),
      headers: _headers,
      body: jsonEncode({'url': imageUrl}),
    );
    _checkStatus(response);
    return PlaceImage.fromJson(_decode(response));
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  static void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  static Map<String, dynamic> _decode(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;
}
