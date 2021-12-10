import 'dart:convert';
import 'dart:io';

import 'package:simple_wallet/common/consts.dart';
import 'package:simple_wallet/pages/assets/asset_page.dart';
// import 'package:simple_wallet/pages/assets/index.dart';
// import 'package:simple_wallet/pages/profile/index.dart';
// import 'package:app/pages/walletConnect/wcSessionsPage.dart';
import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/utils/BottomNavigationBar.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:polkawallet_plugin_kusama/common/constants.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/ui.dart';

class WalletHomePage extends StatefulWidget {
  // WalletHomePage({Key key}) : super(key: key);
  const WalletHomePage(this.service, this.plugins, this.connectedNode,
      this.checkJSCodeUpdate, this.switchNetwork, this.changeNode);

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(BuildContext, PolkawalletPlugin,
      {bool needReload}) checkJSCodeUpdate;
  final Future<void> Function(String) switchNetwork;

  final List<PolkawalletPlugin> plugins;
  final Future<void> Function(NetworkParams) changeNode;

  static const String route = '/';
  @override
  _WalletHomePage createState() => _WalletHomePage();
}

class _WalletHomePage extends State<WalletHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AssetsPage(
        widget.service,
        widget.plugins,
        widget.changeNode,
        widget.connectedNode,
        (PolkawalletPlugin plugin) => widget.checkJSCodeUpdate(context, plugin),
        (String name) async => widget.switchNetwork(name),
      ),
    );
  }
}
