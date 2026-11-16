# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase & Firestore
-keepattributes *Annotation*,Signature,EnclosingMethod
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.protobuf.** { *; }

# App Models & Package
-keep class com.rustinnovations.fiqah.** { *; }
-keep class * implements java.io.Serializable { *; }

# SQLite / Sqflite
-keep class sqflite.** { *; }
-keep class com.tekartik.sqflite.** { *; }
