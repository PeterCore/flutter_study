import 'package:simple_wallet/app.dart';
import 'package:package_info/package_info.dart';
import 'package:simple_wallet/common/consts.dart';

class Utils {
  static Future<int> getBuildNumber() async {
    return int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
  }

  static Future<String> getAppVersion() async {
    return "${(await PackageInfo.fromPlatform()).version}-${WalletApp.buildTarget == BuildTargets.dev ? "dev" : "beta"}.${(await PackageInfo.fromPlatform()).buildNumber.substring((await PackageInfo.fromPlatform()).buildNumber.length - 1)}";
  }
}
