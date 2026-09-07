import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme.dart';
import 'auth_cubit.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const _len = 6;
  String _pin = '';

  void _tap(String k) {
    final state = context.read<AuthCubit>().state;
    if (state.status == AuthStatus.checking) return;
    setState(() {
      if (k == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < _len) {
        _pin += k;
      }
    });
    if (_pin.length == _len) {
      context.read<AuthCubit>().submitPin(_pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (a, b) => b.status == AuthStatus.locked && b.message != null,
      listener: (context, state) => setState(() => _pin = ''),
      builder: (context, state) {
        final checking = state.status == AuthStatus.checking;
        return Scaffold(
          backgroundColor: AppColors.crust,
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color: AppColors.mantle,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.surface1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text('ใส่ PIN เพื่อเข้าใช้งาน',
                      style: TextStyle(
                          color: AppColors.mauve,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_len, (i) {
                      final filled = i < _pin.length;
                      return Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? AppColors.mauve
                              : const Color(0x00000000),
                          border: Border.all(
                              color: filled
                                  ? AppColors.mauve
                                  : AppColors.surface2,
                              width: 2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  _Numpad(onTap: _tap),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 20,
                    child: Text(
                      checking
                          ? (state.message ?? 'กำลังตรวจสอบ...')
                          : (state.message ?? ''),
                      style: TextStyle(
                        color: checking ? AppColors.overlay1 : AppColors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return CupertinoButton(
          padding: EdgeInsets.zero,
          color: AppColors.surface0,
          borderRadius: BorderRadius.circular(AppRadius.r),
          onPressed: () => onTap(k),
          child: Text(k == 'del' ? '⌫' : k,
              style: const TextStyle(
                  color: AppColors.text, fontSize: 20, fontFamily: kMonoFontFamily)),
        );
      }).toList(),
    );
  }
}
