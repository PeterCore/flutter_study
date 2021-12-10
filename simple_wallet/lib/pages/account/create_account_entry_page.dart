import 'package:flutter/cupertino.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:simple_wallet/pages/account/create/create_account_page.dart';
import 'package:simple_wallet/pages/account/import/select_import_typepage.dart';

class CreateAccountEntryPage extends StatelessWidget {
  static const String route = '/account/entry';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: Text(dic['add']),
        backgroundColor: Colors.red,
        centerTitle: true,
        /* leading: BackBtn(
          /   onBack: () => Navigator.of(context).pop(),
          )*/
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: Image.asset('assets/images/logo_about.png'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: RoundedButton(
                text: dic['create'],
                onPressed: () {
                  Navigator.pushNamed(context, CreateAccountPage.route);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: RoundedButton(
                text: dic['import'],
                onPressed: () {
                  Navigator.pushNamed(context, SelectImportTypePage.route);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
