import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// يدير الدخول المجهول ويعيد المحاولة لو فشل (أول تشغيل بلا إنترنت).
/// بلا هذا، `signInAnonymously` يرمي استثناءً في main ويظهر التطبيق أسود.
class AuthController extends ChangeNotifier {
  String? _uid;
  bool _tryingSignIn = false;
  Timer? _retry;
  StreamSubscription<User?>? _sub;

  String? get uid => _uid;
  bool get signedIn => _uid != null;

  /// يُستدعى مرة عند الإقلاع. لا يرمي أبداً — الفشل يعني وضعاً محلياً مؤقتاً.
  Future<void> init() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final auth = FirebaseAuth.instance;
      _sub = auth.authStateChanges().listen((user) {
        final next = user?.uid;
        if (next != _uid) {
          _uid = next;
          notifyListeners();
        }
      });
      _uid = auth.currentUser?.uid;
      if (_uid == null) await _signIn();
    } catch (e) {
      debugPrint('Auth init failed: $e');
      _scheduleRetry();
    }
  }

  Future<void> _signIn() async {
    if (_tryingSignIn || _uid != null) return;
    _tryingSignIn = true;
    try {
      final cred = await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 12));
      _uid = cred.user?.uid;
      _retry?.cancel();
      notifyListeners();
    } catch (e) {
      debugPrint('Anonymous sign-in failed (offline?): $e');
      _scheduleRetry();
    } finally {
      _tryingSignIn = false;
    }
  }

  /// إعادة محاولة دورية — بمجرد عودة الشبكة تُربط البيانات بالسحابة تلقائياً.
  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 30), () {
      if (_uid == null) _signIn();
    });
  }

  @override
  void dispose() {
    _retry?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
