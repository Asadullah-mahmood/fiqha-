class FullSurahReciter {
  final String id;
  final String name;
  final String arabicName;
  final String imageAsset;
  /// Returns the full-surah MP3 URL for a given surah number (1–114).
  final String Function(int surah) urlBuilder;
  /// Optional secondary fallback URL
  final String Function(int surah)? fallbackBuilder;

  const FullSurahReciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.imageAsset,
    required this.urlBuilder,
    this.fallbackBuilder,
  });
}

const List<FullSurahReciter> fullSurahReciters = [
  FullSurahReciter(
    id: 'alafasy_full',
    name: 'Mishary Alafasy',
    arabicName: 'مشاري العفاسي',
    imageAsset:
        'https://i.scdn.co/image/ab6761610000e5ebac381d07bb60d7bfd3be1fe0',
    urlBuilder: _alafasySurahUrl,
    fallbackBuilder: _alafasyFallbackUrl,
  ),
  FullSurahReciter(
    id: 'abdulbasit_full',
    name: 'Abdul Basit (Murattal)',
    arabicName: 'عبد الباسط',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRTHTDKqW2kyNGnF0fS_TBQM-o6JpK_1wqbJ0gYNf1nXg&s=10',
    urlBuilder: _abdulbasitSurahUrl,
    fallbackBuilder: _abdulbasitFallbackUrl,
  ),
  FullSurahReciter(
    id: 'sudais_full',
    name: 'Abdurrahman As-Sudais',
    arabicName: 'عبدالرحمن السديس',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTF0X-RQPnP6IuRq7K1kVbWN_1O5lDreVPHZrvZ9_r5Zg&s=10',
    urlBuilder: _sudaisSurahUrl,
    fallbackBuilder: _sudaisFallbackUrl,
  ),
  FullSurahReciter(
    id: 'shuraim_full',
    name: 'Saud Ash-Shuraim',
    arabicName: 'سعود الشريم',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQso56EZhqzvNqdJw5_NB6tOacRHLXLAfLyO3lgsBv5mA&s=10',
    urlBuilder: _shuraimSurahUrl,
    fallbackBuilder: _shuraimFallbackUrl,
  ),
  FullSurahReciter(
    id: 'minshawi_full',
    name: 'Al-Minshawi',
    arabicName: 'المنشاوي',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ78ExZjkfdOq7k87l4YvbYsZxfMGtR8OcrBRv__z74j0MRA_IlAYcYAjVq&s=10',
    urlBuilder: _minshawiSurahUrl,
    fallbackBuilder: _minshawiFallbackUrl,
  ),
  FullSurahReciter(
    id: 'husary_full',
    name: 'Mahmoud Khalil Al-Husary',
    arabicName: 'محمود خليل الحصري',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTABHOHVHBgVatFqGvS-1EN0q-swJMgMwfTZ5Y3D5CvHA&s=10',
    urlBuilder: _husarySurahUrl,
    fallbackBuilder: _husaryFallbackUrl,
  ),
  FullSurahReciter(
    id: 'shaatree_full',
    name: 'Abu Bakr Ash-Shaatree',
    arabicName: 'أبو بكر الشاطري',
    imageAsset:
        'https://quran.com/_next/image?url=https%3A%2F%2Fstatic.qurancdn.com%2Fimages%2Freciters%2F3%2Fabu-bakr-al-shatri-pofile.jpeg%3Fv%3D1&w=256&q=75',
    urlBuilder: _shaatreeSurahUrl,
    fallbackBuilder: _shaatreeFallbackUrl,
  ),
  FullSurahReciter(
    id: 'ajamy_full',
    name: 'Ahmed ibn Ali al-Ajamy',
    arabicName: 'أحمد بن علي العجمي',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTbPNu7gS843umNubyFl__FA97g-s-Vb5EmPIIdQPkdpg&s=10',
    urlBuilder: _ajamySurahUrl,
    fallbackBuilder: _ajamyFallbackUrl,
  ),
  FullSurahReciter(
    id: 'huzaify_full',
    name: 'Ali Al-Huzaify',
    arabicName: 'علي الحذيفي',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRH7kkWJvm_uJrP4j60-n4uREl0X_gqVTkCQrf-vqAHtA&s=10',
    urlBuilder: _huzaifySurahUrl,
    fallbackBuilder: _huzaifyFallbackUrl,
  ),
  FullSurahReciter(
    id: 'yasser_full',
    name: 'Yasser Ad-Dussary',
    arabicName: 'ياسر الدوسري',
    imageAsset:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQKyv4R9y3MZlbecOm1mSeNpd_kM9iFDsn0iiuor_X0Qg&s',
    urlBuilder: _yasserSurahUrl,
    fallbackBuilder: _yasserFallbackUrl,
  ),
];

// Helper to pad surah number to 3 digits (e.g. 001)
String _pad3(int s) => s.toString().padLeft(3, '0');

// Reliable high-speed CDNs (mp3quran CDN & Islamic Network)
String _alafasySurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/mishary-alafasy/r2/${_pad3(s)}.mp3';
String _alafasyFallbackUrl(int s) =>
    'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$s.mp3';

String _abdulbasitSurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/abdulbasit-abdulsamad/r3/${_pad3(s)}.mp3';
String _abdulbasitFallbackUrl(int s) =>
    'https://cdn.islamic.network/quran/audio-surah/128/ar.abdulbasitmurattal/$s.mp3';

String _sudaisSurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/abdulrahman-sudais/r1/${_pad3(s)}.mp3';
String _sudaisFallbackUrl(int s) =>
    'https://server11.mp3quran.net/sds/${_pad3(s)}.mp3';

String _shuraimSurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/saud-shuraim/r1/${_pad3(s)}.mp3';
String _shuraimFallbackUrl(int s) =>
    'https://server7.mp3quran.net/shur/${_pad3(s)}.mp3';

String _minshawiSurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/muhammad-minshawi/r4/${_pad3(s)}.mp3';
String _minshawiFallbackUrl(int s) =>
    'https://server10.mp3quran.net/minsh/${_pad3(s)}.mp3';

String _husarySurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/mahmoud-husary/r5/${_pad3(s)}.mp3';
String _husaryFallbackUrl(int s) =>
    'https://server13.mp3quran.net/husr/${_pad3(s)}.mp3';

String _shaatreeSurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/abubakr-shatri/r1/${_pad3(s)}.mp3';
String _shaatreeFallbackUrl(int s) =>
    'https://server11.mp3quran.net/shatri/${_pad3(s)}.mp3';

String _ajamySurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/ahmad-ajmi/r1/${_pad3(s)}.mp3';
String _ajamyFallbackUrl(int s) =>
    'https://server10.mp3quran.net/ajm/${_pad3(s)}.mp3';

String _huzaifySurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/ali-hudhaifi/r3/${_pad3(s)}.mp3';
String _huzaifyFallbackUrl(int s) =>
    'https://server9.mp3quran.net/hthfi/${_pad3(s)}.mp3';

String _yasserSurahUrl(int s) =>
    'https://cdn.mp3quran.net/audio/yasser-dosari/r1/${_pad3(s)}.mp3';
String _yasserFallbackUrl(int s) =>
    'https://server11.mp3quran.net/yasser/${_pad3(s)}.mp3';
