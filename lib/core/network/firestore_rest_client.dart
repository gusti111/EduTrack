import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Dilempar kalau Firestore REST API membalas dengan status error
/// (4xx/5xx). Menggantikan peran `FirebaseException` dari package
/// `cloud_firestore` yang sudah tidak dipakai lagi.
class FirestoreRestException implements Exception {
  final int statusCode;
  final String message;
  const FirestoreRestException({required this.statusCode, required this.message});

  @override
  String toString() => 'FirestoreRestException($statusCode): $message';
}

/// Client REST minimal untuk Cloud Firestore.
///
/// LATAR BELAKANG: package `cloud_firestore` (dan gRPC/WebChannel di
/// baliknya) terbukti macet konsisten di lingkungan tertentu — sudah
/// dicoba di berbagai platform (Web, Android emulator) dan jaringan
/// (kampus, hotspot HP) dengan hasil yang sama: operasi tulis selalu
/// timeout tepat di batas waktu client, sementara request HTTP singkat
/// biasa (termasuk Firebase Auth, dan tes manual ke firestore.googleapis.com)
/// selalu lancar. Firestore REST API memakai pola request-response singkat
/// yang sama seperti itu, sehingga jadi jalan keluar yang jauh lebih andal
/// untuk kondisi ini — dengan konsekuensi: TIDAK ADA realtime listener
/// bawaan (`snapshots()`) lewat REST biasa. Kalau butuh update
/// "realtime", itu diakali lewat polling berkala di lapisan Repository
/// (lihat TaskRepositoryImpl/NotificationRepositoryImpl), bukan di sini.
class FirestoreRestClient {
  FirestoreRestClient({FirebaseAuth? auth, http.Client? httpClient})
      : _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _httpClient;

  /// Batas waktu wajar untuk satu request. REST API ini adalah
  /// request-response singkat (bukan streaming), jadi kalau sampai kena
  /// timeout ini, itu benar-benar berarti ada masalah jaringan nyata —
  /// bukan karakteristik transport seperti pada WebChannel/gRPC.
  static const Duration timeout = Duration(seconds: 15);

  String get _projectId => Firebase.app().options.projectId;

  Uri _documentsUri([String path = '']) => Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId'
        '/databases/(default)/documents$path',
      );

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String message = res.body;
    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      message = (decoded['error']?['message'] as String?) ?? res.body;
    } catch (_) {
      // Body bukan JSON valid — pakai apa adanya.
    }
    throw FirestoreRestException(statusCode: res.statusCode, message: message);
  }

  static String _idFromDocumentName(String name) => name.split('/').last;

  // ---------------- Konversi Map<String,dynamic> <-> Firestore "fields" ----------------

  static Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_encodeValue).toList()},
      };
    }
    throw ArgumentError(
      'FirestoreRestClient: tipe data ${value.runtimeType} belum didukung. '
      'Kalau butuh tipe baru, tambahkan case-nya di _encodeValue/_decodeValue.',
    );
  }

  static dynamic _decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'] as String);
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    // Timestamp REST dikembalikan sebagai string RFC3339 — dibiarkan
    // sebagai String, sama seperti field tanggal lain di model (lihat
    // UserModel/TaskModel yang memang sudah pakai ISO8601 String, bukan
    // tipe Timestamp dari cloud_firestore).
    if (value.containsKey('timestampValue')) return value['timestampValue'];
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('arrayValue')) {
      final values =
          (value['arrayValue'] as Map<String, dynamic>)['values'] as List? ?? [];
      return values
          .map((v) => _decodeValue(v as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  static Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _encodeValue(value)));
  }

  static Map<String, dynamic> _decodeFields(Map<String, dynamic> fields) {
    return fields.map(
      (key, value) => MapEntry(key, _decodeValue(value as Map<String, dynamic>)),
    );
  }

  // ---------------- Operasi dokumen tunggal ----------------

  /// Ambil satu dokumen. Return null kalau tidak ada (404), BUKAN throw —
  /// supaya pemanggil bisa langsung `if (doc == null)` tanpa try-catch.
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    final res = await _httpClient
        .get(_documentsUri('/$collection/$docId'), headers: await _headers())
        .timeout(timeout);
    if (res.statusCode == 404) return null;
    _throwIfError(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return _decodeFields(body['fields'] as Map<String, dynamic>? ?? {});
  }

  /// Timpa SELURUH dokumen dengan [data] (field yang tidak disebut akan
  /// HILANG). Dipakai untuk dokumen baru (mis. profil user saat Register)
  /// di mana semua field memang disediakan sekaligus. Untuk update
  /// sebagian field pada dokumen yang sudah ada, pakai [updateFields].
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final res = await _httpClient
        .patch(
          _documentsUri('/$collection/$docId'),
          headers: await _headers(),
          body: jsonEncode({'fields': _encodeFields(data)}),
        )
        .timeout(timeout);
    _throwIfError(res);
  }

  /// Update HANYA field yang disebut di [data] — field lain pada dokumen
  /// tetap utuh (lewat query param `updateMask.fieldPaths`).
  Future<void> updateFields(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final uri = _documentsUri('/$collection/$docId').replace(
      queryParameters: {'updateMask.fieldPaths': data.keys.toList()},
    );
    final res = await _httpClient
        .patch(
          uri,
          headers: await _headers(),
          body: jsonEncode({'fields': _encodeFields(data)}),
        )
        .timeout(timeout);
    _throwIfError(res);
  }

  /// Tambah dokumen baru dengan ID otomatis. Return ID dokumen yang dibuat.
  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final res = await _httpClient
        .post(
          _documentsUri('/$collection'),
          headers: await _headers(),
          body: jsonEncode({'fields': _encodeFields(data)}),
        )
        .timeout(timeout);
    _throwIfError(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return _idFromDocumentName(body['name'] as String);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    final res = await _httpClient
        .delete(_documentsUri('/$collection/$docId'), headers: await _headers())
        .timeout(timeout);
    _throwIfError(res);
  }

  // ---------------- Query (where + orderBy) ----------------

  /// Setara `.where(field, isEqualTo: value).orderBy(orderByField)` di
  /// SDK biasa. CATATAN: kombinasi where+orderBy pada field BERBEDA butuh
  /// composite index di Firestore. Kalau index belum ada, Firestore akan
  /// membalas error berisi LINK LANGSUNG untuk membuatnya otomatis — baca
  /// pesan errornya (lewat [FirestoreRestException.message]) kalau query
  /// ini gagal.
  ///
  /// Return list `MapEntry(docId, fields)` supaya pemanggil tidak perlu
  /// tahu bentuk response mentah Firestore.
  Future<List<MapEntry<String, Map<String, dynamic>>>> runQuery({
    required String collection,
    required String whereField,
    required String whereEquals,
    String? orderByField,
    bool descending = false,
  }) async {
    final body = {
      'structuredQuery': {
        'from': [
          {'collectionId': collection},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': whereField},
            'op': 'EQUAL',
            'value': {'stringValue': whereEquals},
          },
        },
        if (orderByField != null)
          'orderBy': [
            {
              'field': {'fieldPath': orderByField},
              'direction': descending ? 'DESCENDING' : 'ASCENDING',
            },
          ],
      },
    };

    final res = await _httpClient
        .post(
          _documentsUri(':runQuery'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    _throwIfError(res);

    final list = jsonDecode(res.body) as List<dynamic>;
    final results = <MapEntry<String, Map<String, dynamic>>>[];
    for (final item in list) {
      final doc = (item as Map<String, dynamic>)['document'] as Map<String, dynamic>?;
      if (doc == null) continue; // heartbeat/entry kosong dari runQuery, lewati saja
      final id = _idFromDocumentName(doc['name'] as String);
      final fields = _decodeFields(doc['fields'] as Map<String, dynamic>? ?? {});
      results.add(MapEntry(id, fields));
    }
    return results;
  }
}
