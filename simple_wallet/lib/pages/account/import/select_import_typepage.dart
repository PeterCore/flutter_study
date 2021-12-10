import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

import 'import_account_form_keystore.dart';
import 'import_account_form_mnemonic.dart';
import 'import_account_from_rawseed.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class SelectImportTypePage extends StatefulWidget {
  static const String route = '/account/selectImportType';
  final AppService service;

  const SelectImportTypePage(this.service, {Key key}) : super(key: key);

  @override
  _SelectImportTypePageState createState() => _SelectImportTypePageState();
}

class _SelectImportTypePageState extends State<SelectImportTypePage> {
  final _keyOptions = [
    'mnemonic',
    'rawSeed',
    'keystore',
  ];

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['import']),
          centerTitle: true,
          leading: BackBtn(
            onBack: () => Navigator.of(context).pop(),
          )),
      body: SafeArea(
          child: Column(
        children: [
          ListTile(title: Text(dic['import.type'])),
          Expanded(
              child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _keyOptions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(dic[_keyOptions[index]]),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        switch (index) {
                          case 0:
                            Navigator.pushNamed(
                                context, ImportAccountFormMnemonic.route,
                                arguments: {"type": _keyOptions[index]});
                            break;
                          case 1:
                            Navigator.pushNamed(
                                context, ImportAccountFromRawSeed.route,
                                arguments: {"type": _keyOptions[index]});
                            break;
                          case 2:
                            Navigator.pushNamed(
                                context, ImportAccountFormKeyStore.route,
                                arguments: {"type": _keyOptions[index]});
                            break;
                        }
                      },
                    );
                  }))
        ],
      )),
    );
  }
}
