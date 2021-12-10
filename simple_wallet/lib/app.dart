import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/pages/qrSenderPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/pages/walletExtensionSignPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:simple_wallet/pages/wallet_home_page.dart';
import 'package:uni_links/uni_links.dart';

import 'package:simple_wallet/common/components/willPopScopWrapper.dart';
import 'package:simple_wallet/pages/account/create_account_entry_page.dart';
import 'package:simple_wallet/pages/account/create/backup_account_page.dart';
import 'package:simple_wallet/pages/account/create/create_account_page.dart';

import 'package:simple_wallet/common/consts.dart';
import 'package:simple_wallet/common/types/pluginDisabled.dart';
import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/service/walletApi.dart';
// import 'package:simplewallet/startPage.dart';
import 'package:simple_wallet/store/index.dart';
import 'package:simple_wallet/utils/UI.dart';
import 'package:simple_wallet/utils/i18n/index.dart';

import 'package:simple_wallet/pages/account/import/select_import_typepage.dart';
import 'package:simple_wallet/pages/account/import/import_account_create_page.dart';
import 'package:simple_wallet/pages/account/import/import_account_form_keystore.dart';
import 'package:simple_wallet/pages/account/import/import_account_form_mnemonic.dart';
import 'package:simple_wallet/pages/account/import/import_account_from_rawseed.dart';
import 'package:simple_wallet/pages/assets/transfer_detail_page.dart';
import 'package:simple_wallet/pages/transfer/transfer_page.dart';

import 'package:simple_wallet/pages/profile/index.dart';
import 'package:simple_wallet/pages/profile/account/account_manage_page.dart';
import 'package:simple_wallet/pages/profile/contacts/contact_page.dart';
import 'package:simple_wallet/pages/profile/settings/setting_page.dart';
import 'package:simple_wallet/pages/profile/settings/remote_node_page.dart';

const get_storage_container = 'configuration';

bool _isInitialUriHandled = false;

class WalletApp extends StatefulWidget {
  WalletApp(this.plugins, this.disabledPlugins, BuildTargets buildTarget) {
    WalletApp.buildTarget = buildTarget;
  }
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  static BuildTargets buildTarget;
  @override
  _WalletAppSate createState() => _WalletAppSate();
}

class _WalletAppSate extends State<WalletApp> {
  Keyring _keyring;

  AppStore _store;
  AppService _service;

  ThemeData _theme;

  Locale _locale;

  NetworkParams _connectedNode;

  Future<void> _getAcalaModulesConfig(String pluginName) async {
    final karModulesConfig = await (pluginName == 'karura'
        ? WalletApi.getKarModulesConfig()
        : WalletApi.getAcalaModulesConfig());
    if (karModulesConfig != null) {
      _store.settings.setLiveModules(karModulesConfig);
    } else {
      _store.settings.setLiveModules({
        'assets': {'enabled': true}
      });
    }
  }

  void _changeLang(String code) {
    _service.store.settings.setLocalCode(code);

    Locale res;
    switch (code) {
      case 'zh':
        res = const Locale('zh', '');
        break;
      case 'en':
        res = const Locale('en', '');
        break;
      default:
        res = null;
    }
    setState(() {
      _locale = res;
    });
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final versions = await WalletApi.getLatestVersion();
    AppUI.checkUpdate(context, versions, WalletApp.buildTarget,
        autoCheck: true);
  }

  Future<void> _checkBadAddressAndWarn(BuildContext context) async {
    if (_keyring != null &&
        _keyring.current != null &&
        _keyring.current.pubKey ==
            '0xda99a528d2cbe6b908408c4f887d2d0336394414a9edb474c33a690a4202341a') {
      final Map dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
      showCupertinoDialog(
          context: context,
          builder: (_) {
            return CupertinoAlertDialog(
              title: Text(dic['bad.warn']),
              content: Text(
                  '${Fmt.address(_keyring.current.address)} ${dic['bad.warn.info']}'),
              actions: [
                CupertinoButton(
                  child: Text(I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['ok']),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    }
  }

  Future<void> _checkJSCodeUpdate(
      BuildContext context, PolkawalletPlugin plugin,
      {bool needReload = true}) async {
    _checkBadAddressAndWarn(context);
    // check js code update
    final jsVersions = await WalletApi.fetchPolkadotJSVersion();
    if (jsVersions == null) return;

    final network = plugin.basic.name;
    final version = jsVersions[network];
    final versionMin = jsVersions['$network-min'];
    final currentVersion = WalletApi.getPolkadotJSVersion(
      _store.storage,
      network,
      plugin.basic.jsCodeVersion,
    );
    debugPrint('js update: $network $currentVersion $version $versionMin');
    final bool needUpdate = await AppUI.checkJSCodeUpdate(
        context, _store.storage, currentVersion, version, versionMin, network);
    if (needUpdate) {
      final res =
          await AppUI.updateJSCode(context, _store.storage, network, version);
      if (needReload && res) {
        _changeNetwork(plugin);
      }
    }
  }

  Future<int> _startApp(BuildContext context) async {
    if (_keyring == null) {
      _keyring = Keyring();
      await _keyring
          .init(widget.plugins.map((e) => e.basic.ss58).toSet().toList());

      final storage = GetStorage(get_storage_container);
      final store = AppStore(storage);
      await store.init();

      // await _showGuide(context, storage);

      final pluginIndex = widget.plugins
          .indexWhere((e) => e.basic.name == store.settings.network);
      final service = AppService(widget.plugins,
          widget.plugins[pluginIndex > -1 ? pluginIndex : 0], _keyring, store);
      service.init();
      setState(() {
        _store = store;
        _service = service;
        _theme = _getAppTheme(
          service.plugin.basic.primaryColor,
          secondaryColor: service.plugin.basic.gradientColor,
        );
      });

      if (store.settings.localeCode.isNotEmpty) {
        _changeLang(store.settings.localeCode);
      } else {
        _changeLang(Localizations.localeOf(context).toString());
      }

      // _checkUpdate(context);
      // await _checkJSCodeUpdate(context, service.plugin, needReload: false);

      final useLocalJS = WalletApi.getPolkadotJSVersion(
            _store.storage,
            service.plugin.basic.name,
            service.plugin.basic.jsCodeVersion,
          ) >
          service.plugin.basic.jsCodeVersion;

      await service.plugin.beforeStart(
        _keyring,
        jsCode: useLocalJS
            ? WalletApi.getPolkadotJSCode(
                _store.storage, service.plugin.basic.name)
            : null,
      );

      if (_keyring.keyPairs.isNotEmpty) {
        _store.assets.loadCache(_keyring.current, _service.plugin.basic.name);
      }

      _startPlugin(service);
    }

    return _keyring.allAccounts.length;
  }

  ThemeData _getAppTheme(MaterialColor color, {Color secondaryColor}) {
    return ThemeData(
      backgroundColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      dividerColor: const Color(0xFFBAB7B2),
      cardColor: const Color(0xFFF9F8F6),
      toggleableActiveColor: const Color(0xFF768FE1),
      textSelectionColor: const Color(0xFF565554),
      primaryColor: const Color(0xFF188BF0),
      appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF188BF0),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Color(0xFF565554),
              fontSize: 20,
              fontFamily: 'TitilliumWeb',
              fontWeight: FontWeight.w600)),
      primarySwatch: color,
      accentColor: secondaryColor,
      textTheme: const TextTheme(
          headline1: TextStyle(
            fontSize: 24,
          ),
          headline2: TextStyle(
            fontSize: 22,
          ),
          headline3: TextStyle(
            fontSize: 20,
          ),
          headline4: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          bodyText1: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF565554),
              fontFamily: "SF_Pro"),
          bodyText2: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Color(0xFF565554),
              fontFamily: "SF_Pro"),
          button: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: "SF_Pro")),
    );
  }

  Future<void> _changeNetwork(PolkawalletPlugin network) async {
    _keyring.setSS58(network.basic.ss58);

    setState(() {
      _theme = _getAppTheme(
        network.basic.primaryColor,
        secondaryColor: network.basic.gradientColor,
      );
    });
    _store.settings.setNetwork(network.basic.name);

    final useLocalJS = WalletApi.getPolkadotJSVersion(
          _store.storage,
          network.basic.name,
          network.basic.jsCodeVersion,
        ) >
        network.basic.jsCodeVersion;

    final service = AppService(widget.plugins, network, _keyring, _store);
    service.init();

    // we reuse the existing webView instance when we start a new plugin.
    await network.beforeStart(
      _keyring,
      webView: _service?.plugin?.sdk?.webView,
      jsCode: useLocalJS
          ? WalletApi.getPolkadotJSCode(_store.storage, network.basic.name)
          : null,
    );

    setState(() {
      _service = service;
    });

    _startPlugin(service);
  }

  Future<void> _startPlugin(AppService service) async {
    // _initWalletConnect();

    _service.assets.fetchMarketPriceFromSubScan();
    // _store.settings.getXcmEnabledChains(service.plugin.basic.name);

    setState(() {
      _connectedNode = null;
    });
    final connected = await service.plugin.start(_keyring);
    setState(() {
      _connectedNode = connected;
    });

    if (_service.plugin.basic.name == 'karura' ||
        _service.plugin.basic.name == 'acala') {
      _getAcalaModulesConfig(_service.plugin.basic.name);
    }
  }

  void _handleIncomingAppLinks() {
    uriLinkStream.listen((Uri uri) {
      if (!mounted) return;
      print('got uri: $uri');
    }, onError: (Object err) {
      if (!mounted) return;
      print('got err: $err');
    });
  }

  Future<void> _handleInitialAppLinks() async {
    if (!_isInitialUriHandled) {
      _isInitialUriHandled = true;
      print('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          print('no initial uri');
        } else {
          print('got initial uri: $uri');
        }
        if (!mounted) return;
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        print('falied to get initial uri');
      } on FormatException {
        if (!mounted) return;
        print('malformed initial uri');
      }
    }
  }

  Future<void> _switchNetwork(String networkName) async {
    await _changeNetwork(
        widget.plugins.firstWhere((e) => e.basic.name == networkName));
    _service.store.assets.loadCache(_keyring.current, networkName);
  }

  Future<void> _changeNode(NetworkParams node) async {
    if (_connectedNode != null) {
      setState(() {
        _connectedNode = null;
      });
    }
    _service.plugin.sdk.api.account.unsubscribeBalance();
    final connected = await _service.plugin.start(_keyring, nodes: [node]);
    setState(() {
      _connectedNode = connected;
    });
  }

  Map<String, Widget Function(BuildContext)> _getRoutes() {
    final pluginPages = _service != null && _service.plugin != null
        ? _service.plugin.getRoutes(_keyring)
        : {};
    return {
      /// pages of plugin
      ...pluginPages,
      CreateAccountEntryPage.route: (_) {
        _startApp(context);
        return WalletHomePage(_service, widget.plugins, _connectedNode,
            _checkJSCodeUpdate, _switchNetwork, _changeNode);
      },

      //basic pages
      WalletHomePage.route: (_) => WillPopScopWrapper(
            Observer(
              builder: (BuildContext context) {
                final accountCreated =
                    _service?.store?.account?.accountCreated ?? false;
                return FutureBuilder<int>(
                  future: _startApp(context),
                  builder: (_, AsyncSnapshot<int> snapshot) {
                    if (snapshot.hasData && _service != null) {
                      return snapshot.data > 0
                          ? WalletHomePage(
                              _service,
                              widget.plugins,
                              _connectedNode,
                              _checkJSCodeUpdate,
                              _switchNetwork,
                              _changeNode)
                          : CreateAccountEntryPage();
                    } else {
                      return Container(color: Theme.of(context).canvasColor);
                    }
                  },
                );
              },
            ),
          ),
      TxConfirmPage.route: (_) => TxConfirmPage(
            _service.plugin,
            _keyring,
            _service.account.getPassword,
            txDisabledCalls: _service.store.settings
                .getDisabledCalls(_service.plugin.basic.name),
          ),
      WalletExtensionSignPage.route: (_) => WalletExtensionSignPage(
          _service.plugin, _keyring, _service.account.getPassword),
      QrSenderPage.route: (_) => QrSenderPage(_service.plugin, _keyring),
      QrSignerPage.route: (_) => QrSignerPage(_service.plugin, _keyring),
      ScanPage.route: (_) => ScanPage(_service.plugin, _keyring),
      AccountListPage.route: (_) => AccountListPage(_service.plugin, _keyring),
      AccountQrCodePage.route: (_) =>
          AccountQrCodePage(_service.plugin, _keyring),

      /// account
      //CreateAccountEntryPage.route: (_) => CreateAccountEntryPage(),
      CreateAccountPage.route: (_) => CreateAccountPage(_service),
      BackupAccountPage.route: (_) => BackupAccountPage(_service),
      DAppWrapperPage.route: (_) => DAppWrapperPage(_service.plugin, _keyring),
      SelectImportTypePage.route: (_) => SelectImportTypePage(_service),
      ImportAccountFormMnemonic.route: (_) =>
          ImportAccountFormMnemonic(_service),
      ImportAccountFromRawSeed.route: (_) => ImportAccountFromRawSeed(_service),
      ImportAccountFormKeyStore.route: (_) =>
          ImportAccountFormKeyStore(_service),
      ImportAccountCreatePage.route: (_) => ImportAccountCreatePage(_service),

      /// assets
      TransferDetailPage.route: (_) => TransferDetailPage(_service),

      ///transfer
      TransferPage.route: (_) => TransferPage(_service),

      ///profile
      ProfilePage.route: (_) => ProfilePage(
            _service,
            _connectedNode,
            () async => _switchNetwork,
          ),
      AccountManagePage.route: (_) => AccountManagePage(_service),
      ContactsPage.route: (_) => ContactsPage(_service),
      SettingsPage.route: (_) =>
          SettingsPage(_service, _changeLang, _changeNode),
      RemoteNodeListPage.route: (_) => RemoteNodeListPage(_service, _changeNode)
    };
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _handleIncomingAppLinks();
    _handleInitialAppLinks();
  }

  @override
  Widget build(BuildContext context) {
    final routes = _getRoutes();
    return MaterialApp(
      title: 'Polkawallet',
      theme: _theme ??
          _getAppTheme(
            widget.plugins[0].basic.primaryColor,
            secondaryColor: widget.plugins[0].basic.gradientColor,
          ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizationsDelegate(_locale ?? const Locale('en', '')),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
      initialRoute: WalletHomePage.route,
      onGenerateRoute: (settings) => CupertinoPageRoute(
          builder: routes[settings.name], settings: settings),
    );

    /*final routes = _getRoutes();
    return GestureDetector(
      onTapUp: (_) {
        FocusScope.of(context).focusedChild?.unfocus();
      },
      child: ScreenUtilInit(
          designSize: const Size(1170, 2532),
          builder: () => MaterialApp(
                title: 'Polkawallet',
                theme: _theme ??
                    _getAppTheme(
                      widget.plugins[0].basic.primaryColor,
                      secondaryColor: widget.plugins[0].basic.gradientColor,
                    ),
                debugShowCheckedModeBanner: false,
                localizationsDelegates: [
                  AppLocalizationsDelegate(_locale ?? Locale('en', '')),
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                  Locale('zh', ''),
                ],
                initialRoute: CreateAccountEntryPage.route,
                onGenerateRoute: (settings) => CupertinoPageRoute(
                    builder: routes[settings.name], settings: settings),
                navigatorObservers: [
                  //FirebaseAnalyticsObserver(analytics: _analytics)
                ],
              )),
    );*/
  }
}
