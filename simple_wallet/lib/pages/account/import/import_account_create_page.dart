import 'package:simple_wallet/pages/account/create/create_account_form.dart';
import 'package:simple_wallet/service/index.dart';
import 'package:flutter/material.dart';

import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

import 'import_account_action.dart';

class ImportAccountCreatePage extends StatefulWidget {
  final AppService service;

  static const String route = '/account/ImportAccountCreatePage';

  const ImportAccountCreatePage(this.service, {Key key}) : super(key: key);

  @override
  _ImportAccountCreatePageState createState() =>
      _ImportAccountCreatePageState();
}

class _ImportAccountCreatePageState extends State<ImportAccountCreatePage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final data = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['import']),
          centerTitle: true,
          leading: BackBtn(
            onBack: () => Navigator.of(context).pop(),
          )),
      body: SafeArea(
        child: CreateAccountForm(
          widget.service,
          submitting: _submitting,
          onSubmit: () {
            return ImportAccountAction.onSubmit(context, widget.service, data,
                (submiting) {
              setState(() {
                _submitting = submiting;
              });
            });
          },
        ),
      ),
    );
  }
}
