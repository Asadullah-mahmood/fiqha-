// import 'package:flutter/material.dart';
// import 'package:quranpak/utils/AppTheme.dart';
//
// class VoiceSearchSheet extends StatefulWidget {
//   final Function(String surahName, int? ayahNumber) onResult;
//
//   const VoiceSearchSheet({super.key, required this.onResult});
//
//   @override
//   State<VoiceSearchSheet> createState() => _VoiceSearchSheetState();
// }
//
// class _VoiceSearchSheetState extends State<VoiceSearchSheet>
//     with SingleTickerProviderStateMixin {
//   final stt.SpeechToText _speech = stt.SpeechToText();
//   bool _isListening = false;
//   bool _speechAvailable = false;
//   String _recognizedText = '';
//   String _statusText = 'آواز سے تلاش کریں';
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     )..repeat(reverse: true);
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//     _pulseController.stop();
//     _initSpeech();
//   }
//
//   Future<void> _initSpeech() async {
//     _speechAvailable = await _speech.initialize(
//       onStatus: (status) {
//         if (status == 'done' || status == 'notListening') {
//           _stopListening();
//         }
//       },
//       onError: (error) {
//         setState(() {
//           _statusText = 'خطا: ${error.errorMsg}';
//           _isListening = false;
//         });
//         _pulseController.stop();
//       },
//     );
//     setState(() {});
//   }
//
//   Future<void> _startListening() async {
//     if (!_speechAvailable) return;
//     setState(() {
//       _isListening = true;
//       _recognizedText = '';
//       _statusText = 'سن رہا ہوں...';
//     });
//     _pulseController.repeat(reverse: true);
//
//     await _speech.listen(
//       onResult: (result) {
//         setState(() {
//           _recognizedText = result.recognizedWords;
//         });
//         if (result.finalResult) {
//           _processResult(result.recognizedWords);
//         }
//       },
//       listenFor: const Duration(seconds: 10),
//       pauseFor: const Duration(seconds: 3),
//       localeId: 'en_US',
//     );
//   }
//
//   void _stopListening() {
//     _speech.stop();
//     _pulseController.stop();
//     setState(() {
//       _isListening = false;
//       _statusText = _recognizedText.isEmpty ? 'کوئی آواز نہیں ملی' : 'مل گیا!';
//     });
//   }
//
//   void _processResult(String text) {
//     _stopListening();
//     if (text.isEmpty) return;
//
//     // Parse "Surah Al-Fatiha verse 1" or "Al Baqarah ayah 5" etc.
//     final lower = text.toLowerCase();
//     String surahName = text;
//     int? ayahNum;
//
//     // Extract verse/ayah number
//     final versePatterns = [
//       RegExp(r'verse\s+(\d+)', caseSensitive: false),
//       RegExp(r'ayah\s+(\d+)', caseSensitive: false),
//       RegExp(r'ayat\s+(\d+)', caseSensitive: false),
//       RegExp(r'آیت\s+(\d+)'),
//       RegExp(r'(\d+)\s*(?:verse|ayah|ayat)'),
//     ];
//
//     for (final pattern in versePatterns) {
//       final match = pattern.firstMatch(lower);
//       if (match != null) {
//         ayahNum = int.tryParse(match.group(1) ?? '');
//         surahName = text
//             .replaceAll(RegExp(r'verse\s+\d+', caseSensitive: false), '')
//             .replaceAll(RegExp(r'ayah\s+\d+', caseSensitive: false), '')
//             .replaceAll(RegExp(r'ayat\s+\d+', caseSensitive: false), '')
//             .replaceAll(RegExp(r'surah\s+', caseSensitive: false), '')
//             .replaceAll(RegExp(r'al-?', caseSensitive: false), '')
//             .trim();
//         break;
//       }
//     }
//
//     widget.onResult(surahName, ayahNum);
//     if (mounted) Navigator.pop(context);
//   }
//
//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _speech.stop();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Handle bar
//           Container(
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const SizedBox(height: 24),
//
//           // Title
//           const Text(
//             'آواز سے تلاش کریں',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.primary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'مثال: "Surah Al-Fatiha verse 1"',
//             style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
//           ),
//           const SizedBox(height: 32),
//
//           // Mic button with pulse animation
//           AnimatedBuilder(
//             animation: _pulseAnimation,
//             builder: (context, child) {
//               return Transform.scale(
//                 scale: _isListening ? _pulseAnimation.value : 1.0,
//                 child: GestureDetector(
//                   onTap: _isListening ? _stopListening : _startListening,
//                   child: Container(
//                     width: 90,
//                     height: 90,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: _isListening
//                           ? Colors.red.shade400
//                           : AppTheme.primary,
//                       boxShadow: [
//                         BoxShadow(
//                           color: (_isListening ? Colors.red : AppTheme.primary)
//                               .withOpacity(0.4),
//                           blurRadius: 20,
//                           spreadRadius: 4,
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       _isListening ? Icons.stop : Icons.mic,
//                       color: Colors.white,
//                       size: 40,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           const SizedBox(height: 20),
//
//           Text(
//             _statusText,
//             style: TextStyle(
//               fontSize: 15,
//               color: _isListening ? Colors.red.shade600 : AppTheme.textSecondary,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//
//           const SizedBox(height: 12),
//
//           if (_recognizedText.isNotEmpty) ...[
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: AppTheme.primary.withOpacity(0.06),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
//               ),
//               child: Text(
//                 '"$_recognizedText"',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: AppTheme.primary,
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ),
//           ] else if (!_isListening) ...[
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Text(
//                 'مائیک کا بٹن دبائیں اور سورت یا آیت کا نام بولیں',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
//               ),
//             ),
//           ],
//
//           const SizedBox(height: 24),
//
//           // Examples
//           const Text('مثالیں:', style: TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 6,
//             alignment: WrapAlignment.center,
//             children: [
//               _exampleChip('Al Fatiha verse 1'),
//               _exampleChip('Baqarah ayah 255'),
//               _exampleChip('Surah Yasin'),
//               _exampleChip('Rahman'),
//             ],
//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }
//
//   Widget _exampleChip(String text) {
//     return GestureDetector(
//       onTap: () => _processResult(text),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: AppTheme.gold.withOpacity(0.15),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(fontSize: 12, color: AppTheme.primary),
//         ),
//       ),
//     );
//   }
// }