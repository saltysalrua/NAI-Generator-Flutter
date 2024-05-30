// 文件路径：lib/screens/settings_screen.dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n.dart';
import '../models/info_manager.dart';
import '../widgets/param_config_widget.dart';
import '../models/utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _proxyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    _proxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(S.of(context).NAI_API_key),
            subtitle: Text(InfoManager().apiKey),
            onTap: () {
              _editApiKey();
            },
          ),
          Padding(
              padding: const EdgeInsets.only(left: 20, right: 80),
              child: ParamConfigWidget(config: InfoManager().paramConfig)),
          _buildLinkTile()
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await _loadJsonConfig();
            },
            tooltip: S.of(context).import_settings_from_file,
            child: const Icon(Icons.file_open),
          ),
          const SizedBox(height: 20),
          FloatingActionButton(
            onPressed: () async {
              await _saveJsonConfig();
            },
            tooltip: S.of(context).export_settings_to_file,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  void _editApiKey() {
    TextEditingController controller =
        TextEditingController(text: InfoManager().apiKey);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${S.of(context).edit}${S.of(context).NAI_API_key}'),
          content: TextField(
            controller: controller,
            maxLines: null,
          ),
          actions: [
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(S.of(context).confirm),
              onPressed: () {
                setState(() {
                  InfoManager().apiKey = controller.text;
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadJsonConfig() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withData: true);
      if (result != null) {
        var fileContent = utf8.decode(result.files.single.bytes!);
        Map<String, dynamic> jsonData = json.decode(fileContent);
        setState(() {
          if (InfoManager().fromJson(jsonData)) {
            showInfoBar(context,
                '${S.of(context).info_import_file}${S.of(context).succeed}');
          } else {
            throw Exception();
          }
        });
      }
    } catch (e) {
      showErrorBar(
          context, '${S.of(context).info_import_file}${S.of(context).failed}');
    }
  }

  _saveJsonConfig() {
    saveStringToFile(json.encode(InfoManager().toJson()),
        'nai-generator-config-${generateRandomFileName()}.json');
  }

  _buildLinkTile() {
    return ListTile(
      title: Text(S.of(context).github_repo),
      leading: const Icon(Icons.link),
      subtitle: const Text(
          'https://github.com/Exception0x0194/NAI-Generator-Flutter'),
      onTap: () => {
        launchUrl(Uri.parse(
            'https://github.com/Exception0x0194/NAI-Generator-Flutter'))
      },
    );
  }
}
