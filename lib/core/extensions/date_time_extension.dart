import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String get toDisplayDate => DateFormat('dd MMM yyyy').format(this);

  bool get isPastNow => isBefore(DateTime.now());
}
