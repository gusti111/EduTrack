/// Representasi error yang sudah "diterjemahkan" dari exception mentah
/// (Firebase, network, dll) menjadi bentuk yang bisa langsung dipakai UI.
///
/// Alur: Service melempar exception mentah -> Repository menangkapnya
/// lalu melempar ulang sebagai [Failure] -> Provider menangkap [Failure]
/// dan expose ke UI lewat state, bukan lewat try-catch tersebar di mana-mana.
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(
      [super.message = 'Tidak ada koneksi internet. Periksa jaringan kamu.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Terjadi kesalahan yang tidak diketahui.']);
}
