import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLowEndModeKey = 'setting_low_end_mode';
const _kAutoSaveKey = 'setting_auto_save';
const _kWordWrapKey = 'setting_word_wrap';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final bool isLowEndMode;
  final bool isAutoSave;
  final bool isWordWrap;

  const SettingsState({
    this.isLowEndMode = false,
    this.isAutoSave = false,
    this.isWordWrap = false,
  });

  SettingsState copyWith({
    bool? isLowEndMode,
    bool? isAutoSave,
    bool? isWordWrap,
  }) {
    return SettingsState(
      isLowEndMode: isLowEndMode ?? this.isLowEndMode,
      isAutoSave: isAutoSave ?? this.isAutoSave,
      isWordWrap: isWordWrap ?? this.isWordWrap,
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
    final isAutoSave = prefs.getBool(_kAutoSaveKey) ?? false;
    final isWordWrap = prefs.getBool(_kWordWrapKey) ?? false;
    state = state.copyWith(
      isLowEndMode: isLowEndMode,
      isAutoSave: isAutoSave,
      isWordWrap: isWordWrap,
    );
  }

  Future<void> toggleLowEndMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLowEndModeKey, value);
    state = state.copyWith(isLowEndMode: value);
  }

  Future<void> toggleAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSaveKey, value);
    state = state.copyWith(isAutoSave: value);
  }

  Future<void> toggleWordWrap(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWordWrapKey, value);
    state = state.copyWith(isWordWrap: value);
  }
}
