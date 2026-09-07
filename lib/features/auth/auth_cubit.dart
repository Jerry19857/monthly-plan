import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sheet_api.dart';

enum AuthStatus { unknown, locked, unlocked, checking, error }

class AuthState {
  const AuthState(this.status, {this.message});
  final AuthStatus status;
  final String? message;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._api) : super(const AuthState(AuthStatus.unknown)) {
    _boot();
  }

  final SheetApi _api;

  Future<void> _boot() async {
    final tok = await _api.token;
    emit(AuthState(tok != null ? AuthStatus.unlocked : AuthStatus.locked));
  }

  Future<void> submitPin(String pin) async {
    emit(const AuthState(AuthStatus.checking, message: 'กำลังตรวจสอบ...'));
    try {
      final ok = await _api.checkPin(pin);
      if (ok) {
        emit(const AuthState(AuthStatus.unlocked));
      } else {
        emit(const AuthState(AuthStatus.locked, message: '❌ PIN ไม่ถูกต้อง'));
      }
    } catch (_) {
      emit(const AuthState(AuthStatus.locked,
          message: '⚠️ เชื่อมต่อไม่ได้ ลองใหม่'));
    }
  }

  Future<void> lock() async {
    await _api.clearToken();
    emit(const AuthState(AuthStatus.locked));
  }
}
