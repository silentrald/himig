import "package:flutter/material.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/use_cases/settings/types.dart";
import "package:himig/frontend/components/setting/folder_source_form.dart";
import "package:himig/frontend/components/setting/subsonic_source_form.dart";
import "package:himig/frontend/controllers/locale.dart";
import "package:himig/inject.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class SettingsPage extends StatefulWidget {
  final LocaleController _localeController;

  const SettingsPage({super.key, required this._localeController});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingUseCase = getInject<SettingsUseCase>();

  bool _showForm = false;
  SourceType _sourceType = SourceType.folder;

  Future<void> _addSource(Source source) async {
    await _settingUseCase.addSource(source);
    setState(() => _showForm = false);
  }

  Future<void> _editSource(Source source) async {
    await _settingUseCase.editSource(source);
    setState(() {});
  }

  Future<void> _scanAlbums() async {
    switch (await _settingUseCase.scanSources()) {
      case ResultError(:var error):
        logger.error("Could not scan sources. Reson ${error.toString()}");
      case ResultOk(:var value):
        logger.info("Done caching $value");
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        children: [
          ...AppState().sourceList.map((source) => _buildItem(locale, source)),

          _showForm
              ? _buildForm(context)
              : FilledButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: Text(locale.app(.generic, "add")),
                ),

          FilledButton(
            onPressed: _scanAlbums,
            child: Text(locale.app(.generic, "scan")),
          ),

          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(locale.app(.generic, "back")),
          ),

          _buildLanguageDropdown(),
        ],
      ),
    );
  }

  Widget _buildItem(AppLocalizations locale, Source source) {
    switch (source) {
      case FolderSource(:var name):
        return ExpansionTile(
          title: Text(name),
          subtitle: Row(
            children: [
              Icon(Icons.folder, size: 16),
              Text(locale.app(.source, "folder")),
            ],
          ),
          children: [
            FolderSourceForm(
              source: source,
              onAccept: (editedSource) => _editSource(editedSource),
            ),
          ],
        );
      case SubsonicSource(:var name):
        return ExpansionTile(
          title: Text(name),
          subtitle: Row(
            children: [
              Icon(Icons.api, size: 16),
              Text(locale.app(.source, "subsonic")),
            ],
          ),
          children: [
            SubsonicSourceForm(
              source: source,
              onAccept: (editedSource) => _editSource(editedSource),
            ),
          ],
        );
    }
  }

  // TODO: Convert this to a modal
  Widget _buildForm(BuildContext context) {
    final form = switch (_sourceType) {
      SourceType.folder => FolderSourceForm(
        onAccept: (source) => _addSource(source),
      ),
      SourceType.subsonic => SubsonicSourceForm(
        onAccept: (source) => _addSource(source),
      ),
    };

    return Column(
      children: [
        DropdownButton<SourceType>(
          value: _sourceType,
          isExpanded: true,
          items: SourceType.values
              .map(
                (SourceType type) =>
                    DropdownMenuItem(value: type, child: Text(type.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => _sourceType = value!),
        ),

        SizedBox(height: 8),

        form,
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButton<Locale>(
      value: widget._localeController.locale,
      items: supportedLocales
          .map(
            (l) => DropdownMenuItem(
              value: l,
              child: Text(LocaleController.getDisplayName(l)),
            ),
          )
          .toList(),
      isExpanded: true,
      onChanged: (l) => widget._localeController.setLocale(l!),
    );
  }
}
