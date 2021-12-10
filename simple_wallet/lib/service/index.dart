import 'package:simple_wallet/service/apiAccount.dart';
import 'package:simple_wallet/service/apiAssets.dart';
import 'package:simple_wallet/store/index.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class AppService {
  AppService(this.allPlugins, this.plugin, this.keyring, this.store);

  final List<PolkawalletPlugin> allPlugins;
  final PolkawalletPlugin plugin;
  final Keyring keyring;
  final AppStore store;

  final subScan = SubScanApi();

  ApiAccount _account;
  ApiAssets _assets;

  ApiAccount get account => _account;
  ApiAssets get assets => _assets;

  void init() {
    _account = ApiAccount(this);
    _assets = ApiAssets(this);
  }
}
