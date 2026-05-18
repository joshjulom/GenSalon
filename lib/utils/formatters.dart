import 'package:intl/intl.dart';

final pesoFormat = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);

String formatPeso(num value) => pesoFormat.format(value);

final dateFmt = DateFormat('MMM d, y');
final timeFmt = DateFormat('h:mm a');
final dateTimeFmt = DateFormat('MMM d, y • h:mm a');
