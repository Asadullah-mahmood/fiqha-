final _diacritics = RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

const _charMap = <String, String>{
  'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا',
  'ى': 'ي', 'ی': 'ي', 'ې': 'ي', 'ئ': 'ي', 'ے': 'ي',
  'ك': 'ك', 'ک': 'ك',
  'ة': 'ه', 'ۃ': 'ه', 'ہ': 'ه', 'ھ': 'ه', 'ۂ': 'ه',
  'ؤ': 'و',
};

String normalizeText(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    sb.write(_charMap[ch] ?? ch);
  }
  return sb
      .toString()
      .replaceAll(_diacritics, '')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// Each group = words that mean the same topic across languages.
const _topicGroups = <List<String>>[
  ['namaz', 'salah', 'salat', 'salaah', 'prayer', 'نماز', 'صلاة'],
  ['roza', 'sawm', 'siyam', 'fasting', 'روزہ', 'صوم', 'صيام'],
  ['zakat', 'zakah', 'زکوٰۃ', 'زكاة'],
  ['hajj', 'pilgrimage', 'حج'],
  ['wudu', 'wuzu', 'ablution', 'وضو', 'وضوء'],
  ['nikah', 'marriage', 'نکاح', 'نكاح'],
  ['talaq', 'divorce', 'طلاق'],
  ['sadaqah', 'sadaqa', 'charity', 'صدقہ', 'صدقة'],
  ['quran', 'قرآن', 'القرآن'],
  ['jannah', 'paradise', 'جنت', 'الجنة'],
  ['jahannam', 'hellfire', 'جہنم', 'النار'],
  ['sabr', 'patience', 'صبر'],
  ['jihad', 'جہاد', 'جهاد'],
  ['dua', 'supplication', 'دعا', 'دعاء'],
];

final List<Set<String>> _normGroups = _topicGroups
    .map((g) => g.map(normalizeText).toSet())
    .toList();

class SearchQuery {
  final String where;
  final List<Object?> args;
  SearchQuery(this.where, this.args);
}

SearchQuery? buildSearchQuery(String raw) {
  final tokens = normalizeText(raw)
      .replaceAll('%', '')
      .replaceAll('_', '')
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;

  final parts = <String>[];
  final args = <Object?>[];
  for (final token in tokens) {
    final terms = <String>{token};
    for (final g in _normGroups) {
      if (g.contains(token)) terms.addAll(g);
    }
    final clause = terms
        .map((_) => '(ar_norm LIKE ? OR ur_norm LIKE ? OR en_norm LIKE ?)')
        .join(' OR ');
    parts.add('($clause)');
    for (final t in terms) {
      args.addAll(['%$t%', '%$t%', '%$t%']);
    }
  }
  return SearchQuery(parts.join(' AND '), args);
}