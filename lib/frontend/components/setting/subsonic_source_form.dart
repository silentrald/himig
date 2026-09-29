import "package:flutter/material.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/state.dart";

class SubsonicSourceForm extends StatefulWidget {
  // If null, then this is in create mode
  //   else, update mode
  final SubsonicSource? source;
  final void Function(SubsonicSource)? onAccept;
  final void Function()? onCancel;

  const SubsonicSourceForm({
    super.key,
    this.source,
    this.onAccept,
    this.onCancel,
  });

  @override
  State<SubsonicSourceForm> createState() => _SubsonicSourceFormState();
}

class _SubsonicSourceFormState extends State<SubsonicSourceForm> {
  final _formGlobalKey = GlobalKey<FormState>();

  String _name = "";
  String _address = "";
  String _username = "";
  String _password = "";
  int? _localSourceId;
  bool _passwordObscured = true;

  @override
  void initState() {
    super.initState();

    if (widget.source == null) {
      return;
    }

    final source = widget.source!;
    final protocol = source.https ? "https" : "http";
    _name = source.name;
    _address = "$protocol://${source.host}";
    _username = source.username;
    _localSourceId = source.localSourceId;
  }

  String? _validatePassword(String value) =>
      widget.source != null && _password.isEmpty
      ? null
      : SubsonicSource.validatePassword(value);

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
              label: Text(locale.app(.generic, "name")),
            ),
            validator: (value) => SubsonicSource.validateName(value ?? ""),
            onSaved: (value) => _name = value!,
          ),

          // Host
          TextFormField(
            initialValue: _address,
            decoration: InputDecoration(
              label: Text(locale.app(.generic, "address")),
            ),
            validator: (value) => SubsonicSource.validateAddress(value ?? ""),
            onSaved: (value) => _address = value!,
          ),

          // Username
          TextFormField(
            initialValue: _username,
            decoration: InputDecoration(
              label: Text(locale.app(.generic, "username")),
            ),
            validator: (value) => SubsonicSource.validateUsername(value ?? ""),
            onSaved: (value) => _username = value!,
          ),

          // Password
          TextFormField(
            initialValue: _password,
            obscureText: _passwordObscured,
            decoration: InputDecoration(
              label: Text(locale.app(.generic, "password")),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordObscured ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _passwordObscured = !_passwordObscured),
              ),
            ),
            validator: (value) => _validatePassword(value ?? ""),
            onSaved: (value) => _password = value!,
          ),

          // Local source id
          DropdownButton<int>(
            value: _localSourceId,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(locale.app(.generic, "none")),
              ),
              ...AppState().writeableSources.map(
                (source) => DropdownMenuItem(
                  value: source.id,
                  child: Text(source.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _localSourceId = value),
          ),

          const SizedBox(height: 8),

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
          child: Text(locale.app(.generic, "delete")),
        ),
      );
      buttons.add(
        FilledButton(
          onPressed: () {
            if (!_formGlobalKey.currentState!.validate() ||
                widget.onAccept == null) {
              return;
            }

            _formGlobalKey.currentState!.save();

            final SubsonicSource source = widget.source!.copy();
            source.setName(_name);
            source.setAddress(_address);
            source.setUsername(_username);
            source.setLocalSourceId(_localSourceId);
            if (_password.isNotEmpty) source.setPassword(_password);
            widget.onAccept!.call(source);
            setState(() => _password = ""); // Clear password afterwards
          },
          style: buttonStyle,
          child: Text(locale.app(.generic, "update")),
        ),
      );
    } else {
      buttons.add(
        FilledButton(
          onPressed: () {
            if (!_formGlobalKey.currentState!.validate() ||
                widget.onAccept == null) {
              return;
            }

            _formGlobalKey.currentState!.save();
            widget.onAccept!.call(
              SubsonicSource.createUnsafe(
                name: _name,
                address: _address,
                username: _username,
                password: _password,
                localSourceId: _localSourceId,
              ),
            );
          },
          style: buttonStyle,
          child: Text(locale.app(.generic, "create")),
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
