import 'package:simple_wallet/app.dart';
import 'package:simple_wallet/common/consts.dart';
import 'package:simple_wallet/service/walletApi.dart';
import 'package:simple_wallet/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(get_storage_container);
  //await Firebase.initializeApp();
  var appVersionCode = await Utils.getBuildNumber();

  final plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
  ];

  final pluginsConfig = await WalletApi.getPluginsConfig(BuildTargets.apk);
  if (pluginsConfig != null) {
    plugins.removeWhere((i) {
      final List disabled = pluginsConfig[i.basic.name]['disabled'];
      if (disabled != null) {
        return disabled.contains(appVersionCode) || disabled.contains(0);
      }
      return false;
    });
  }

  runApp(WalletApp(
      plugins,
      [
        // PluginDisabled(
        //     'chainx', Image.asset('assets/images/public/chainx_gray.png'))
      ],
      BuildTargets.apk));
}
