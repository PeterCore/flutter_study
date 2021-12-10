// ignore_for_file: use_key_in_widget_constructors

import 'package:simple_wallet/pages/account/create/account_advance_option.dart';
import 'package:simple_wallet/pages/account/create/backup_account_page.dart';
import 'package:simple_wallet/pages/account/create/create_account_form.dart';
import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/utils/UI.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage(this.service);
  final AppService service;

  static const String route = '/account/create';

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  AccountAdvanceOptionParams _advanceOptions = AccountAdvanceOptionParams();

  int _step = 0;
  bool _submitting = false;

  Future<bool> _importAccount() async {
    setState(() {
      _submitting = true;
    });
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['loading']),
          content:
              const SizedBox(height: 64, child: CupertinoActivityIndicator()),
        );
      },
    );

    try {
      final json = await widget.service.account.importAccount(
        cryptoType: _advanceOptions.type ?? CryptoType.sr25519,
        derivePath: _advanceOptions.path ?? '',
        isFromCreatePage: true,
      );
      await widget.service.account.addAccount(
        json: json,
        cryptoType: _advanceOptions.type ?? CryptoType.sr25519,
        derivePath: _advanceOptions.path ?? '',
        isFromCreatePage: true,
      );

      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop();
      return true;
    } catch (err) {
      Navigator.of(context).pop();
      AppUI.alertWASM(context, () {
        setState(() {
          _submitting = false;
          _step = 0;
        });
      }, errorMsg: err.toString());
      return false;
    }
  }

  Future<void> _onNext() async {
    final next = await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
        final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
        return CupertinoAlertDialog(
          title: Container(),
          content: Column(
            children: <Widget>[
              Image.asset('assets/images/screenshot.png'),
              Container(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Text(
                  dic['create.warn9'],
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Text(dic['create.warn10']),
            ],
          ),
          actions: <Widget>[
            CupertinoButton(
              child: Text(dicCommon['cancel']),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoButton(
              child: Text(dicCommon['ok']),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (next) {
      final advancedOptions =
          await Navigator.pushNamed(context, BackupAccountPage.route);
      if (advancedOptions != null) {
        setState(() {
          _step = 1;
          _advanceOptions = (advancedOptions as AccountAdvanceOptionParams);
        });
      } else {
        widget.service.store.account.resetNewAccount();
      }
    }
  }

  Widget _generateSeed(BuildContext context) {
    var theme = Theme.of(context).textTheme;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Scaffold(
      appBar: AppBar(
          title: Text(dic['create']),
          centerTitle: true,
          leading: BackBtn(
            onBack: () => Navigator.of(context).pop(),
          )),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(dic['create.warn1'], style: theme.headline4),
                  ),
                  Text(dic['create.warn2']),
                  Container(
                    padding: const EdgeInsets.only(bottom: 16, top: 32),
                    child: Text(dic['create.warn3'], style: theme.headline4),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(dic['create.warn4']),
                  ),
                  Text(dic['create.warn5']),
                  Container(
                    padding: const EdgeInsets.only(bottom: 16, top: 32),
                    child: Text(dic['create.warn6'], style: theme.headline4),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(dic['create.warn7']),
                  ),
                  Text(dic['create.warn8']),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: RoundedButton(
                text:
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['next'],
                onPressed: () => _onNext(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      return _generateSeed(context);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
            I18n.of(context).getDic(i18n_full_dic_app, 'account')['create']),
        leading: BackBtn(
          onBack: () {
            setState(() {
              _step = 0;
            });
          },
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CreateAccountForm(
          widget.service,
          submitting: _submitting,
          onSubmit: _importAccount,
        ),
      ),
    );
  }
}
