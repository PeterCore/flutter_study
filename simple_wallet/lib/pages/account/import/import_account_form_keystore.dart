import 'dart:convert';

import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

import 'import_account_action.dart';

class ImportAccountFormKeyStore extends StatefulWidget {
  final AppService service;

  static const String route = '/account/ImportAccountFormKeyStore';

  const ImportAccountFormKeyStore(this.service, {Key key}) : super(key: key);

  @override
  _ImportAccountFormKeyStoreState createState() =>
      _ImportAccountFormKeyStoreState();
}

class _ImportAccountFormKeyStoreState extends State<ImportAccountFormKeyStore> {
  String selected;
  final TextEditingController _keyCtrl = new TextEditingController();
  final TextEditingController _nameCtrl = new TextEditingController();
  final TextEditingController _passCtrl = new TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _supportBiometric = false;
  bool _enableBiometric = true; // if the biometric usage checkbox checked

  AddressIconData _addressIcon = AddressIconData();

  @override
  void dispose() {
    widget.service.store.account.resetNewAccount();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAuth();
  }

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

  @override
  Widget build(BuildContext context) {
    selected = (ModalRoute.of(context).settings.arguments as Map)["type"];
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
        appBar: AppBar(
            title: Text(dic['import']),
            centerTitle: true,
            leading: BackBtn(
              onBack: () => Navigator.of(context).pop(),
            )),
        body: SafeArea(
          child: Observer(
              builder: (_) => Column(
                    children: [
                      Expanded(
                          child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                  child: Column(
                                children: [
                                  Visibility(
                                      visible: _addressIcon.svg != null,
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                              left: 16, right: 16, top: 16),
                                          child: AddressFormItem(
                                              KeyPairData()
                                                ..icon = _addressIcon.svg
                                                ..address =
                                                    _addressIcon.address,
                                              isShowSubtitle: false))),
                                  ListTile(
                                      title: Text(
                                        dic['import.type'],
                                      ),
                                      trailing: Text(dic[selected])),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 16, right: 16),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        hintText: dic[selected],
                                        labelText: dic[selected],
                                      ),
                                      controller: _keyCtrl,
                                      maxLines: 2,
                                      validator: _validateInput,
                                      onChanged: _onKeyChange,
                                    ),
                                  ),
                                  _buildNameAndPassInput(),
                                ],
                              )))),
                      Container(
                        padding: EdgeInsets.all(16),
                        child: RoundedButton(
                          text: I18n.of(context)
                              .getDic(i18n_full_dic_ui, 'common')['next'],
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              /// save user account info (keystore & name & pass) from input
                              widget.service.store.account.setNewAccount(
                                  _nameCtrl.text.trim(), _passCtrl.text.trim());
                              widget.service.store.account
                                  .setNewAccountKey(_keyCtrl.text.trim());

                              final saved = await ImportAccountAction.onSubmit(
                                  context,
                                  widget.service,
                                  {
                                    'keyType': selected,
                                  },
                                  (p0) {});
                              if (saved) {
                                if (_supportBiometric && _enableBiometric) {
                                  await ImportAccountAction.authBiometric(
                                      context, widget.service);
                                }

                                widget.service.plugin.changeAccount(
                                    widget.service.keyring.current);
                                widget.service.store.assets.loadCache(
                                    widget.service.keyring.current,
                                    widget.service.plugin.basic.name);
                                widget.service.store.account.resetNewAccount();
                                widget.service.store.account
                                    .setAccountCreated();
                                Navigator.popUntil(
                                    context, ModalRoute.withName('/'));
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  )),
        ));
  }

  Widget _buildNameAndPassInput() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: dic['create.name'],
              labelText: dic['create.name'],
            ),
            controller: _nameCtrl,
            validator: (v) {
              return v.trim().length > 0 ? null : dic['create.name.error'];
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: dic['create.password'],
              labelText: dic['create.password'],
              suffixIcon: IconButton(
                iconSize: 18,
                icon: Icon(
                  CupertinoIcons.clear_thick_circled,
                  color: Theme.of(context).unselectedWidgetColor,
                ),
                onPressed: () {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _passCtrl.clear());
                },
              ),
            ),
            controller: _passCtrl,
            obscureText: true,
            validator: (v) {
              // TODO: fix me: disable validator for polkawallet-RN exported keystore importing
              return null;
              // return v.trim().length > 0 ? null : dic['create.password.error'];
            },
          ),
        ),
        Visibility(
            visible: _supportBiometric,
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 24),
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
                    padding: EdgeInsets.only(left: 16),
                    child: Text(dic['unlock.bio.enable']),
                  )
                ],
              ),
            )),
      ],
    );
  }

  String _validateInput(String v) {
    bool passed = false;
    try {
      jsonDecode(v);
      passed = true;
    } catch (_) {
      // ignore
    }
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return passed ? null : '${dic['import.invalid']} ${dic[selected]}';
  }

  void _onKeyChange(String v) {
    try {
      final keyStoreString = v.trim();
      var json = jsonDecode(keyStoreString);
      _refreshAccountAddress(json);
      if (json['meta']['name'] != null) {
        setState(() {
          _nameCtrl.value = TextEditingValue(text: json['meta']['name']);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _refreshAccountAddress(Map keyStore) async {
    final addressInfo = await widget.service.plugin.sdk.api.keyring
        .addressFromKeyStore(widget.service.plugin.basic.ss58,
            keyStore: keyStore);
    setState(() {
      _addressIcon = addressInfo;
    });
  }
}
