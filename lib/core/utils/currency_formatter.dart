import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  static int parse(String amount) {
    return int.tryParse(amount.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }
}

