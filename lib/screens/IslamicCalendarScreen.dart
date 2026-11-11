import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;

class IslamicEvent {
  final int hijriMonth;
  final int hijriDay;
  final String title;
  final String titleUr;
  final String description;
  final String descriptionUr;
  final String wikiEn; // exact English Wikipedia article title
  final String wikiUr; // exact Urdu Wikipedia article title
  final EventType type;
  final bool isHoliday;

  const IslamicEvent({
    required this.hijriMonth,
    required this.hijriDay,
    required this.title,
    required this.titleUr,
    required this.description,
    required this.descriptionUr,
    required this.wikiEn,
    required this.wikiUr,
    this.type = EventType.general,
    this.isHoliday = false,
  });
}

enum EventType { festival, fasting, mourning, historical, general }

enum CalendarMode { hijri, gregorian }

// Height of one calendar row (compact cards)
const double _kTileHeight = 54;

// Local palette (swap for your AppColors class if you prefer)
class _CalColors {
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF003300);
}

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  CalendarMode _mode = CalendarMode.hijri;

  // Currently displayed month
  late int _hijriYear;
  late int _hijriMonth;
  late int _gregYear;
  late int _gregMonth;

  final List<IslamicEvent> _allEvents = const [
    // ═══════════════ MUHARRAM (1) ═══════════════
    IslamicEvent(
      hijriMonth: 1,
      hijriDay: 1,
      title: 'Islamic New Year',
      titleUr: 'اسلامی نیا سال',
      description:
          'The first day of the Hijri year, marking the migration (Hijrah) of Prophet Muhammad ﷺ from Makkah to Madinah.',
      descriptionUr:
          'ہجری سال کا پہلا دن، جو نبی کریم ﷺ کی مکہ سے مدینہ ہجرت کی یاد دلاتا ہے۔',
      wikiEn: 'Islamic New Year',
      wikiUr: 'اسلامی نیا سال',
      type: EventType.historical,
      isHoliday: true,
    ),
    IslamicEvent(
      hijriMonth: 1,
      hijriDay: 9,
      title: 'Day of Tasu\'a',
      titleUr: 'یومِ تاسوعہ',
      description:
          'The 9th of Muharram. Fasting on this day is recommended along with Ashura.',
      descriptionUr:
          '9 محرم الحرام۔ عاشورہ کے ساتھ اس دن کا روزہ رکھنا مستحب ہے۔',
      wikiEn: 'Tasu\'a',
      wikiUr: 'تاسوعہ',
      type: EventType.fasting,
    ),
    IslamicEvent(
      hijriMonth: 1,
      hijriDay: 10,
      title: 'Day of Ashura',
      titleUr: 'یومِ عاشورہ',
      description:
          'The 10th of Muharram. Fasting on this day expiates the sins of the previous year. Also marks the martyrdom of Imam Hussain (RA) at Karbala.',
      descriptionUr:
          '10 محرم الحرام۔ اس دن کا روزہ گزشتہ سال کے گناہوں کا کفارہ ہے۔ کربلا میں امام حسینؓ کی شہادت کا دن بھی ہے۔',
      wikiEn: 'Ashura',
      wikiUr: 'عاشورہ',
      type: EventType.fasting,
      isHoliday: true,
    ),

    // ═══════════════ SAFAR (2) ═══════════════
    IslamicEvent(
      hijriMonth: 2,
      hijriDay: 27,
      title: 'Hijrah of Prophet ﷺ',
      titleUr: 'ہجرتِ نبی ﷺ',
      description:
          'Commemoration of the Prophet\'s ﷺ migration from Makkah to Madinah.',
      descriptionUr: 'نبی کریم ﷺ کی مکہ سے مدینہ منورہ ہجرت کی یادگار۔',
      wikiEn: 'Hijrah',
      wikiUr: 'ہجرت نبوی',
      type: EventType.historical,
    ),

    // ═══════════════ RABI AL-AWWAL (3) ═══════════════
    IslamicEvent(
      hijriMonth: 3,
      hijriDay: 12,
      title: 'Mawlid un-Nabi ﷺ',
      titleUr: 'میلاد النبی ﷺ',
      description:
          'The birth of Prophet Muhammad ﷺ. Celebrated by many Muslims worldwide with prayers and remembrance.',
      descriptionUr:
          'نبی کریم ﷺ کی ولادت باسعادت۔ دنیا بھر کے مسلمان اس دن کو ذکر و درود سے مناتے ہیں۔',
      wikiEn: 'Mawlid',
      wikiUr: 'میلاد النبی',
      type: EventType.festival,
      isHoliday: true,
    ),

    // ═══════════════ RABI AL-THANI (4) ═══════════════
    IslamicEvent(
      hijriMonth: 4,
      hijriDay: 11,
      title: 'Urs of Abdul Qadir Jilani',
      titleUr: 'عرس حضرت عبدالقادر جیلانیؒ',
      description:
          'Commemoration of Sheikh Abdul Qadir Jilani (RA), the great Sufi saint and founder of the Qadiriyya order.',
      descriptionUr:
          'حضرت شیخ عبدالقادر جیلانیؒ کی یاد میں، جو عظیم صوفی بزرگ اور سلسلہ قادریہ کے بانی ہیں۔',
      wikiEn: 'Abdul Qadir Gilani',
      wikiUr: 'عبدالقادر جیلانی',
      type: EventType.historical,
    ),

    // ═══════════════ JUMADA AL-AWWAL (5) ═══════════════
    IslamicEvent(
      hijriMonth: 5,
      hijriDay: 5,
      title: 'Battle of Mutah',
      titleUr: 'جنگِ موتہ',
      description:
          'Commemoration of the Battle of Mutah where Khalid bin Walid (RA) earned the title "Sword of Allah".',
      descriptionUr:
          'جنگِ موتہ کی یادگار، جس میں حضرت خالد بن ولیدؓ کو "سیف اللہ" کا لقب ملا۔',
      wikiEn: 'Battle of Mu\'tah',
      wikiUr: 'جنگ موتہ',
      type: EventType.historical,
    ),

    // ═══════════════ JUMADA AL-THANI (6) ═══════════════
    IslamicEvent(
      hijriMonth: 6,
      hijriDay: 22,
      title: 'Hazrat Abu Bakr Siddiq (RA)',
      titleUr: 'حضرت ابوبکر صدیقؓ',
      description: 'Commemoration of the passing of the first Caliph of Islam.',
      descriptionUr: 'اسلام کے پہلے خلیفہ کی یاد میں۔',
      wikiEn: 'Abu Bakr',
      wikiUr: 'ابوبکر صدیق',
      type: EventType.historical,
    ),

    // ═══════════════ RAJAB (7) ═══════════════
    IslamicEvent(
      hijriMonth: 7,
      hijriDay: 1,
      title: 'Start of Rajab',
      titleUr: 'رجب کی ابتدا',
      description:
          'Beginning of the sacred month of Rajab, one of the four sacred months in Islam.',
      descriptionUr:
          'ماہِ رجب کا آغاز، جو اسلام کے چار حرمت والے مہینوں میں سے ایک ہے۔',
      wikiEn: 'Rajab',
      wikiUr: 'رجب',
      type: EventType.general,
    ),
    IslamicEvent(
      hijriMonth: 7,
      hijriDay: 13,
      title: 'Birth of Ali (RA)',
      titleUr: 'ولادتِ حضرت علیؓ',
      description:
          'Birth anniversary of Hazrat Ali ibn Abi Talib (RA), the fourth Caliph of Islam.',
      descriptionUr: 'چوتھے خلیفہ حضرت علی ابن ابی طالبؓ کی ولادت کی یادگار۔',
      wikiEn: 'Ali',
      wikiUr: 'علی بن ابی طالب',
      type: EventType.historical,
    ),
    IslamicEvent(
      hijriMonth: 7,
      hijriDay: 27,
      title: 'Isra & Mi\'raj',
      titleUr: 'شبِ معراج',
      description:
          'The Night Journey of Prophet Muhammad ﷺ from Makkah to Jerusalem and ascension to the heavens.',
      descriptionUr:
          'نبی کریم ﷺ کا مکہ سے بیت المقدس اور پھر آسمانوں تک کا سفرِ معراج۔',
      wikiEn: 'Isra and Mi\'raj',
      wikiUr: 'معراج',
      type: EventType.historical,
      isHoliday: true,
    ),

    // ═══════════════ SHA\'BAN (8) ═══════════════
    IslamicEvent(
      hijriMonth: 8,
      hijriDay: 1,
      title: 'Start of Sha\'ban',
      titleUr: 'شعبان کی ابتدا',
      description:
          'Beginning of the month preceding Ramadan. A time for increased worship and preparation.',
      descriptionUr: 'رمضان سے پہلے مہینے کا آغاز۔ عبادت اور تیاری کا وقت۔',
      wikiEn: 'Sha\'ban',
      wikiUr: 'شعبان',
      type: EventType.general,
    ),
    IslamicEvent(
      hijriMonth: 8,
      hijriDay: 15,
      title: 'Shab-e-Barat',
      titleUr: 'شبِ برات',
      description:
          'The 15th night of Sha\'ban, a night of forgiveness and blessings. Many Muslims spend it in prayer and fasting.',
      descriptionUr:
          'شعبان کی 15ویں شب، جو بخشش اور برکتوں کی رات ہے۔ بہت سے مسلمان اسے عبادت اور روزے میں گزارتے ہیں۔',
      wikiEn: 'Mid-Sha\'ban',
      wikiUr: 'شب برات',
      type: EventType.festival,
      isHoliday: true,
    ),

    // ═══════════════ RAMADAN (9) ═══════════════
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 1,
      title: 'First Day of Ramadan',
      titleUr: 'رمضان کا پہلا دن',
      description:
          'The beginning of the blessed month of fasting, the 4th pillar of Islam.',
      descriptionUr: 'ماہِ صیام کا آغاز، جو اسلام کا چوتھا رکن ہے۔',
      wikiEn: 'Ramadan',
      wikiUr: 'رمضان',
      type: EventType.fasting,
      isHoliday: true,
    ),
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 17,
      title: 'Battle of Badr',
      titleUr: 'جنگِ بدر',
      description:
          'Commemoration of the first major battle of Islam on the 17th of Ramadan.',
      descriptionUr: '17 رمضان کو اسلام کی پہلی بڑی جنگ کی یادگار۔',
      wikiEn: 'Battle of Badr',
      wikiUr: 'جنگ بدر',
      type: EventType.historical,
    ),
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 21,
      title: 'Martyrdom of Ali (RA)',
      titleUr: 'شہادتِ حضرت علیؓ',
      description:
          'Commemoration of the martyrdom of Hazrat Ali ibn Abi Talib (RA), the 4th Caliph.',
      descriptionUr: 'چوتھے خلیفہ حضرت علی ابن ابی طالبؓ کی شہادت کی یادگار۔',
      wikiEn: 'Assassination of Ali',
      wikiUr: 'علی بن ابی طالب',
      type: EventType.mourning,
    ),
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 27,
      title: 'Laylat al-Qadr (likely)',
      titleUr: 'شبِ قدر (غالب امکان)',
      description:
          'The Night of Power, better than a thousand months. Most likely to occur on the 27th night of Ramadan.',
      descriptionUr:
          'شبِ قدر، ہزار مہینوں سے بہتر۔ غالب امکان ہے کہ رمضان کی 27ویں شب کو ہو۔',
      wikiEn: 'Laylat al-Qadr',
      wikiUr: 'شب قدر',
      type: EventType.festival,
      isHoliday: true,
    ),

    // ═══════════════ SHAWWAL (10) ═══════════════
    IslamicEvent(
      hijriMonth: 10,
      hijriDay: 1,
      title: 'Eid ul-Fitr',
      titleUr: 'عید الفطر',
      description:
          'The Festival of Breaking the Fast, celebrated on the 1st of Shawwal after the completion of Ramadan.',
      descriptionUr:
          'عید الفطر، جو رمضان کے اختتام پر یکم شوال کو منائی جاتی ہے۔',
      wikiEn: 'Eid al-Fitr',
      wikiUr: 'عید الفطر',
      type: EventType.festival,
      isHoliday: true,
    ),
    IslamicEvent(
      hijriMonth: 10,
      hijriDay: 2,
      title: 'Second Day of Eid',
      titleUr: 'عید کا دوسرا دن',
      description:
          'Continued celebration of Eid ul-Fitr with family and community.',
      descriptionUr: 'عید الفطر کی خوشیاں خاندان اور محلے کے ساتھ جاری۔',
      wikiEn: 'Eid al-Fitr',
      wikiUr: 'عید الفطر',
      type: EventType.festival,
    ),

    // ═══════════════ DHU AL-QADAH (11) ═══════════════
    IslamicEvent(
      hijriMonth: 11,
      hijriDay: 1,
      title: 'Start of Dhu al-Qadah',
      titleUr: 'ذیقعدہ کی ابتدا',
      description:
          'Beginning of the 11th month, one of the four sacred months.',
      descriptionUr:
          'گیارہویں مہینے کا آغاز، جو چار حرمت والے مہینوں میں شامل ہے۔',
      wikiEn: 'Dhu al-Qi\'dah',
      wikiUr: 'ذوالقعدہ',
      type: EventType.general,
    ),

    // ═══════════════ DHU AL-HIJJAH (12) ═══════════════
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 1,
      title: 'Start of Dhu al-Hijjah',
      titleUr: 'ذی الحجہ کی ابتدا',
      description:
          'Beginning of the sacred month of Hajj. First 10 days are the most blessed days of the year.',
      descriptionUr:
          'حج کے مہینے کا آغاز۔ پہلے دس دن سال کے سب سے بابرکت دن ہیں۔',
      wikiEn: 'Dhu al-Hijjah',
      wikiUr: 'ذوالحجہ',
      type: EventType.general,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 8,
      title: 'Day of Tarwiyah',
      titleUr: 'یومِ ترویہ',
      description: 'The 8th of Dhu al-Hijjah, when pilgrims travel to Mina.',
      descriptionUr: '8 ذی الحجہ، جب حاجی منیٰ کی طرف روانہ ہوتے ہیں۔',
      wikiEn: 'Tarwiyah',
      wikiUr: 'یوم ترویہ',
      type: EventType.historical,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 9,
      title: 'Day of Arafah',
      titleUr: 'یومِ عرفہ',
      description:
          'The most important day of Hajj. Fasting on this day expiates the sins of two years.',
      descriptionUr:
          'حج کا سب سے اہم دن۔ اس دن کا روزہ دو سال کے گناہوں کا کفارہ ہے۔',
      wikiEn: 'Day of Arafah',
      wikiUr: 'یوم عرفہ',
      type: EventType.fasting,
      isHoliday: true,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 10,
      title: 'Eid ul-Adha',
      titleUr: 'عید الاضحیٰ',
      description:
          'The Festival of Sacrifice, commemorating Prophet Ibrahim\'s (AS) willingness to sacrifice his son.',
      descriptionUr: 'عید قربان، حضرت ابراہیمؑ کی قربانی کی تیاری کی یادگار۔',
      wikiEn: 'Eid al-Adha',
      wikiUr: 'عید الاضحیٰ',
      type: EventType.festival,
      isHoliday: true,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 11,
      title: 'Days of Tashreeq',
      titleUr: 'ایامِ تشریق',
      description:
          '11th-13th of Dhu al-Hijjah. Days of eating, drinking, and remembrance of Allah.',
      descriptionUr: '11 تا 13 ذی الحجہ۔ کھانے، پینے اور ذکرِ الٰہی کے دن۔',
      wikiEn: 'Days of Tashreeq',
      wikiUr: 'ایام تشریق',
      type: EventType.festival,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 12,
      title: 'Days of Tashreeq',
      titleUr: 'ایامِ تشریق',
      description: 'Continued days of Tashreeq and remembrance of Allah.',
      descriptionUr: 'ایامِ تشریق اور ذکرِ الٰہی کا سلسلہ جاری۔',
      wikiEn: 'Days of Tashreeq',
      wikiUr: 'ایام تشریق',
      type: EventType.festival,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 13,
      title: 'Days of Tashreeq (End)',
      titleUr: 'ایامِ تشریق (اختتام)',
      description:
          'Last day of Tashreeq. Pilgrims perform the final stoning ritual.',
      descriptionUr: 'تشریق کا آخری دن۔ حاجی آخری رمی کرتے ہیں۔',
      wikiEn: 'Days of Tashreeq',
      wikiUr: 'ایام تشریق',
      type: EventType.festival,
    ),
  ];

  static const List<String> _hijriMonths = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qadah',
    'Dhu al-Hijjah',
  ];

  static const List<String> _hijriMonthsArabic = [
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع ٱلْأَوَّل',
    'رَبِيع ٱلثَّانِي',
    'جُمَادَىٰ ٱلْأُولَىٰ',
    'جُمَادَىٰ ٱلثَّانِيَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو ٱلْقَعْدَة',
    'ذُو ٱلْحِجَّة',
  ];

  // Wikipedia search terms per event (falls back to the event title).
  static const Map<String, String> _wikiQueries = {
    'Islamic New Year': 'Islamic New Year',
    'Day of Tasu\'a': 'Ashura',
    'Day of Ashura': 'Ashura',
    'Hijrah of Prophet ﷺ': 'Hijrah',
    'Mawlid un-Nabi ﷺ': 'Mawlid',
    'Urs of Abdul Qadir Jilani': 'Abdul Qadir Gilani',
    'Battle of Mutah': 'Battle of Mu\'tah',
    'Hazrat Abu Bakr Siddiq (RA)': 'Abu Bakr',
    'Start of Rajab': 'Rajab',
    'Isra & Mi\'raj': 'Isra and Mi\'raj',
    'Start of Sha\'ban': 'Sha\'ban',
    'Shab-e-Barat': 'Mid-Sha\'ban Laylat al-Bara\'at',
    'First Day of Ramadan': 'Ramadan',
    'Battle of Badr': 'Battle of Badr',
    'Martyrdom of Ali (RA)': 'Ali ibn Abi Talib assassination',
    'Laylat al-Qadr (likely)': 'Laylat al-Qadr',
    'Eid ul-Fitr': 'Eid al-Fitr',
    'Second Day of Eid': 'Eid al-Fitr',
    'Start of Dhu al-Qadah': 'Dhu al-Qi\'dah',
    'Start of Dhu al-Hijjah': 'Dhu al-Hijjah',
    'Day of Tarwiyah': 'Day of Tarwiyah Hajj',
    'Day of Arafah': 'Day of Arafah',
    'Eid ul-Adha': 'Eid al-Adha',
    'Days of Tashreeq': 'Tashreeq',
    'Days of Tashreeq (End)': 'Tashreeq',
  };

  String _wikiQueryFor(IslamicEvent e) =>
      _wikiQueries[e.title] ??
      e.title.replaceAll(RegExp(r'\(.*?\)|ﷺ'), '').trim();

  @override
  void initState() {
    super.initState();
    final today = HijriCalendar.now();
    _hijriYear = today.hYear;
    _hijriMonth = today.hMonth;

    final now = DateTime.now();
    _gregYear = now.year;
    _gregMonth = now.month;
  }

  // ─────────────────────────────────────────────────────────────
  //  Helper: convert current displayed month to a Gregorian anchor
  // ─────────────────────────────────────────────────────────────
  DateTime _gregorianAnchorForHijri() {
    // Mid-month gives the best Gregorian month to land on when switching.
    return HijriCalendar().hijriToGregorian(_hijriYear, _hijriMonth, 15);
  }

  // Label for every Hijri month touched by the visible Gregorian month,
  // e.g. "Rabi al-Awwal – Rabi al-Thani 1448 AH".
  String _hijriRangeLabel(List<_DayCell> cells) {
    final seen = <List<int>>[]; // [year, month]
    for (final c in cells) {
      if (c.isEmpty) continue;
      final y = c.hijri!.hYear;
      final m = c.hijri!.hMonth;
      if (seen.isEmpty || seen.last[0] != y || seen.last[1] != m) {
        seen.add([y, m]);
      }
    }
    if (seen.isEmpty) return '';
    final sameYear = seen.every((e) => e[0] == seen.first[0]);
    if (sameYear) {
      final names = seen.map((e) => _hijriMonths[e[1] - 1]).join(' – ');
      return '$names ${seen.first[0]} AH';
    }
    return seen.map((e) => '${_hijriMonths[e[1] - 1]} ${e[0]}').join(' – ') +
        ' AH';
  }

  // ─────────────────────────────────────────────────────────────
  //  Build the 6×7 grid of dates for the current month
  //  Returns list of _DayCell
  // ─────────────────────────────────────────────────────────────
  List<_DayCell> _buildMonthGrid() {
    final cells = <_DayCell>[];

    if (_mode == CalendarMode.gregorian) {
      final firstOfMonth = DateTime(_gregYear, _gregMonth, 1);
      final daysInMonth = DateTime(_gregYear, _gregMonth + 1, 0).day;

      // Monday = 1, Sunday = 7
      final startWeekday = firstOfMonth.weekday;

      // Empty cells before day 1
      for (int i = 1; i < startWeekday; i++) {
        cells.add(_DayCell.empty());
      }
      for (int d = 1; d <= daysInMonth; d++) {
        final gDate = DateTime(_gregYear, _gregMonth, d);
        final hDate = HijriCalendar.fromDate(gDate);
        final events = _eventsForHijriDate(hDate.hMonth, hDate.hDay);
        cells.add(
          _DayCell(
            gregorian: gDate,
            hijri: hDate,
            events: events,
            isToday: _isSameGregorianDay(gDate, DateTime.now()),
          ),
        );
      }
      // Pad to complete the last week
      while (cells.length % 7 != 0) {
        cells.add(_DayCell.empty());
      }
    } else {
      // ── Hijri grid ──
      // Determine length of Hijri month: try to build the next month
      // and diff. HijriCalendar supports monthLength via hMonthLength().
      final firstHijri = HijriCalendar()
        ..hYear = _hijriYear
        ..hMonth = _hijriMonth
        ..hDay = 1;

      final firstGreg = firstHijri.hijriToGregorian(_hijriYear, _hijriMonth, 1);
      final daysInMonth = firstHijri.getDaysInMonth(_hijriYear, _hijriMonth);
      // Monday = 1, Sunday = 7
      final startWeekday = firstGreg.weekday;

      for (int i = 1; i < startWeekday; i++) {
        cells.add(_DayCell.empty());
      }
      for (int d = 1; d <= daysInMonth; d++) {
        final hDate = HijriCalendar()
          ..hYear = _hijriYear
          ..hMonth = _hijriMonth
          ..hDay = d;

        // pass ints, never the HijriCalendar object
        final gDate = HijriCalendar().hijriToGregorian(
          _hijriYear,
          _hijriMonth,
          d,
        );

        final events = _eventsForHijriDate(_hijriMonth, d);
        cells.add(
          _DayCell(
            gregorian: gDate,
            hijri: hDate,
            events: events,
            isToday: _isSameGregorianDay(gDate, DateTime.now()),
          ),
        );
      }
      while (cells.length % 7 != 0) {
        cells.add(_DayCell.empty());
      }
    }
    return cells;
  }

  bool _isSameGregorianDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<IslamicEvent> _eventsForHijriDate(int month, int day) {
    return _allEvents
        .where((e) => e.hijriMonth == month && e.hijriDay == day)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  //  Navigation
  // ─────────────────────────────────────────────────────────────
  void _previousMonth() {
    setState(() {
      if (_mode == CalendarMode.hijri) {
        if (_hijriMonth == 1) {
          _hijriMonth = 12;
          _hijriYear--;
        } else {
          _hijriMonth--;
        }
      } else {
        if (_gregMonth == 1) {
          _gregMonth = 12;
          _gregYear--;
        } else {
          _gregMonth--;
        }
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_mode == CalendarMode.hijri) {
        if (_hijriMonth == 12) {
          _hijriMonth = 1;
          _hijriYear++;
        } else {
          _hijriMonth++;
        }
      } else {
        if (_gregMonth == 12) {
          _gregMonth = 1;
          _gregYear++;
        } else {
          _gregMonth++;
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  Styling helpers
  // ─────────────────────────────────────────────────────────────
  Color _eventColor(EventType type) {
    switch (type) {
      case EventType.festival:
        return const Color(0xFF0F3D26);
      case EventType.fasting:
        return const Color(0xFF8D6E63);
      case EventType.mourning:
        return const Color(0xFF5D4037);
      case EventType.historical:
        return const Color(0xFF6D4C41);
      case EventType.general:
        return const Color(0xFF78909C);
    }
  }

  IconData _eventIcon(EventType type) {
    switch (type) {
      case EventType.festival:
        return Icons.celebration;
      case EventType.fasting:
        return Icons.nights_stay;
      case EventType.mourning:
        return Icons.favorite_border;
      case EventType.historical:
        return Icons.history_edu;
      case EventType.general:
        return Icons.event;
    }
  }

  String _eventTypeLabel(EventType type) {
    switch (type) {
      case EventType.festival:
        return 'Festival';
      case EventType.fasting:
        return 'Fasting';
      case EventType.mourning:
        return 'Mourning';
      case EventType.historical:
        return 'Historical';
      case EventType.general:
        return 'General';
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Popup: details of a tapped day
  // ─────────────────────────────────────────────────────────────
  void _showDayDetails(_DayCell cell) {
    if (cell.isEmpty) return;

    final hijriStr =
        '${cell.hijri!.hDay} ${_hijriMonths[cell.hijri!.hMonth - 1]} ${cell.hijri!.hYear} AH';
    final gregStr = DateFormat.yMMMMd().format(cell.gregorian!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      backgroundColor: const Color(0xFFFBF8F1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3D26),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${cell.hijri!.hDay}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE2B76C),
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hijriStr,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textScaler: TextScaler.linear(1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _hijriMonthsArabic[cell.hijri!.hMonth - 1],
                            style: GoogleFonts.amiri(
                              fontSize: 14,
                              color: const Color(0xFF8D6E63),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gregStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cell.isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2B76C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'TODAY',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Events
                if (cell.events.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 36,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No major Islamic event on this day',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...cell.events.map((e) {
                    final color = _eventColor(e.type);
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_eventIcon(e.type), size: 16, color: color),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _eventTypeLabel(e.type).toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (e.isHoliday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE2B76C,
                                    ).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'HOLIDAY',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF8D6E63),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.description,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _EventHistory(
                            wikiEn: e.wikiEn,
                            wikiUr: e.wikiUr,
                            accent: _CalColors.primary,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Event list under the grid (fills the rest of the screen)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMonthEvents(List<_DayCell> cells) {
    final items = <MapEntry<_DayCell, IslamicEvent>>[];
    for (final c in cells) {
      if (c.isEmpty) continue;
      for (final e in c.events) {
        items.add(MapEntry(c, e));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EVENTS THIS MONTH',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8D6E63),
            ),
            textScaler: TextScaler.linear(1),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'No major Islamic events this month',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            ...items.map((entry) {
              final cell = entry.key;
              final e = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showDayDetails(cell),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _CalColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${cell.hijri!.hDay}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textScaler: TextScaler.linear(1),
                                ),
                                Text(
                                  DateFormat.MMM().format(cell.gregorian!),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cell.hijri!.hDay} ${_hijriMonths[cell.hijri!.hMonth - 1]} · ${DateFormat.yMMMd().format(cell.gregorian!)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: _CalColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cells = _buildMonthGrid();
    final today = HijriCalendar.now();

    final title = _mode == CalendarMode.hijri
        ? '${_hijriMonths[_hijriMonth - 1]} $_hijriYear'
        : DateFormat.yMMMM().format(DateTime(_gregYear, _gregMonth));

    final subtitle = _mode == CalendarMode.hijri
        ? _hijriMonthsArabic[_hijriMonth - 1]
        : _hijriRangeLabel(cells);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Islamic Calendar',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Today banner ──
          Container(
            margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3D26), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2B76C).withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${today.hDay}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE2B76C),
                      ),
                      textScaler: TextScaler.linear(1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white60,
                        ),
                        textScaler: TextScaler.linear(1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${today.hDay} ${_hijriMonths[today.hMonth - 1]} ${today.hYear} AH',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textScaler: TextScaler.linear(1),
                      ),
                    ],
                  ),
                ),
                // Calendar mode dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CalendarMode>(
                      value: _mode,
                      dropdownColor: const Color(0xFF0F3D26),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: CalendarMode.hijri,
                          child: Text(
                            'Hijri',
                            textScaler: TextScaler.linear(1),
                          ),
                        ),
                        DropdownMenuItem(
                          value: CalendarMode.gregorian,
                          child: Text(
                            'Gregorian',
                            textScaler: TextScaler.linear(1),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          if (v == CalendarMode.gregorian) {
                            final g = _gregorianAnchorForHijri();
                            _gregYear = g.year;
                            _gregMonth = g.month;
                          } else {
                            final h = HijriCalendar.fromDate(
                              DateTime(_gregYear, _gregMonth, 15),
                            );
                            _hijriYear = h.hYear;
                            _hijriMonth = h.hMonth;
                          }
                          _mode = v;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Month header with navigation ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _previousMonth,
                          icon: const Icon(Icons.chevron_left),
                          color: const Color(0xFF0F3D26),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _mode == CalendarMode.hijri
                                    ? GoogleFonts.amiri(
                                        fontSize: 14,
                                        color: const Color(0xFF8D6E63),
                                      )
                                    : GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF8D6E63),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(Icons.chevron_right),
                          color: const Color(0xFF0F3D26),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Weekday header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: const [
                        _WeekdayHeader('Mon'),
                        _WeekdayHeader('Tue'),
                        _WeekdayHeader('Wed'),
                        _WeekdayHeader('Thu'),
                        _WeekdayHeader('Fri'),
                        _WeekdayHeader('Sat'),
                        _WeekdayHeader('Sun'),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),

                  // ── Calendar grid ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: _CalendarGrid(
                      cells: cells,
                      mode: _mode,
                      hijriMonths: _hijriMonths,
                      rowHeight: _kTileHeight,
                      onDayTap: _showDayDetails,
                      eventColor: _eventColor,
                    ),
                  ),

                  // ── Events in this month ──
                  _buildMonthEvents(cells),
                  SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Calendar grid widget
// ═══════════════════════════════════════════════════════════════
class _CalendarGrid extends StatelessWidget {
  final List<_DayCell> cells;
  final CalendarMode mode;
  final List<String> hijriMonths;
  final double rowHeight;
  final void Function(_DayCell) onDayTap;
  final Color Function(EventType) eventColor;

  const _CalendarGrid({
    required this.cells,
    required this.mode,
    required this.hijriMonths,
    required this.rowHeight,
    required this.onDayTap,
    required this.eventColor,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, i + 7);
      rows.add(
        SizedBox(
          height: rowHeight,
          child: Row(
            children: week
                .map(
                  (c) => Expanded(
                    child: _DayTile(
                      cell: c,
                      mode: mode,
                      hijriMonths: hijriMonths,
                      onTap: () => onDayTap(c),
                      eventColor: eventColor,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ═══════════════════════════════════════════════════════════════
//  Single day tile
// ═══════════════════════════════════════════════════════════════
class _DayTile extends StatelessWidget {
  final _DayCell cell;
  final CalendarMode mode;
  final List<String> hijriMonths;
  final VoidCallback onTap;
  final Color Function(EventType) eventColor;

  const _DayTile({
    required this.cell,
    required this.mode,
    required this.hijriMonths,
    required this.onTap,
    required this.eventColor,
  });

  @override
  Widget build(BuildContext context) {
    if (cell.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasEvents = cell.events.isNotEmpty;
    // Event days are filled with the app's primary colour.
    final bigColor = hasEvents ? Colors.white : Colors.black87;
    final smallColor = hasEvents ? Colors.white70 : Colors.grey.shade500;

    // Big number = the currently selected calendar's day
    final bigNumber = mode == CalendarMode.hijri
        ? '${cell.hijri!.hDay}'
        : '${cell.gregorian!.day}';

    // Small number = the other calendar's day
    final smallNumber = mode == CalendarMode.hijri
        ? '${cell.gregorian!.day}'
        : '${cell.hijri!.hDay}';

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: hasEvents ? _CalColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cell.isToday
                      ? const Color(0xFFE2B76C)
                      : hasEvents
                      ? _CalColors.primaryDark
                      : Colors.grey.shade200,
                  width: cell.isToday ? 1.8 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bigNumber,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: hasEvents
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: bigColor,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                        Text(
                          smallNumber,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: smallColor,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                      ],
                    ),
                  ),

                  // Event dot(s)
                  if (hasEvents)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: cell.events.take(3).map((e) {
                          return Container(
                            margin: const EdgeInsets.only(left: 2),
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Today badge
                  if (cell.isToday)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2B76C),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Weekday header cell
// ═══════════════════════════════════════════════════════════════
class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: const Color(0xFF8D6E63),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Day cell data model
// ═══════════════════════════════════════════════════════════════
class _DayCell {
  final DateTime? gregorian;
  final HijriCalendar? hijri;
  final List<IslamicEvent> events;
  final bool isToday;
  final bool isEmpty;

  const _DayCell({
    this.gregorian,
    this.hijri,
    this.events = const [],
    this.isToday = false,
    this.isEmpty = false,
  });

  const _DayCell.empty()
    : gregorian = null,
      hijri = null,
      events = const [],
      isToday = false,
      isEmpty = true;
}

// ═══════════════════════════════════════════════════════════════
//  Short history from Wikipedia (free REST API, no key needed)
// ═══════════════════════════════════════════════════════════════
class _WikiInfo {
  final String title;
  final String extract;
  const _WikiInfo(this.title, this.extract);
}

class _EventHistory extends StatefulWidget {
  final String wikiEn;
  final String wikiUr;
  final Color accent;

  const _EventHistory({
    required this.wikiEn,
    required this.wikiUr,
    required this.accent,
  });

  @override
  State<_EventHistory> createState() => _EventHistoryState();
}

class _EventHistoryState extends State<_EventHistory> {
  static final Map<String, _WikiInfo?> _cacheEn = {};
  static final Map<String, _WikiInfo?> _cacheUr = {};

  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'QuranPak/1.0 (Islamic calendar app)',
  };

  late Future<_WikiInfo?> _futureEn;
  late Future<_WikiInfo?> _futureUr;

  @override
  void initState() {
    super.initState();
    _futureEn = _load(lang: 'en', title: widget.wikiEn, cache: _cacheEn);
    _futureUr = _load(lang: 'ur', title: widget.wikiUr, cache: _cacheUr);
  }

  String _shorten(String text, {int max = 480}) {
    final t = text.trim();
    if (t.length <= max) return t;
    final cut = t.substring(0, max);
    final i = cut.lastIndexOf('. ');
    return i > 120 ? cut.substring(0, i + 1) : '${cut.trimRight()}…';
  }

  Future<_WikiInfo?> _load({
    required String lang,
    required String title,
    required Map<String, _WikiInfo?> cache,
  }) async {
    if (title.trim().isEmpty) return null;
    if (cache.containsKey(title)) return cache[title];

    try {
      final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final uri = Uri.parse(
        'https://$lang.wikipedia.org/api/rest_v1/page/summary/$encoded',
      );
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        cache[title] = null;
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      // Skip disambiguation pages
      if ((json['type'] as String?) == 'disambiguation') {
        cache[title] = null;
        return null;
      }
      final extract = (json['extract'] as String?) ?? '';
      if (extract.isEmpty) {
        cache[title] = null;
        return null;
      }
      final info = _WikiInfo(
        (json['title'] as String?) ?? title,
        _shorten(extract),
      );
      cache[title] = info;
      return info;
    } catch (_) {
      cache[title] = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(Icons.history_edu, size: 14, color: widget.accent),
              const SizedBox(width: 6),
              Text(
                'SHORT HISTORY',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: widget.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── English ──
          FutureBuilder<_WikiInfo?>(
            future: _futureEn,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return _loadingRow(widget.accent, 'Loading English…');
              }
              if (snap.data == null) {
                return Text(
                  'English summary unavailable.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snap.data!.extract,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.55,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),

          // ── Urdu ──
          FutureBuilder<_WikiInfo?>(
            future: _futureUr,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return _loadingRow(widget.accent, 'اردو خلاصہ لوڈ ہو رہا ہے…');
              }
              if (snap.data == null) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'اردو خلاصہ دستیاب نہیں۔',
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 12,
                      height: 2.0,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snap.data!.extract,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 12.5,
                        height: 2.2,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _loadingRow(Color accent, String label) {
    return Row(
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: accent),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
