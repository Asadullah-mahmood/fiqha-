import '../models/StaticDua.dart';

class IslamicDuasData {
  // ═══════════════════════════════════════════════════════════
  // 6 KALIMAS
  // ═══════════════════════════════════════════════════════════
  static const List<StaticDua> kalimas = [
    StaticDua(
      id: 'kalima_1',
      title: '1. Kalima Tayyab (The Pure Word)',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ',
      transliteration: "La ilaha illallahu Muhammadur Rasulullah",
      english: 'There is no god but Allah, Muhammad is the Messenger of Allah.',
      reference: 'First Kalima',
    ),
    StaticDua(
      id: 'kalima_2',
      title: '2. Kalima Shahadat (The Testimony)',
      arabic: 'أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration: "Ash-hadu an la ilaha illallahu wahdahu la sharika lahu wa ash-hadu anna Muhammadan 'abduhu wa rasuluh",
      english: 'I bear witness that there is no god but Allah, He is One and has no partner, and I bear witness that Muhammad is His servant and Messenger.',
      reference: 'Second Kalima',
    ),
    StaticDua(
      id: 'kalima_3',
      title: '3. Kalima Tamjeed (The Glorification)',
      arabic: 'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      transliteration: "Subhanallahi walhamdulillahi wa la ilaha illallahu wallahu akbar, wa la hawla wa la quwwata illa billahil-'aliyyil-'azim",
      english: 'Glory be to Allah, all praise is for Allah, there is no god but Allah, Allah is the Greatest, and there is no power or might except with Allah, the Most High, the Most Great.',
      reference: 'Third Kalima',
    ),
    StaticDua(
      id: 'kalima_4',
      title: '4. Kalima Tawheed (The Unity)',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيِي وَيُمِيتُ وَهُوَ حَيٌّ لَا يَمُوتُ أَبَدًا أَبَدًا ذُو الْجَلَالِ وَالْإِكْرَامِ بِيَدِهِ الْخَيْرُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration: "La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu, yuhyi wa yumitu, wa huwa hayyun la yamutu abadan abadan, dhul-jalali wal-ikram, biyadihil-khayr, wa huwa 'ala kulli shay'in qadir",
      english: 'There is no god but Allah, He is One, He has no partner. His is the dominion and His is the praise. He gives life and death, He is Ever-Living and never dies. He is the Lord of Majesty and Honour. In His hand is all good, and He has power over all things.',
      reference: 'Fourth Kalima',
    ),
    StaticDua(
      id: 'kalima_5',
      title: '5. Kalima Astaghfar (The Seeking of Forgiveness)',
      arabic: 'أَسْتَغْفِرُ اللَّهَ رَبِّي مِنْ كُلِّ ذَنْبٍ أَذْنَبْتُهُ عَمْدًا أَوْ خَطَأً سِرًّا أَوْ عَلَانِيَةً وَأَتُوبُ إِلَيْهِ مِنَ الذَّنْبِ الَّذِي أَعْلَمُ وَمِنَ الذَّنْبِ الَّذِي لَا أَعْلَمُ إِنَّكَ أَنْتَ عَلَّامُ الْغُيُوبِ وَسَتَّارُ الْعُيُوبِ وَغَفَّارُ الذُّنُوبِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      transliteration: "Astaghfirullaha rabbi min kulli dhambin adhnabtuhu 'amdan aw khata'an sirran aw 'alaniyatan wa atubu ilayhi min adh-dhanbil-ladhi a'lamu wa min adh-dhanbil-ladhi la a'lamu innaka anta 'allamul-ghuyub wa sattarul-'uyub wa ghaffarudh-dhunub wa la hawla wa la quwwata illa billahil-'aliyyil-'azim",
      english: 'I seek forgiveness from Allah, my Lord, from every sin I committed knowingly or unknowingly, secretly or openly. I turn to Him from the sin I know and the sin I do not know. Indeed, You are the Knower of hidden things, the Concealer of faults, the Forgiver of sins. And there is no power or might except with Allah, the Most High, the Most Great.',
      reference: 'Fifth Kalima',
    ),
    StaticDua(
      id: 'kalima_6',
      title: '6. Kalima Radde Kufr (The Rejection of Disbelief)',
      arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ أَنْ أُشْرِكَ بِكَ شَيْئًا وَأَنَا أَعْلَمُ بِهِ وَأَسْتَغْفِرُكَ لِمَا لَا أَعْلَمُ بِهِ تُبْتُ عَنْهُ وَتَبَرَّأْتُ مِنَ الْكُفْرِ وَالشِّرْكِ وَالْكِذْبِ وَالْغِيبَةِ وَالْبِدْعَةِ وَالنَّمِيمَةِ وَالْفَوَاحِشِ وَالْبُهْتَانِ وَالْمَعَاصِي كُلِّهَا وَأَسْلَمْتُ وَأَقُولُ لَا إِلَٰهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ',
      transliteration: "Allahumma inni a'udhu bika min an ushrika bika shay'an wa ana a'lamu bihi wa astaghfiruka lima la a'lamu bihi tubtu 'anhu wa tabarra'tu minal-kufri wash-shirki wal-kidhbi wal-ghibati wal-bid'ati wan-namimati wal-fawahishi wal-buhtani wal-ma'asi kulliha wa aslamtu wa aqulu la ilaha illallahu Muhammadur Rasulullah",
      english: 'O Allah, I seek refuge in You from knowingly associating anything with You, and I seek Your forgiveness for what I do not know. I repent from it, and I disassociate myself from disbelief, polytheism, lying, backbiting, innovation, slander, indecency, false accusation, and all sins. I submit, and I say: There is no god but Allah, Muhammad is the Messenger of Allah.',
      reference: 'Sixth Kalima',
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // BASIC EVERYDAY DUAS
  // ═══════════════════════════════════════════════════════════
  static const List<StaticDua> basicDuas = [
    StaticDua(
      id: 'wake_up',
      title: 'Waking Up',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      transliteration: "Alhamdulillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
      english: 'All praise is for Allah who gave us life after death, and unto Him is the resurrection.',
      reference: 'Bukhari 6312',
    ),
    StaticDua(
      id: 'before_eating',
      title: 'Before Eating',
      arabic: 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
      transliteration: "Bismillahi wa 'ala barakatillah",
      english: 'In the name of Allah and with the blessings of Allah.',
      reference: 'Abu Dawud 3767',
    ),
    StaticDua(
      id: 'after_eating',
      title: 'After Eating',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
      transliteration: "Alhamdulillahil-ladhi at'amana wa saqana wa ja'alana muslimin",
      english: 'All praise is for Allah who fed us, gave us drink, and made us Muslims.',
      reference: 'Abu Dawud 3850',
    ),
    StaticDua(
      id: 'leaving_home',
      title: 'Leaving Home',
      arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration: "Bismillahi tawakkaltu 'alallahi wa la hawla wa la quwwata illa billah",
      english: 'In the name of Allah, I place my trust in Allah. There is no power or might except with Allah.',
      reference: 'Abu Dawud 5095',
    ),
    StaticDua(
      id: 'entering_home',
      title: 'Entering Home',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ',
      transliteration: "Allahumma inni as'aluka khayral-mawliji wa khayral-makhraji",
      english: 'O Allah, I ask You for the best entering and the best exiting.',
      reference: 'Abu Dawud 5096',
    ),
    StaticDua(
      id: 'before_sleep',
      title: 'Before Sleeping',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      transliteration: "Bismika Allahumma amutu wa ahya",
      english: 'In Your name, O Allah, I die and I live.',
      reference: 'Bukhari 6324',
    ),
    StaticDua(
      id: 'entering_mosque',
      title: 'Entering the Mosque',
      arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      transliteration: "Allahumma-ftah li abwaba rahmatik",
      english: 'O Allah, open the gates of Your mercy for me.',
      reference: 'Muslim 713',
    ),
    StaticDua(
      id: 'leaving_mosque',
      title: 'Leaving the Mosque',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      transliteration: "Allahumma inni as'aluka min fadlik",
      english: 'O Allah, I ask You from Your bounty.',
      reference: 'Muslim 713',
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // NAMAZ (SALAH) DUAS
  // ═══════════════════════════════════════════════════════════
  static const List<StaticDua> namazDuas = [
    StaticDua(
      id: 'sana',
      title: 'Sana (Opening Praise)',
      arabic: 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَٰهَ غَيْرُكَ',
      transliteration: "Subhanakallahumma wa bihamdika wa tabarakasmuka wa ta'ala jadduka wa la ilaha ghayruk",
      english: 'Glory be to You, O Allah, and praise be to You. Blessed is Your name and exalted is Your majesty. There is no god besides You.',
      reference: 'Abu Dawud 775',
    ),
    StaticDua(
      id: 'ruku',
      title: 'Ruku (Bowing)',
      arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      transliteration: "Subhana Rabbiyal-'Azim",
      english: 'Glory be to my Lord, the Most Great.',
      reference: 'Muslim 772',
    ),
    StaticDua(
      id: 'rising_from_ruku',
      title: 'Rising from Ruku',
      arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ، رَبَّنَا وَلَكَ الْحَمْدُ',
      transliteration: "Sami'allahu liman hamidah, Rabbana wa lakal-hamd",
      english: 'Allah hears the one who praises Him. Our Lord, to You belongs all praise.',
      reference: 'Bukhari 796',
    ),
    StaticDua(
      id: 'sujud',
      title: 'Sujud (Prostration)',
      arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: "Subhana Rabbiyal-A'la",
      english: 'Glory be to my Lord, the Most High.',
      reference: 'Muslim 772',
    ),
    StaticDua(
      id: 'jalsa',
      title: 'Between Two Sujuds',
      arabic: 'رَبِّ اغْفِرْ لِي',
      transliteration: "Rabbighfir li",
      english: 'My Lord, forgive me.',
      reference: 'Abu Dawud 874',
    ),
    StaticDua(
      id: 'tashahhud',
      title: 'Tashahhud (At-Tahiyyat)',
      arabic: 'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration: "At-tahiyyatu lillahi was-salawatu wat-tayyibat, as-salamu 'alayka ayyuhan-Nabiyyu wa rahmatullahi wa barakatuh, as-salamu 'alayna wa 'ala 'ibadillahis-salihin, ash-hadu an la ilaha illallahu wa ash-hadu anna Muhammadan 'abduhu wa rasuluh",
      english: 'All compliments, prayers and pure words are due to Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah, and I bear witness that Muhammad is His servant and Messenger.',
      reference: 'Bukhari 831',
    ),
    StaticDua(
      id: 'durood_ibrahim',
      title: 'Durood Ibrahim',
      arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      transliteration: "Allahumma salli 'ala Muhammadin wa 'ala aali Muhammadin kama sallayta 'ala Ibrahima wa 'ala aali Ibrahima innaka Hamidum-Majid. Allahumma barik 'ala Muhammadin wa 'ala aali Muhammadin kama barakta 'ala Ibrahima wa 'ala aali Ibrahima innaka Hamidum-Majid",
      english: 'O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim. Indeed, You are Praiseworthy, Most Glorious. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim. Indeed, You are Praiseworthy, Most Glorious.',
      reference: 'Bukhari 3370',
    ),
    StaticDua(
      id: 'dua_masura',
      title: 'Dua-e-Masura',
      arabic: 'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ وَارْحَمْنِي إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
      transliteration: "Allahumma inni zalamtu nafsi zulman kathiran wa la yaghfirudh-dhunuba illa anta faghfir li maghfiratan min 'indika warhamni innaka antal-Ghafurur-Rahim",
      english: 'O Allah, I have greatly wronged myself, and none forgives sins except You. So forgive me with a forgiveness from Yourself and have mercy on me. Indeed, You are the Forgiving, the Merciful.',
      reference: 'Bukhari 834',
    ),
    StaticDua(
      id: 'after_salam',
      title: 'After Salam (End of Prayer)',
      arabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration: "Allahumma antas-Salamu wa minkas-salam, tabarakta ya dhal-jalali wal-ikram",
      english: 'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of Majesty and Honour.',
      reference: 'Muslim 591',
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // JANAZA (FUNERAL) DUAS
  // ═══════════════════════════════════════════════════════════
  static const List<StaticDua> janazaDuas = [
    StaticDua(
      id: 'janaza_1',
      title: 'Janaza - Opening (Sana)',
      arabic: 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَٰهَ غَيْرُكَ',
      transliteration: "Subhanakallahumma wa bihamdika wa tabarakasmuka wa ta'ala jadduka wa la ilaha ghayruk",
      english: 'Glory be to You, O Allah, and praise be to You. Blessed is Your name and exalted is Your majesty. There is no god besides You.',
      reference: 'Janaza Prayer - First Takbir',
    ),
    StaticDua(
      id: 'janaza_2',
      title: 'Janaza - Durood Ibrahim',
      arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      transliteration: "Allahumma salli 'ala Muhammadin wa 'ala aali Muhammadin kama sallayta 'ala Ibrahima wa 'ala aali Ibrahima innaka Hamidum-Majid",
      english: 'O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim. Indeed, You are Praiseworthy, Most Glorious.',
      reference: 'Janaza Prayer - Second Takbir',
    ),
    StaticDua(
      id: 'janaza_3',
      title: 'Janaza - Dua for the Deceased',
      arabic: 'اللَّهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا وَشَاهِدِنَا وَغَائِبِنَا وَصَغِيرِنَا وَكَبِيرِنَا وَذَكَرِنَا وَأُنْثَانَا، اللَّهُمَّ مَنْ أَحْيَيْتَهُ مِنَّا فَأَحْيِهِ عَلَى الْإِسْلَامِ وَمَنْ تَوَفَّيْتَهُ مِنَّا فَتَوَفَّهُ عَلَى الْإِيمَانِ',
      transliteration: "Allahummaghfir lihayyina wa mayyitina wa shahidina wa gha'ibina wa saghirina wa kabirina wa dhakarina wa unthana. Allahumma man ahyaytahu minna fa-ahyihi 'alal-Islam, wa man tawaffaytahu minna fa-tawaffahu 'alal-iman",
      english: 'O Allah, forgive our living and our dead, those present and those absent, our young and our old, our males and our females. O Allah, whomever You keep alive among us, keep him alive upon Islam, and whomever You cause to die among us, cause him to die upon faith.',
      reference: 'Abu Dawud 3201',
    ),
    StaticDua(
      id: 'janaza_4',
      title: 'Janaza - For a Child',
      arabic: 'اللَّهُمَّ اجْعَلْهُ لَنَا سَلَفًا وَفَرَطًا وَذُخْرًا وَشَفِيعًا مُجَابًا',
      transliteration: "Allahummaj'alhu lana salafan wa faratan wa dhukhran wa shafi'an mujaban",
      english: 'O Allah, make him a predecessor, a forerunner, a treasure, and an accepted intercessor for us.',
      reference: 'For a deceased child',
    ),
    StaticDua(
      id: 'janaza_5',
      title: 'Janaza - After Burial',
      arabic: 'اللَّهُمَّ اغْفِرْ لَهُ وَارْفَعْ دَرَجَتَهُ فِي الْمَهْدِيِّينَ وَاخْلُفْهُ فِي عَقِبِهِ',
      transliteration: "Allahummaghfir lahu warfa' darajatahu fil-mahdiyyin wakhlufhu fi 'aqibihi",
      english: 'O Allah, forgive him and raise his rank among the rightly guided, and be a successor to his family.',
      reference: 'Muslim 920',
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // SPECIAL RECITATIONS
  // ═══════════════════════════════════════════════════════════
  static const List<StaticDua> specialRecitations = [
    StaticDua(
      id: 'ayatul_kursi',
      title: 'Ayat-ul-Kursi',
      arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۚ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      transliteration: "Allahu la ilaha illa huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bishay'in min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard. Wa la ya'uduhu hifdhuhuma. Wa huwal-'Aliyyul-'Azim",
      english: 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.',
      reference: 'Surah Al-Baqarah 2:255',
      note: 'Reciting after every prayer and before sleep carries great reward.',
    ),
    StaticDua(
      id: 'dua_qunoot',
      title: 'Dua-e-Qunoot',
      arabic: 'اللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْرَ وَنَشْكُرُكَ وَلَا نَكْفُرُكَ وَنَخْلَعُ وَنَتْرُكُ مَنْ يَفْجُرُكَ، اللَّهُمَّ إِيَّاكَ نَعْبُدُ وَلَكَ نُصَلِّي وَنَسْجُدُ وَلَكَ نَسْعَى وَنَحْفِدُ وَنَرْجُو رَحْمَتَكَ وَنَخْشَى عَذَابَكَ إِنَّ عَذَابَكَ بِالْكُفَّارِ مُلْحِقٌ',
      transliteration: "Allahumma inna nasta'inuka wa nastaghfiruka wa nu'minu bika wa natawakkalu 'alayka wa nuthni 'alaykal-khayr, wa nashkuruka wa la nakfuruk, wa nakhla'u wa natruku man yafjuruk. Allahumma iyyaka na'budu wa laka nusalli wa nasjudu wa laka nas'a wa nahfidu wa narju rahmataka wa nakhsha 'adhabaka inna 'adhabaka bil-kuffari mulhiq",
      english: 'O Allah, we seek Your help and ask Your forgiveness, and we believe in You and rely on You, and we praise You with all good, and we thank You and we are not ungrateful to You. We disown and abandon the one who disobeys You. O Allah, You alone we worship, and to You we pray and prostrate, and for You we strive and toil, and we hope for Your mercy and we fear Your punishment. Surely Your punishment will overtake the disbelievers.',
      reference: 'Witr Prayer - Hanafi tradition',
    ),
    StaticDua(
      id: 'aman_rasool',
      title: 'Aman-ur-Rasool (Amana Rasul)',
      arabic: 'آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ ۚ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ. لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      transliteration: "Amanar-Rasulu bima unzila ilayhi mir-Rabbihi wal-mu'minun. Kullun amana billahi wa mala'ikatihi wa kutubihi wa rusulih. La nufarriqu bayna ahadin mir-rusulih. Wa qalu sami'na wa ata'na ghufranaka Rabbana wa ilaykal-masir. La yukallifullahu nafsan illa wus'aha. Laha ma kasabat wa 'alayha maktasabat. Rabbana la tu'akhidhna in nasina aw akhta'na. Rabbana wa la tahmil 'alayna isran kama hamaltahu 'alal-ladhina min qablina. Rabbana wa la tuhammilna ma la taqata lana bih. Wa'fu 'anna waghfir lana warhamna. Anta mawlana fansurna 'alal-qawmil-kafirin",
      english: 'The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All have believed in Allah and His angels and His books and His messengers, saying, "We make no distinction between any of His messengers." And they say, "We hear and we obey. We seek Your forgiveness, our Lord, and to You is the final destination." Allah does not burden a soul beyond that it can bear. It will have the good it has earned and bear the evil it has earned. Our Lord, do not take us to task if we forget or make a mistake. Our Lord, do not place upon us a burden like that which You placed on those before us. Our Lord, do not burden us with that which we have no strength to bear. Pardon us, forgive us, and have mercy on us. You are our Protector, so grant us victory over the disbelieving people.',
      reference: 'Surah Al-Baqarah 2:285-286',
      note: 'The last two verses of Surah Al-Baqarah — whoever recites them at night, they will suffice him.',
    ),
    StaticDua(
      id: 'surah_muzammil',
      title: 'Surah Al-Muzammil (First 20 Ayahs)',
      arabic: 'يَا أَيُّهَا الْمُزَّمِّلُ ۝ قُمِ اللَّيْلَ إِلَّا قَلِيلًا ۝ نِصْفَهُ أَوِ انْقُصْ مِنْهُ قَلِيلًا ۝ أَوْ زِدْ عَلَيْهِ وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا ۝ إِنَّا سَنُلْقِي عَلَيْكَ قَوْلًا ثَقِيلًا ۝ إِنَّ نَاشِئَةَ اللَّيْلِ هِيَ أَشَدُّ وَطْئًا وَأَقْوَمُ قِيلًا ۝ إِنَّ لَكَ فِي النَّهَارِ سَبْحًا طَوِيلًا ۝ وَاذْكُرِ اسْمَ رَبِّكَ وَتَبَتَّلْ إِلَيْهِ تَبْتِيلًا ۝ رَبُّ الْمَشْرِقِ وَالْمَغْرِبِ لَا إِلَٰهَ إِلَّا هُوَ فَاتَّخِذْهُ وَكِيلًا ۝ وَاصْبِرْ عَلَىٰ مَا يَقُولُونَ وَاهْجُرْهُمْ هَجْرًا جَمِيلًا ۝ وَذَرْنِي وَالْمُكَذِّبِينَ أُولِي النَّعْمَةِ وَمَهِّلْهُمْ قَلِيلًا ۝ إِنَّ لَدَيْنَا أَنْكَالًا وَجَحِيمًا ۝ وَطَعَامًا ذَا غُصَّةٍ وَعَذَابًا أَلِيمًا ۝ يَوْمَ تَرْجُفُ الْأَرْضُ وَالْجِبَالُ وَكَانَتِ الْجِبَالُ كَثِيبًا مَهِيلًا ۝ إِنَّا أَرْسَلْنَا إِلَيْكُمْ رَسُولًا شَاهِدًا عَلَيْكُمْ كَمَا أَرْسَلْنَا إِلَىٰ فِرْعَوْنَ رَسُولًا ۝ فَعَصَىٰ فِرْعَوْنُ الرَّسُولَ فَأَخَذْنَاهُ أَخْذًا وَبِيلًا ۝ فَكَيْفَ تَتَّقُونَ إِنْ كَفَرْتُمْ يَوْمًا يَجْعَلُ الْوِلْدَانَ شِيبًا ۝ السَّمَاءُ مُنْفَطِرٌ بِهِ ۚ كَانَ وَعْدُهُ مَفْعُولًا ۝ إِنَّ هَٰذِهِ تَذْكِرَةٌ ۖ فَمَنْ شَاءَ اتَّخَذَ إِلَىٰ رَبِّهِ سَبِيلًا',
      transliteration: "Ya ayyuhal-muzzammil. Qumil-layla illa qalila. Nisfahu awinqus minhu qalila. Aw zid 'alayhi wa rattilil-Qur'ana tartila. Inna sanulqi 'alayka qawlan thaqila. Inna nashi'atal-layli hiya ashaddu wat'an wa aqwamu qila. Inna laka fin-nahari sabhan tawila. Wadhkurisma Rabbika wa tabattal ilayhi tabtila. Rabbul-mashriqi wal-maghribi la ilaha illa huwa fattakhidhhu wakila. Wasbir 'ala ma yaquluna wahjurhum hajran jamila. Wa dharni wal-mukadhdhibina ulin-ni'mati wa mahhilhum qalila. Inna ladayna ankalal wa jahima. Wa ta'aman dha ghussatin wa 'adhaban alima. Yawma tarjuful-ardu wal-jibalu wa kanatil-jibalu kathiban mahila. Inna arsalna ilaykum rasulan shahidan 'alaykum kama arsalna ila Fir'awna rasula. Fa'asa Fir'awnur-Rasula fa-akhadhnahu akhdhan wabila. Fakayfa tattaquna inkafartum yawman yaj'alul-wildana shiba. As-sama'u munfatirun bih. Kana wa'duhu maf'ula. Inna hadhihi tadhkiratun faman sha'at-takhadha ila Rabbihi sabila",
      english: 'O you who wraps himself [in clothing], arise [to pray] the night, except for a little — half of it, or subtract from it a little, or add to it, and recite the Quran with measured recitation. Indeed, We will cast upon you a heavy word. Indeed, the hours of the night are more effective for concurrence [of heart and tongue] and more suitable for words. Indeed, for you by day is prolonged occupation. And remember the name of your Lord and devote yourself to Him with [complete] devotion. [He is] the Lord of the east and the west; there is no deity except Him, so take Him as Disposer of [your] affairs. And be patient over what they say and avoid them with gracious avoidance. And leave Me with [the matter of] the deniers, those of ease [in life], and allow them respite a little. Indeed, with Us [for them] are shackles and burning fire, and food that chokes and a painful punishment — on the Day the earth and the mountains will convulse, and the mountains will become a heap of sand pouring down. Indeed, We have sent to you a Messenger as a witness upon you just as We sent to Pharaoh a messenger. But Pharaoh disobeyed the messenger, so We seized him with a ruinous seizure. Then how can you fear, if you disbelieve, a Day that will make the children white-haired? The heaven will break apart therefrom; ever is His promise fulfilled. Indeed, this is a reminder, so whoever wills may take to his Lord a way.',
      reference: 'Surah Al-Muzammil 73:1-20',
      note: 'Reciting Surah Al-Muzammil brings peace and protection.',
    ),
  ];

  /// All sections grouped together for the Duas Hub screen.
  static List<MapEntry<String, List<StaticDua>>> get allSections => [
    const MapEntry('6 Kalimas', kalimas),
    const MapEntry('Basic Everyday Duas', basicDuas),
    const MapEntry('Namaz (Salah) Duas', namazDuas),
    const MapEntry('Janaza (Funeral) Duas', janazaDuas),
    const MapEntry('Special Recitations', specialRecitations),
  ];
}