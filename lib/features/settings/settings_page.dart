import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/db/app_database.dart';
import '../../theme.dart';
import '../auth/auth_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _wage = TextEditingController();
  final _tax = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await context.read<AppDatabase>().getSettings();
    _wage.text = s.dailyWage == 0 ? '' : _trim(s.dailyWage);
    _tax.text = s.taxRate == 0 ? '' : _trim(s.taxRate);
    setState(() => _loaded = true);
  }

  String _trim(double v) =>
      v == v.truncate() ? v.truncate().toString() : v.toString();

  Future<void> _save() async {
    final wage = double.tryParse(_wage.text) ?? 0;
    final tax = double.tryParse(_tax.text) ?? 0;
    await context.read<AppDatabase>().saveSettings(wage, tax);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกแล้ว')));
    }
  }

  @override
  void dispose() {
    _wage.dispose();
    _tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('ตั้งค่า'), backgroundColor: AppColors.mantle),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('ค่าแรง & ภาษี',
                    style: TextStyle(
                        color: AppColors.overlay1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                TextField(
                  controller: _wage,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'ค่าแรงต่อวัน (บาท)', hintText: 'เช่น 800'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tax,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'ภาษีหัก ณ ที่จ่าย (%)', hintText: 'เช่น 3'),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text('บันทึก')),
                const Divider(height: 40, color: AppColors.surface0),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.red),
                  title: const Text('ล็อกแอป'),
                  onTap: () => context.read<AuthCubit>().lock(),
                ),
                const SizedBox(height: 24),
                Text(
                  'sync ขึ้น Google Sheet เฉพาะรายการรายรับ-รายจ่ายรายเดือน\n'
                  'ปฏิทินและงานที่ต้องทำเก็บในเครื่องเท่านั้น',
                  style: TextStyle(color: AppColors.overlay0, fontSize: 12),
                ),
              ],
            ),
    );
  }
}
