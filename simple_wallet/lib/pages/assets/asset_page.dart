import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simple_wallet/common/components/CustomRefreshIndicator.dart';
import 'package:simple_wallet/common/consts.dart';
// import 'package:simple_wallet/pages/assets/announcementPage.dart';
// import 'package:simple_wallet/pages/assets/asset/assetPage.dart';
// import 'package:simple_wallet/pages/assets/manage/manageAssetsPage.dart';
// import 'package:simple_wallet/pages/assets/nodeSelectPage.dart';
// import 'package:simple_wallet/pages/assets/transfer/transferPage.dart';
// import 'package:simple_wallet/pages/networkSelectPage.dart';
// import 'package:simple_wallet/pages/public/AdBanner.dart';
import 'package:simple_wallet/service/index.dart';
import 'package:simple_wallet/service/walletApi.dart';
import 'package:simple_wallet/utils/i18n/index.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/components/v3/iconButton.dart' as v3;
import 'package:simple_wallet/colors.dart' as color;
import 'package:simple_wallet/pages/assets/transfer_detail_page.dart';
import 'package:simple_wallet/pages/profile/index.dart';

// import 'package:rive/rive.dart';

class AssetsPage extends StatefulWidget {
  AssetsPage(
    this.service,
    this.plugins,
    this.changeNode,
    this.connectedNode,
    this.checkJSCodeUpdate,
    this.switchNetwork,
    //this.handleWalletConnect,
  );

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(PolkawalletPlugin) checkJSCodeUpdate;
  final Future<void> Function(String) switchNetwork;
  //final Future<void> Function(String) handleWalletConnect;

  final List<PolkawalletPlugin> plugins;
  final Future<void> Function(NetworkParams) changeNode;
  @override
  _AssetsState createState() => _AssetsState();
}

class _AssetsState extends State<AssetsPage> {
  final GlobalKey<CustomRefreshIndicatorState> _refreshKey =
      new GlobalKey<CustomRefreshIndicatorState>();

  bool _refreshing = false;
  List _announcements;
  Timer _priceUpdateTimer;

  Future<dynamic> _fetchAnnouncements() async {
    if (_announcements == null) {
      _announcements = await WalletApi.getAnnouncements();
    }
    var index = _announcements.indexWhere((element) {
      return element["plugin"] == widget.service.plugin.basic.name;
    });
    if (index == -1) {
      return _announcements.where((element) {
        return element["plugin"] == "all";
      }).first;
    } else {
      return _announcements[index];
    }
  }

  Future<void> _updateMarketPrices() async {
    if (widget.service.plugin.balances.tokens.isNotEmpty) {
      widget.service.assets.fetchMarketPrices(
          widget.service.plugin.balances.tokens.map((e) => e.symbol).toList());
    }
    _priceUpdateTimer = Timer(const Duration(seconds: 60), _updateMarketPrices);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (BuildContext context) {
      bool transferEnabled = true;
      // // todo: fix this after new acala online
      if (widget.service.plugin.basic.name == 'acala') {
        transferEnabled = false;
        if (widget.service.store.settings.liveModules['assets'] != null) {
          transferEnabled =
              widget.service.store.settings.liveModules['assets']['enabled'];
        }
      }
      bool claimKarEnabled = false;
      if (widget.service.plugin.basic.name == 'karura') {
        if (widget.service.store.settings.liveModules['claim'] != null) {
          claimKarEnabled =
              widget.service.store.settings.liveModules['claim']['enabled'];
        }
      }
      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

      final balancesInfo = widget.service.plugin.balances.native;
      final tokens = widget.service.plugin.balances.tokens.toList();
      final tokensAll = widget.service.plugin.noneNativeTokensAll ?? [];

      // add custom assets from user's config & tokensAll
      final customTokensConfig = widget.service.store.assets.customAssets;
      if (customTokensConfig.keys.isNotEmpty) {
        tokens.retainWhere((e) => customTokensConfig[e.id]);

        tokensAll.retainWhere((e) => customTokensConfig[e.id]);
        for (var e in tokensAll) {
          if (tokens.indexWhere((token) => token.id == e.id) < 0) {
            tokens.add(e);
          }
        }
      }

      final extraTokens = widget.service.plugin.balances.extraTokens;
      final isTokensFromCache =
          widget.service.plugin.balances.isTokensFromCache;

      String tokenPrice;
      if (widget.service.store.assets.marketPrices[symbol] != null &&
          balancesInfo != null) {
        tokenPrice = Fmt.priceCeil(
            widget.service.store.assets.marketPrices[symbol] *
                Fmt.bigIntToDouble(Fmt.balanceTotal(balancesInfo), decimals));
      }
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final address = widget.service.keyring.current.address;
      const String unit = "\$";
      // final bannerVisible =
      //     widget.service.plugin.basic.name == relay_chain_name_dot ||
      //         widget.service.store.account.showBanner;
      return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          title: Text(
            dic['assets'],
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SafeArea(
            child: Container(
          padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).primaryColor.withOpacity(0.9),
                  ], begin: Alignment.bottomLeft, end: Alignment.centerRight),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                        offset: const Offset(5, 10),
                        blurRadius: 20,
                        color: color.AppColor.gradientSecond.withOpacity(0.2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                  image: AssetImage(
                                      "assets/images/wallet_connect_logo.png"),
                                  fit: BoxFit.fill),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Marie D.Moore',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'LUK账号: ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      address,
                                      textAlign: TextAlign.left,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                          Expanded(child: Container()), //SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Colors.white,
                          )
                        ],
                      ),
                      onTap: () {
                        print("123131313");
                        Navigator.pushNamed(context, ProfilePage.route);
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: Colors.white.withAlpha(100),
                    ),
                    const SizedBox(height: 35),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '我的资产',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 45),
                        Text(
                          '$unit$tokenPrice',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    Container(
                      height: 1,
                      color: Colors.white.withAlpha(100),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      //crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                                text: '资产\n',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$unit$tokenPrice',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                ]),
                          ),
                        )),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withAlpha(100),
                        ),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                                text: '零钱\n',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$unit$tokenPrice',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                ]),
                          ),
                        )),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withAlpha(100),
                        ),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                                text: '合计\n',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$unit$tokenPrice',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                ]),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(width: 5, height: 20, color: Colors.black),
                  const SizedBox(width: 5),
                  Text(
                    dic['assets'],
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: color.AppColor.homePageIcons),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RoundedCard(
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        height: 30,
                        width: 30,
                        child: widget.service.plugin.tokenIcons[symbol],
                      ),
                      title: Text(
                        symbol,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textSelectionColor,
                            fontFamily: "TitilliumWeb"),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              balancesInfo != null &&
                                      balancesInfo.freeBalance != null
                                  ? Fmt.priceFloorBigInt(
                                      Fmt.balanceTotal(balancesInfo), decimals,
                                      lengthFixed: 4)
                                  : '--.--',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: balancesInfo?.isFromCache == false
                                      ? Theme.of(context).textSelectionColor
                                      : Theme.of(context).dividerColor,
                                  fontFamily: "TitilliumWeb")),
                          Text(
                            '≈ \$${tokenPrice ?? '--.--'}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).textSelectionColor,
                                fontFamily: "TitilliumWeb"),
                          ),
                        ],
                      ),
                      onTap: transferEnabled
                          ? () {
                              Navigator.pushNamed(
                                  context, TransferDetailPage.route);
                            }
                          : null,
                    ),
                    Visibility(
                        visible: tokens != null && tokens.length > 0,
                        child: Column(
                          children: (tokens ?? []).map((TokenBalanceData i) {
                            // we can use token price form plugin or from market
                            final price = i.price ??
                                widget.service.store.assets
                                    .marketPrices[i.symbol];
                            return TokenItem(
                              i,
                              i.decimals,
                              isFromCache: isTokensFromCache,
                              detailPageRoute: i.detailPageRoute,
                              marketPrice: price,
                              icon: TokenIcon(
                                i.id ?? i.symbol,
                                widget.service.plugin.tokenIcons,
                                symbol: i.symbol,
                              ),
                            );
                          }).toList(),
                        )),
                    Visibility(
                      visible: extraTokens == null || extraTokens.isEmpty,
                      child: Column(
                          children: (extraTokens ?? []).map((ExtraTokenData i) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: BorderedTitle(
                                title: i.title,
                              ),
                            ),
                            Column(
                              children: i.tokens
                                  .map((e) => TokenItem(
                                        e,
                                        e.decimals,
                                        isFromCache: isTokensFromCache,
                                        detailPageRoute: e.detailPageRoute,
                                        icon: widget.service.plugin
                                            .tokenIcons[e.symbol],
                                      ))
                                  .toList(),
                            )
                          ],
                        );
                      }).toList()),
                    )
                  ],
                ),
              ),
            ],
          ),
        )),
      );
    });

    //return Container();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMarketPrices();
    });
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    super.dispose();
  }
}

class TokenItem extends StatelessWidget {
  TokenItem(this.item, this.decimals,
      {this.marketPrice,
      this.detailPageRoute,
      this.icon,
      this.isFromCache = false});
  final TokenBalanceData item;
  final int decimals;
  final double marketPrice;
  final String detailPageRoute;
  final Widget icon;
  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    final balanceTotal =
        Fmt.balanceInt(item.amount) + Fmt.balanceInt(item.reserved);
    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: Container(
            height: 30,
            width: 30,
            alignment: Alignment.centerLeft,
            child: icon ??
                CircleAvatar(
                  child: Text(item.symbol.substring(0, 2)),
                ),
          ),
          title: Text(
            item.symbol,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textSelectionColor,
                fontFamily: "TitilliumWeb"),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.priceFloorBigInt(balanceTotal, decimals, lengthFixed: 4),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFromCache == false
                        ? Theme.of(context).textSelectionColor
                        : Theme.of(context).dividerColor,
                    fontFamily: "TitilliumWeb"),
              ),
              marketPrice != null
                  ? Text(
                      '≈ \$${Fmt.priceFloor(Fmt.bigIntToDouble(balanceTotal, decimals) * marketPrice)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).textSelectionColor,
                          fontFamily: "TitilliumWeb"),
                    )
                  : Container(height: 0, width: 8),
            ],
          ),
          onTap: detailPageRoute == null
              ? null
              : () {
                  Navigator.of(context)
                      .pushNamed(detailPageRoute, arguments: item);
                },
        )
      ],
    );
  }
}
