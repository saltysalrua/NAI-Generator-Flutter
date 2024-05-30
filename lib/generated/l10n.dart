// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Image Generation`
  String get generation {
    return Intl.message(
      'Image Generation',
      name: 'generation',
      desc: '',
      args: [],
    );
  }

  /// `Prompt Settings`
  String get prompt_config {
    return Intl.message(
      'Prompt Settings',
      name: 'prompt_config',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Start/Stop Generation`
  String get toggle_generation {
    return Intl.message(
      'Start/Stop Generation',
      name: 'toggle_generation',
      desc: '',
      args: [],
    );
  }

  /// `Genration Settings`
  String get generation_settings {
    return Intl.message(
      'Genration Settings',
      name: 'generation_settings',
      desc: '',
      args: [],
    );
  }

  /// `Image Tile Height`
  String get info_tile_height {
    return Intl.message(
      'Image Tile Height',
      name: 'info_tile_height',
      desc: '',
      args: [],
    );
  }

  /// `Display Image Generation Info`
  String get toggle_display_info_aside_img {
    return Intl.message(
      'Display Image Generation Info',
      name: 'toggle_display_info_aside_img',
      desc: '',
      args: [],
    );
  }

  /// `Number of Images to Generate`
  String get image_number_to_generate {
    return Intl.message(
      'Number of Images to Generate',
      name: 'image_number_to_generate',
      desc: '',
      args: [],
    );
  }

  /// `Set Number of Images to Generate (Set to 0 for continuous generation)`
  String get edit_image_number_to_generate {
    return Intl.message(
      'Set Number of Images to Generate (Set to 0 for continuous generation)',
      name: 'edit_image_number_to_generate',
      desc: '',
      args: [],
    );
  }

  /// `Set looping generation`
  String get info_set_looping_genration {
    return Intl.message(
      'Set looping generation',
      name: 'info_set_looping_genration',
      desc: '',
      args: [],
    );
  }

  /// `Set {num} generations`
  String info_set_genration_number(Object num) {
    return Intl.message(
      'Set $num generations',
      name: 'info_set_genration_number',
      desc: '',
      args: [num],
    );
  }

  /// `Set genration number failed`
  String get info_set_genration_number_failed {
    return Intl.message(
      'Set genration number failed',
      name: 'info_set_genration_number_failed',
      desc: '',
      args: [],
    );
  }

  /// `Generate One Prompt`
  String get generate_one_prompt {
    return Intl.message(
      'Generate One Prompt',
      name: 'generate_one_prompt',
      desc: '',
      args: [],
    );
  }

  /// `Config Comment`
  String get comment {
    return Intl.message(
      'Config Comment',
      name: 'comment',
      desc: '',
      args: [],
    );
  }

  /// `Copy to Clipboard`
  String get copy_to_clipboard {
    return Intl.message(
      'Copy to Clipboard',
      name: 'copy_to_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `Selection Method`
  String get selection_method {
    return Intl.message(
      'Selection Method',
      name: 'selection_method',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get selection_method_all {
    return Intl.message(
      'All',
      name: 'selection_method_all',
      desc: '',
      args: [],
    );
  }

  /// `Single - random`
  String get selection_method_single {
    return Intl.message(
      'Single - random',
      name: 'selection_method_single',
      desc: '',
      args: [],
    );
  }

  /// `Single - sequential`
  String get selection_method_single_sequential {
    return Intl.message(
      'Single - sequential',
      name: 'selection_method_single_sequential',
      desc: '',
      args: [],
    );
  }

  /// `Multiple - with specified Count`
  String get selection_method_multiple_num {
    return Intl.message(
      'Multiple - with specified Count',
      name: 'selection_method_multiple_num',
      desc: '',
      args: [],
    );
  }

  /// `Selection Count`
  String get selection_num {
    return Intl.message(
      'Selection Count',
      name: 'selection_num',
      desc: '',
      args: [],
    );
  }

  /// `Multiple - with pecified Probability`
  String get selection_method_multiple_prob {
    return Intl.message(
      'Multiple - with pecified Probability',
      name: 'selection_method_multiple_prob',
      desc: '',
      args: [],
    );
  }

  /// `Selection Probability`
  String get selection_prob {
    return Intl.message(
      'Selection Probability',
      name: 'selection_prob',
      desc: '',
      args: [],
    );
  }

  /// `Shuffle Order`
  String get shuffled {
    return Intl.message(
      'Shuffle Order',
      name: 'shuffled',
      desc: '',
      args: [],
    );
  }

  /// `Random Number of Brackets`
  String get random_brackets {
    return Intl.message(
      'Random Number of Brackets',
      name: 'random_brackets',
      desc: '',
      args: [],
    );
  }

  /// `Nested Config Type`
  String get cascaded_config_type {
    return Intl.message(
      'Nested Config Type',
      name: 'cascaded_config_type',
      desc: '',
      args: [],
    );
  }

  /// `Nested Config`
  String get cascaded_config_type_config {
    return Intl.message(
      'Nested Config',
      name: 'cascaded_config_type_config',
      desc: '',
      args: [],
    );
  }

  /// `String`
  String get cascaded_config_type_str {
    return Intl.message(
      'String',
      name: 'cascaded_config_type_str',
      desc: '',
      args: [],
    );
  }

  /// `Nested Configs`
  String get cascaded_configs {
    return Intl.message(
      'Nested Configs',
      name: 'cascaded_configs',
      desc: '',
      args: [],
    );
  }

  /// `String Values`
  String get cascaded_strings {
    return Intl.message(
      'String Values',
      name: 'cascaded_strings',
      desc: '',
      args: [],
    );
  }

  /// `Add New Config`
  String get add_new_config {
    return Intl.message(
      'Add New Config',
      name: 'add_new_config',
      desc: '',
      args: [],
    );
  }

  /// `Import Config from Clipboard`
  String get import_config_from_clipboard {
    return Intl.message(
      'Import Config from Clipboard',
      name: 'import_config_from_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `Delete Config`
  String get delete_config {
    return Intl.message(
      'Delete Config',
      name: 'delete_config',
      desc: '',
      args: [],
    );
  }

  /// `Enable/Disable Config`
  String get toggle_config_enable {
    return Intl.message(
      'Enable/Disable Config',
      name: 'toggle_config_enable',
      desc: '',
      args: [],
    );
  }

  /// `Toggle Compact View`
  String get toggle_compact_view {
    return Intl.message(
      'Toggle Compact View',
      name: 'toggle_compact_view',
      desc: '',
      args: [],
    );
  }

  /// `NAI API Key`
  String get NAI_API_key {
    return Intl.message(
      'NAI API Key',
      name: 'NAI_API_key',
      desc: '',
      args: [],
    );
  }

  /// `Image Size`
  String get image_size {
    return Intl.message(
      'Image Size',
      name: 'image_size',
      desc: '',
      args: [],
    );
  }

  /// `Custom Size`
  String get custom_size {
    return Intl.message(
      'Custom Size',
      name: 'custom_size',
      desc: '',
      args: [],
    );
  }

  /// `Height`
  String get height {
    return Intl.message(
      'Height',
      name: 'height',
      desc: '',
      args: [],
    );
  }

  /// `Width`
  String get width {
    return Intl.message(
      'Width',
      name: 'width',
      desc: '',
      args: [],
    );
  }

  /// `Prompt Guidance`
  String get scale {
    return Intl.message(
      'Prompt Guidance',
      name: 'scale',
      desc: '',
      args: [],
    );
  }

  /// `Prompt Guidance Rescale`
  String get cfg_rescale {
    return Intl.message(
      'Prompt Guidance Rescale',
      name: 'cfg_rescale',
      desc: '',
      args: [],
    );
  }

  /// `SMEA`
  String get sm {
    return Intl.message(
      'SMEA',
      name: 'sm',
      desc: '',
      args: [],
    );
  }

  /// `DYN`
  String get sm_dyn {
    return Intl.message(
      'DYN',
      name: 'sm_dyn',
      desc: '',
      args: [],
    );
  }

  /// `Sampler`
  String get sampler {
    return Intl.message(
      'Sampler',
      name: 'sampler',
      desc: '',
      args: [],
    );
  }

  /// `Use Random Seed`
  String get use_random_seed {
    return Intl.message(
      'Use Random Seed',
      name: 'use_random_seed',
      desc: '',
      args: [],
    );
  }

  /// `Random Seed`
  String get random_seed {
    return Intl.message(
      'Random Seed',
      name: 'random_seed',
      desc: '',
      args: [],
    );
  }

  /// `Inverse Prompt Token`
  String get uc {
    return Intl.message(
      'Inverse Prompt Token',
      name: 'uc',
      desc: '',
      args: [],
    );
  }

  /// `GitHub Repository`
  String get github_repo {
    return Intl.message(
      'GitHub Repository',
      name: 'github_repo',
      desc: '',
      args: [],
    );
  }

  /// `Import Settings from File`
  String get import_settings_from_file {
    return Intl.message(
      'Import Settings from File',
      name: 'import_settings_from_file',
      desc: '',
      args: [],
    );
  }

  /// `Export Settings to File`
  String get export_settings_to_file {
    return Intl.message(
      'Export Settings to File',
      name: 'export_settings_to_file',
      desc: '',
      args: [],
    );
  }

  /// `Export to Clipboard`
  String get export_to_clipboard {
    return Intl.message(
      'Export to Clipboard',
      name: 'export_to_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `File import `
  String get info_import_file {
    return Intl.message(
      'File import ',
      name: 'info_import_file',
      desc: '',
      args: [],
    );
  }

  /// `File export `
  String get info_export_file {
    return Intl.message(
      'File export ',
      name: 'info_export_file',
      desc: '',
      args: [],
    );
  }

  /// `Clipboard import `
  String get info_import_from_clipboard {
    return Intl.message(
      'Clipboard import ',
      name: 'info_import_from_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `Clipboard export `
  String get info_export_to_clipboard {
    return Intl.message(
      'Clipboard export ',
      name: 'info_export_to_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `succeed`
  String get succeed {
    return Intl.message(
      'succeed',
      name: 'succeed',
      desc: '',
      args: [],
    );
  }

  /// `failed`
  String get failed {
    return Intl.message(
      'failed',
      name: 'failed',
      desc: '',
      args: [],
    );
  }

  /// `Enabled`
  String get enabled {
    return Intl.message(
      'Enabled',
      name: 'enabled',
      desc: '',
      args: [],
    );
  }

  /// `Disabled`
  String get disabled {
    return Intl.message(
      'Disabled',
      name: 'disabled',
      desc: '',
      args: [],
    );
  }

  /// `Edit `
  String get edit {
    return Intl.message(
      'Edit ',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Select `
  String get select {
    return Intl.message(
      'Select ',
      name: 'select',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
