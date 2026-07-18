import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLowEndModeKey = 'setting_low_end_mode';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final bool isLowEndMode;

  const SettingsState({
    this.isLowEndMode = false,
  });

  SettingsState copyWith({
    bool? isLowEndMode,
  }) {
    return SettingsState(
      isLowEndMode: isLowEndMode ?? this.isLowEndMode,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isLowEndMode = prefs.getBool(_kLowEndModeKey) ?? false;
    state = state.copyWith(isLowEndMode: isLowEndMode);
  }

  Future<void> toggleLowEndMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLowEndModeKey, value);
    state = state.copyWith(isLowEndMode: value);
  }
}
