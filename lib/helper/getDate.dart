import 'package:hijri_date/hijri_date.dart';

String formatFullDate() {
  // Get Gregorian date
  final now = DateTime.now();
  final gregorianDate =
      "${now.day} ${getGregorianMonth(now.month)} ${now.year}";

  // Get Hijri date
  final hijri = HijriDate.now();
  final hijriDate =
      "${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} AH";

  return "$hijriDate  •  $gregorianDate";
}

// Helper to get Gregorian month name
String getGregorianMonth(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
