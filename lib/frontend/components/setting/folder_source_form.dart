import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/locales/app_localizations.dart";

class FolderSourceForm extends StatefulWidget {
  final FolderSource? source;
  final void Function(FolderSource source)? onAccept;
  final void Function()? onCancel;

  const FolderSourceForm({
    super.key,
    this.source,
    this.onAccept,
    this.onCancel,
  });

  @override
  State<FolderSourceForm> createState() => _FolderSourceFormState();
}

enum _Option { read, readAndWrite }

class _FolderSourceFormState extends State<FolderSourceForm> {
  final _formGlobalKey = GlobalKey<FormState>();

  final _pathController = TextEditingController();
  String? _pathError;

  var _name = "";
  var _selectedReadWrite = _Option.readAndWrite;

  @override
  void initState() {
    super.initState();

    if (widget.source == null) {
      return;
    }

    _name = widget.source!.name;
    _pathController.text = widget.source!.path;
    _selectedReadWrite = widget.source!.writeable
        ? _Option.readAndWrite
        : _Option.read;
  }

  Future<void> _selectFolder() async {
    final locale = AppLocalizations.of(context)!;

    final path = (await FilePicker.getDirectoryPath()) ?? "";
    final error = FolderSource.validatePath(path);
    if (error != null) {
      _pathError = locale.translateProjectError(error);
    }
    _pathController.text = _pathError == null ? path : "";
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: _formGlobalKey,
      child: Column(
        children: [
          // Name
          TextFormField(
            initialValue: _name,
            decoration: InputDecoration(
              label: Text(locale.translate(.generic, "name")),
            ),
            validator: (value) => locale.translateProjectError(
              FolderSource.validateName(value ?? ""),
            ),
            onSaved: (value) => _name = value!,
          ),

          SizedBox(height: 8),

          // Path
          TextFormField(
            readOnly: true,
            canRequestFocus: false,
            controller: _pathController,
            decoration: InputDecoration(
              label: Text(locale.translate(.generic, "path")),
              errorText: _pathError,
            ),
            onTap: () => _selectFolder(),
          ),

          SizedBox(height: 8),

          DropdownButton<_Option>(
            value: _selectedReadWrite,
            isExpanded: true,
            items: _Option.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(locale.translate(.folderReadWrite, value.name)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedReadWrite = value!),
          ),

          SizedBox(height: 8),

          _buildButtons(locale, theme),
        ],
      ),
    );
  }

  Widget _buildButtons(AppLocalizations locale, ThemeData theme) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );

    final List<Widget> buttons = [];
    if (widget.source != null) {
      buttons.add(
        FilledButton(
          onPressed: () => widget.onCancel?.call(),
          style: buttonStyle,
          child: Text(locale.translate(.generic, "delete")),
        ),
      );
      buttons.add(
        FilledButton(
          onPressed: () {
            if (!_formGlobalKey.currentState!.validate() &&
                _pathController.text.isEmpty &&
                widget.onAccept == null) {
              return;
            }
            _formGlobalKey.currentState!.save();

            // No need to copy here
            widget.onAccept!.call(
              FolderSource(
                id: widget.source!.id,
                name: _name,
                path: _pathController.text,
                writeable: _selectedReadWrite == _Option.readAndWrite,
              ),
            );
          },
          style: buttonStyle,
          child: Text(locale.translate(.generic, "update")),
        ),
      );
    } else {
      buttons.add(
        FilledButton(
          onPressed: () {
            if (!_formGlobalKey.currentState!.validate() &&
                _pathController.text.isEmpty &&
                widget.onAccept == null) {
              return;
            }
            _formGlobalKey.currentState!.save();

            widget.onAccept!.call(
              FolderSource(
                name: _name,
                path: _pathController.text,
                writeable: _selectedReadWrite == _Option.readAndWrite,
              ),
            );
          },
          style: buttonStyle,
          child: Text(locale.translate(.generic, "create")),
        ),
      );
    }

    return Row(
      mainAxisAlignment: buttons.length == 2
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: buttons,
    );
  }
}
