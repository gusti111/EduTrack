import 'dart:async';

/// Firestore REST API (lihat [FirestoreRestClient]) tidak punya realtime
/// listener seperti `snapshots()` di SDK biasa — ini menggantikannya
/// dengan pola polling: [fetch] dipanggil sekali langsung saat ada
/// listener pertama, lalu diulang tiap [interval].
///
/// CATATAN: ini BUKAN realtime beneran (ada jeda sampai [interval]
/// sebelum perubahan dari device/sesi lain terlihat), tapi cukup untuk
/// kebutuhan app ini (task planner personal, bukan kolaborasi live).
///
/// Kalau [fetch] melempar error, itu diteruskan ke stream lewat
/// [StreamController.addError] tanpa menghentikan polling — supaya satu
/// request yang gagal (mis. timeout sesaat) tidak mematikan listener
/// selamanya, dan permintaan berikutnya tetap dicoba di tick selanjutnya.
Stream<T> pollingStream<T>({
  required Future<T> Function() fetch,
  Duration interval = const Duration(seconds: 5),
}) {
  late final StreamController<T> controller;
  Timer? timer;

  Future<void> tick() async {
    if (controller.isClosed) return;
    try {
      final result = await fetch();
      if (!controller.isClosed) controller.add(result);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  controller = StreamController<T>.broadcast(
    onListen: () {
      tick();
      timer?.cancel();
      timer = Timer.periodic(interval, (_) => tick());
    },
    onCancel: () {
      timer?.cancel();
    },
  );

  return controller.stream;
}
