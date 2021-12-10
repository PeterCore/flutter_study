import 'package:simple_wallet/pages/account/import/import_account_action.dart';
import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/utils/format.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class CreateAccountForm extends StatefulWidget {
  const CreateAccountForm(this.service,
      {Key key, this.submitting, this.onSubmit})
      : super(key: key);

  final AppService service;
  final Future<bool> Function() onSubmit;
  final bool submitting;

  @override
  _CreateAccountFormState createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _pass2Ctrl = TextEditingController();

  bool _supportBiometric = false;
  bool _enableBiometric = true; // if the biometric usage checkbox checked

  Future<void> _checkBiometricAuth() async {
    final response = await BiometricStorage().canAuthenticate();
    final supportBiometric = response == CanAuthenticateResponse.success;
    if (!supportBiometric) {
      return;
    }
    setState(() {
      _supportBiometric = supportBiometric;
    });
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState.validate()) {
      widget.service.store.account
          .setNewAccount(_nameCtrl.text, _passCtrl.text);
      final success = await widget.onSubmit();

      if (success) {
        /// save password with biometrics after import success
        if (_supportBiometric && _enableBiometric) {
          await ImportAccountAction.authBiometric(context, widget.service);
        }

        widget.service.plugin.changeAccount(widget.service.keyring.current);
        widget.service.store.account.resetNewAccount();
        widget.service.store.account.setAccountCreated();
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAuth();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.person),
                    hintText: dic['create.name'],
                    labelText: dic['create.name'],
                  ),
                  controller: _nameCtrl,
                  validator: (v) {
                    return v.trim().isNotEmpty
                        ? null
                        : dic['create.name.error'];
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.lock),
                    hintText: dic['create.password'],
                    labelText: dic['create.password'],
                  ),
                  controller: _passCtrl,
                  validator: (v) {
                    return AppFmt.checkPassword(v.trim())
                        ? null
                        : dic['create.password.error'];
                  },
                  obscureText: true,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.lock),
                    hintText: dic['create.password2'],
                    labelText: dic['create.password2'],
                  ),
                  controller: _pass2Ctrl,
                  obscureText: true,
                  validator: (v) {
                    return _passCtrl.text != v
                        ? dic['create.password2.error']
                        : null;
                  },
                ),
                Visibility(
                    visible: _supportBiometric,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _enableBiometric,
                              onChanged: (v) {
                                setState(() {
                                  _enableBiometric = v;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(dic['unlock.bio.enable']),
                          )
                        ],
                      ),
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: RoundedButton(
              text: I18n.of(context).getDic(i18n_full_dic_ui, 'common')['next'],
              onPressed: widget.submitting ? null : () => _onSubmit(),
            ),
          ),
        ],
      ),
    );
  }
}
