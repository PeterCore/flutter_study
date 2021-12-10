import 'package:simple_wallet/pages/account/create/account_advance_option.dart';
import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'import_account_action.dart';
import 'import_account_create_page.dart';

class ImportAccountFormMnemonic extends StatefulWidget {
  final AppService service;

  static const String route = '/account/importAccountFormMnemonic';

  const ImportAccountFormMnemonic(this.service, {Key key}) : super(key: key);

  @override
  _ImportAccountFormMnemonicState createState() =>
      _ImportAccountFormMnemonicState();
}

class _ImportAccountFormMnemonicState extends State<ImportAccountFormMnemonic> {
  String selected;
  final TextEditingController _keyCtrl = TextEditingController();
  AccountAdvanceOptionParams _advanceOptions = AccountAdvanceOptionParams();
  final _formKey = GlobalKey<FormState>();

  bool _validating = false;
  AddressIconData _addressIcon = AddressIconData();

  @override
  void dispose() {
    widget.service.store.account.resetNewAccount();
    super.dispose();
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
                                          padding: const EdgeInsets.only(
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
                                    padding: const EdgeInsets.only(
                                        left: 16, right: 16),
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
                                  AccountAdvanceOption(
                                    api: widget.service.plugin.sdk.api?.keyring,
                                    seed: _keyCtrl.text.trim(),
                                    onChange:
                                        (AccountAdvanceOptionParams data) {
                                      setState(() {
                                        _advanceOptions = data;
                                      });

                                      _refreshAccountAddress(_keyCtrl.text);
                                    },
                                  ),
                                ],
                              )))),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: RoundedButton(
                          text: I18n.of(context)
                              .getDic(i18n_full_dic_ui, 'common')['next'],
                          onPressed: () async {
                            if (_formKey.currentState.validate() &&
                                !(_advanceOptions.error ?? false)) {
                              if (!(await _validateMnemonic())) return;

                              /// we should save user's key before next page
                              widget.service.store.account
                                  .setNewAccountKey(_keyCtrl.text.trim());

                              Navigator.pushNamed(
                                  context, ImportAccountCreatePage.route,
                                  arguments: {
                                    'keyType': selected,
                                    'cryptoType': _advanceOptions.type ??
                                        CryptoType.sr25519,
                                    'derivePath': _advanceOptions.path ?? '',
                                  });
                            }
                          },
                        ),
                      ),
                    ],
                  )),
        ));
  }

  String _validateInput(String v) {
    bool passed = false;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String input = v.trim();
    int len = input.split(' ').length;
    if (len >= 12) {
      passed = true;
    }
    return passed ? null : '${dic['import.invalid']} ${dic[selected]}';
  }

  Future<bool> _validateMnemonic() async {
    if (_validating) return false;

    setState(() {
      _validating = true;
    });
    final input = _keyCtrl.text.trim();
    final res =
        await widget.service.plugin.sdk.api.keyring.checkMnemonicValid(input);
    if (!res) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(dic['import.warn']),
            content: Text('${dic['import.invalid']} ${dic['mnemonic']}'),
            actions: [
              CupertinoButton(
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    setState(() {
      _validating = false;
    });
    return res;
  }

  void _onKeyChange(String v) {
    _refreshAccountAddress(v);
  }

  Future<void> _refreshAccountAddress(String v) async {
    final mnemonic = v.trim();

    if (mnemonic.split(" ").length >= 12) {
      final addressInfo = await widget.service.plugin.sdk.api.keyring
          .addressFromMnemonic(widget.service.plugin.basic.ss58,
              cryptoType: _advanceOptions.type,
              derivePath: _advanceOptions.path,
              mnemonic: mnemonic);
      setState(() {
        _addressIcon = addressInfo;
      });
    }
  }
}
