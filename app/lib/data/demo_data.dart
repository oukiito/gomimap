// SPDX-License-Identifier: GPL-3.0-or-later

import '../domain/schedule.dart';

const officialWasteUrl =
    'https://www.city.toshima.lg.jp/kurashi/gomi/index.html';
final demoToday = DateTime(2026, 10, 5);

enum DemoArea { a, b }

ScheduleCalendar demoCalendar(DemoArea area) => ScheduleCalendar(
  validFrom: DateTime(2026, 10),
  validUntil: DateTime(2026, 10, 31),
  rules: [
    CollectionRule('burnable', area == DemoArea.a ? {1, 4} : {2, 5}),
    const CollectionRule('recyclables', {3}),
    const CollectionRule('metals', {5}, monthWeeks: {1, 3}),
  ],
  uncertainDates: {DateTime(2026, 10, 8)},
);

enum SpecialItem { dryBattery, rechargeable, appliance, lamp }

enum SortingKind {
  food,
  pet,
  cans,
  dryBattery,
  rechargeable,
  appliance,
  lamp,
  bulky,
}

class SortingItem {
  const SortingItem(this.kind, this.keywords, {this.special});
  final SortingKind kind;

  /// Search aliases are independent of the current display language.
  final String keywords;
  final SpecialItem? special;
}

const sortingItems = [
  SortingItem(
    SortingKind.food,
    '生ごみ なまごみ 食べ残し 野菜 food scraps vegetable 厨余 廚餘 음식물 rác thực phẩm खानेकुरा restos comida alimentos pagkain',
  ),
  SortingItem(
    SortingKind.pet,
    'ペットボトル PET ぺっとぼとる plastic bottle 塑料瓶 寶特瓶 페트병 chai nhựa बोतल garrafa botella bote',
  ),
  SortingItem(
    SortingKind.cans,
    '缶 かん ビン びん 瓶 cans glass bottles 罐 玻璃瓶 캔 유리병 lon chai thủy tinh क्यान सिसा lata vidrio salamin',
  ),
  SortingItem(
    SortingKind.dryBattery,
    '乾電池 かんでんち 電池 dry cell battery batteries 干电池 乾電池 건전지 pin khô ब्याट्री pilha pila baterya',
    special: SpecialItem.dryBattery,
  ),
  SortingItem(
    SortingKind.rechargeable,
    '充電池 じゅうでんち モバイルバッテリー リチウム 電池 rechargeable battery batteries power bank lithium 充电电池 充電電池 충전지 pin sạc रिचार्जेबल ब्याट्री bateria batería recarregável recargable baterya',
    special: SpecialItem.rechargeable,
  ),
  SortingItem(
    SortingKind.appliance,
    '小型家電 こがたかでん 携帯電話 スマホ small electronics phone smartphone 小型家电 小型家電 소형 가전 thiết bị điện उपकरण eletrônico aparato elektroniko',
    special: SpecialItem.appliance,
  ),
  SortingItem(
    SortingKind.lamp,
    '蛍光灯 けいこうとう 電球 fluorescent tube lamp bulb 荧光灯 日光燈 형광등 đèn huỳnh quang बत्ती lâmpada tubo fluorescente ilaw',
    special: SpecialItem.lamp,
  ),
  SortingItem(
    SortingKind.bulky,
    '家具 粗大ごみ そだいごみ 椅子 いす 机 furniture bulky waste chair desk 家具 大件 大型 가구 대형 đồ nội thất cồng kềnh फर्निचर móveis muebles muwebles',
  ),
];

class CollectionPoint {
  const CollectionPoint(this.id, this.latitude, this.longitude, this.accepts);
  final String id;
  final double latitude;
  final double longitude;
  final Set<SpecialItem> accepts;
}

// Fictional test points. Never use for directions or disposal.
const demoPoints = [
  CollectionPoint('a', 35.7295, 139.7109, {
    SpecialItem.dryBattery,
    SpecialItem.appliance,
  }),
  CollectionPoint('b', 35.724, 139.718, {
    SpecialItem.dryBattery,
    SpecialItem.lamp,
  }),
];
