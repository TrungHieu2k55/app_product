import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static bool get isConfigured => true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Ứng dụng hiện hỗ trợ Firebase Web và Android.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA1iXvBT21_e5YdJmog-OpwV11NsUAbjOQ',
    appId: '1:943483357686:web:5c876bb10e754369485fd7',
    messagingSenderId: '943483357686',
    projectId: 'giuaki2-23458',
    authDomain: 'giuaki2-23458.firebaseapp.com',
    databaseURL: 'https://giuaki2-23458-default-rtdb.firebaseio.com',
    storageBucket: 'giuaki2-23458.firebasestorage.app',
    measurementId: 'G-8GC57DHZ7H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjHag-n-YQzLEmbyvN8kPCRsthFt22rxs',
    appId: '1:943483357686:android:321272691a61b30b485fd7',
    messagingSenderId: '943483357686',
    projectId: 'giuaki2-23458',
    databaseURL: 'https://giuaki2-23458-default-rtdb.firebaseio.com',
    storageBucket: 'giuaki2-23458.firebasestorage.app',
  );
}
