import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(double amount) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }

  static String formatCurrencyShort(double amount) {
    if (amount >= 1000000) {
      double millions = amount / 1000000;
      // Removes trailing zeros if it's an integer
      String formatted = millions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return 'Rp$formatted jt';
    }
    return formatCurrency(amount);
  }
}
