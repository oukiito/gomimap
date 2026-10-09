// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => '语言 / Language';

  @override
  String get languageSaveError => '无法保存语言。下次请重新选择。';

  @override
  String get about => '关于此原型';

  @override
  String get sampleBanner => '测试数据 · 请勿用于实际投放垃圾';

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get searchTab => '垃圾分类';

  @override
  String get placesTab => '资源回收点';

  @override
  String get chooseArea => '选择地区';

  @override
  String get fictionalAreas => '这些是用于测试的虚构地区。';

  @override
  String areaName(String area) {
    return '丰岛区 · 示例地区$area';
  }

  @override
  String get areaSaveError => '无法保存。设置未更改。请重试。';

  @override
  String sourceOpenError(String url) {
    return '无法打开官方网站。\n$url';
  }

  @override
  String demoDate(String date) {
    return '$date的显示示例';
  }

  @override
  String get upcoming => '接下来的收集安排';

  @override
  String get officialToshima => '查看丰岛区官方信息（日语）';

  @override
  String get official => '查看官方信息（日语）';

  @override
  String get checkTime => '请查看官方投放方法和时间';

  @override
  String get noCollection => '当天不收集';

  @override
  String get uncertain => '需要确认垃圾收集安排';

  @override
  String get burnable => '可燃垃圾';

  @override
  String get recyclables => '可回收资源';

  @override
  String get metals => '金属、陶瓷和玻璃';

  @override
  String get searchTitle => '这是什么垃圾？';

  @override
  String get searchSubtitle => '输入物品名称查询。';

  @override
  String get itemName => '物品名称';

  @override
  String get searchHint => '例如：电池、塑料瓶';

  @override
  String get noResults => '未找到。请尝试其他名称，或查看官方信息。';

  @override
  String get disposal => '查看投放方法';

  @override
  String get disposalAndPlaces => '投放方法与专用回收点';

  @override
  String get sampleSorting => '垃圾分类示例';

  @override
  String get findPlaces => '查找专用回收点';

  @override
  String get officialDisposal => '查看官方投放方法（日语）';

  @override
  String get placesSubtitle => '电池、小型家电和荧光灯等的回收点。\n普通垃圾请查看“今天”。';

  @override
  String get damageQuestion => '是否鼓包或破损？';

  @override
  String get noDamage => '没有';

  @override
  String get damagedOrUnknown => '有／不确定';

  @override
  String get damageWarning => '请勿放入普通回收箱。请确认物品状况，并通过区政府官方信息查找咨询方式。';

  @override
  String get officialBattery => '查看官方电池回收方法与咨询方式（日语）';

  @override
  String placesCount(int count) {
    return '示例回收点（$count处）';
  }

  @override
  String get fictionalPoints => '这些地点是虚构的。请勿前往。';

  @override
  String get noPoints => '尚无此物品的已确认回收点。请查看区政府官方说明。';

  @override
  String get conditions => '查看接收条件';

  @override
  String samplePoint(String point) {
    return '示例回收点$point';
  }

  @override
  String get samplePointDetail => '用于测试的虚构回收点';

  @override
  String acceptedItems(String items) {
    return '接收物品示例：$items';
  }

  @override
  String get pointConditions => '接收时间和条件：未登记。\n此处并非实际回收点，不提供路线导航。';

  @override
  String get mapTitle => '回收点地图';

  @override
  String get mapUnavailable => '地图尚未连接。\n可通过下方列表试用。';

  @override
  String get aboutBody =>
      '本开发示例使用虚构的日程、地区和回收点。请勿用于实际垃圾投放。\n\n地区、语言和提醒设置保存在设备上。不获取照片或位置信息。';

  @override
  String get dryBattery => '干电池';

  @override
  String get rechargeable => '充电电池';

  @override
  String get appliance => '小型家电';

  @override
  String get lamp => '荧光灯';

  @override
  String get dryBatteryHint => '请先确认电池类型和状况，再选择回收点。';

  @override
  String get rechargeableHint => '请勿放入干电池回收箱。请确认适合其类型和状况的回收方法。';

  @override
  String get applianceHint => '请确认接收品目、投入口大小及内置电池的处理规定。';

  @override
  String get lampHint => '破损灯管与LED灯泡的处理方法不同，请查看官方说明。';

  @override
  String get food => '厨余垃圾';

  @override
  String get pet => 'PET塑料瓶';

  @override
  String get cans => '罐和玻璃瓶';

  @override
  String get bulky => '家具及大件垃圾';

  @override
  String get foodGuidance => '可燃垃圾投放示例：投放前请沥干水分。';

  @override
  String get recyclingGuidance => '资源回收示例：请确认定期收集日期和投放方法。';

  @override
  String get dryBatteryGuidance => '请根据电池类型确认回收方法。';

  @override
  String get rechargeableGuidance => '处理方法因类型及是否鼓包、破损而异。';

  @override
  String get applianceGuidance => '请确认尺寸限制及内置电池的处理规定。';

  @override
  String get lampGuidance => '请分别确认荧光灯与LED灯泡的规定。';

  @override
  String get bulkyGuidance => '大件垃圾的处理规定因尺寸和品目而异。请查看区政府的品目说明及预约信息。';

  @override
  String collectionArea(String area) {
    return '垃圾收集区域：$area';
  }

  @override
  String get setupAreaTitle => '设置示例地区';

  @override
  String get confirmAreaTitle => '使用这个地区吗？';

  @override
  String candidateArea(String area) {
    return '将设置的地区：$area';
  }

  @override
  String currentArea(String area) {
    return '当前设置：$area';
  }

  @override
  String get confirmAreaAction => '保存这个地区';

  @override
  String get chooseAgain => '重新选择';

  @override
  String get savingArea => '正在保存…';

  @override
  String get setupRecovery => '无法读取地区设置。请重新选择。';

  @override
  String get cancel => '取消';

  @override
  String collectionDeadline(String time) {
    return '请在$time前投放';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item：请在$time前投放';
  }

  @override
  String get chooseCollectionItem => '请选择要送去回收的物品类型。';

  @override
  String backToItem(String item) {
    return '返回$item的说明';
  }

  @override
  String get close => '关闭';

  @override
  String get widgetLabel => '垃圾收集日程';

  @override
  String get widgetSample => '开发用示例';

  @override
  String get widgetNext => '下次安排';

  @override
  String get widgetOfferTitle => '在主屏幕显示垃圾收集日程';

  @override
  String get widgetOfferBody => '无需打开应用，即可查看日期和垃圾种类。';

  @override
  String get widgetAdd => '添加';

  @override
  String get widgetSkip => '跳过';

  @override
  String get widgetSettings => '主屏幕小组件';

  @override
  String get widgetAdded => '已添加到主屏幕';

  @override
  String get widgetRequested => '已请求添加。请在系统提示中确认。';

  @override
  String get widgetUnsupported => '长按主屏幕，选择“小组件”，然后添加“Gomimap”。';

  @override
  String get widgetFailure => '无法请求添加。请重试或从主屏幕添加。';

  @override
  String get widgetSaveError => '无法保存选择。请重试。';

  @override
  String get disposalDeadlinePassed => '已过垃圾投放截止时间';

  @override
  String get notifications => '垃圾收集提醒';

  @override
  String get notificationIntro => '在收集日早晨提醒您。';

  @override
  String get notificationEnabled => '早晨提醒';

  @override
  String get notificationEvening => '也在前一天晚上提醒';

  @override
  String get notificationSave => '保存';

  @override
  String get notificationLater => '稍后';

  @override
  String get notificationPermission => '此设备未允许通知';

  @override
  String get notificationOsSettings => '打开设备通知设置';

  @override
  String get notificationNone => '没有可预约的收集日期';

  @override
  String get notificationFixture => '普通版不会预约示例提醒';

  @override
  String notificationReserved(int count) {
    return '已预约：$count条';
  }

  @override
  String notificationPreview(int count) {
    return '测试时钟：预览$count条提醒';
  }

  @override
  String notificationNext(String when) {
    return '下次提醒：$when';
  }

  @override
  String get notificationError => '无法保存或应用更改。请检查设置和提醒预约。';

  @override
  String get notificationRetry => '重试';

  @override
  String get notificationTest => '显示测试通知';

  @override
  String notificationMorningTitle(String date) {
    return '今天$date的垃圾';
  }

  @override
  String notificationEveningTitle(String date) {
    return '为明天$date做准备';
  }

  @override
  String notificationTestTitle(String title) {
    return '测试：$title';
  }

  @override
  String get notificationChangedArea => '此提醒属于其他收集地区。显示当前地区。';

  @override
  String get notificationUpdated => '此提醒之后日程已更新。';

  @override
  String get notificationOfferTitle => '在收集日提醒我';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => '语言 / Language';

  @override
  String get languageSaveError => '无法保存语言。下次请重新选择。';

  @override
  String get about => '关于此原型';

  @override
  String get sampleBanner => '测试数据 · 请勿用于实际投放垃圾';

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get searchTab => '垃圾分类';

  @override
  String get placesTab => '资源回收点';

  @override
  String get chooseArea => '选择地区';

  @override
  String get fictionalAreas => '这些是用于测试的虚构地区。';

  @override
  String areaName(String area) {
    return '丰岛区 · 示例地区$area';
  }

  @override
  String get areaSaveError => '无法保存。设置未更改。请重试。';

  @override
  String sourceOpenError(String url) {
    return '无法打开官方网站。\n$url';
  }

  @override
  String demoDate(String date) {
    return '$date的显示示例';
  }

  @override
  String get upcoming => '接下来的收集安排';

  @override
  String get officialToshima => '查看丰岛区官方信息（日语）';

  @override
  String get official => '查看官方信息（日语）';

  @override
  String get checkTime => '请查看官方投放方法和时间';

  @override
  String get noCollection => '当天不收集';

  @override
  String get uncertain => '需要确认垃圾收集安排';

  @override
  String get burnable => '可燃垃圾';

  @override
  String get recyclables => '可回收资源';

  @override
  String get metals => '金属、陶瓷和玻璃';

  @override
  String get searchTitle => '这是什么垃圾？';

  @override
  String get searchSubtitle => '输入物品名称查询。';

  @override
  String get itemName => '物品名称';

  @override
  String get searchHint => '例如：电池、塑料瓶';

  @override
  String get noResults => '未找到。请尝试其他名称，或查看官方信息。';

  @override
  String get disposal => '查看投放方法';

  @override
  String get disposalAndPlaces => '投放方法与专用回收点';

  @override
  String get sampleSorting => '垃圾分类示例';

  @override
  String get findPlaces => '查找专用回收点';

  @override
  String get officialDisposal => '查看官方投放方法（日语）';

  @override
  String get placesSubtitle => '电池、小型家电和荧光灯等的回收点。\n普通垃圾请查看“今天”。';

  @override
  String get damageQuestion => '是否鼓包或破损？';

  @override
  String get noDamage => '没有';

  @override
  String get damagedOrUnknown => '有／不确定';

  @override
  String get damageWarning => '请勿放入普通回收箱。请确认物品状况，并通过区政府官方信息查找咨询方式。';

  @override
  String get officialBattery => '查看官方电池回收方法与咨询方式（日语）';

  @override
  String placesCount(int count) {
    return '示例回收点（$count处）';
  }

  @override
  String get fictionalPoints => '这些地点是虚构的。请勿前往。';

  @override
  String get noPoints => '尚无此物品的已确认回收点。请查看区政府官方说明。';

  @override
  String get conditions => '查看接收条件';

  @override
  String samplePoint(String point) {
    return '示例回收点$point';
  }

  @override
  String get samplePointDetail => '用于测试的虚构回收点';

  @override
  String acceptedItems(String items) {
    return '接收物品示例：$items';
  }

  @override
  String get pointConditions => '接收时间和条件：未登记。\n此处并非实际回收点，不提供路线导航。';

  @override
  String get mapTitle => '回收点地图';

  @override
  String get mapUnavailable => '地图尚未连接。\n可通过下方列表试用。';

  @override
  String get aboutBody =>
      '本开发示例使用虚构的日程、地区和回收点。请勿用于实际垃圾投放。\n\n地区、语言和提醒设置保存在设备上。不获取照片或位置信息。';

  @override
  String get dryBattery => '干电池';

  @override
  String get rechargeable => '充电电池';

  @override
  String get appliance => '小型家电';

  @override
  String get lamp => '荧光灯';

  @override
  String get dryBatteryHint => '请先确认电池类型和状况，再选择回收点。';

  @override
  String get rechargeableHint => '请勿放入干电池回收箱。请确认适合其类型和状况的回收方法。';

  @override
  String get applianceHint => '请确认接收品目、投入口大小及内置电池的处理规定。';

  @override
  String get lampHint => '破损灯管与LED灯泡的处理方法不同，请查看官方说明。';

  @override
  String get food => '厨余垃圾';

  @override
  String get pet => 'PET塑料瓶';

  @override
  String get cans => '罐和玻璃瓶';

  @override
  String get bulky => '家具及大件垃圾';

  @override
  String get foodGuidance => '可燃垃圾投放示例：投放前请沥干水分。';

  @override
  String get recyclingGuidance => '资源回收示例：请确认定期收集日期和投放方法。';

  @override
  String get dryBatteryGuidance => '请根据电池类型确认回收方法。';

  @override
  String get rechargeableGuidance => '处理方法因类型及是否鼓包、破损而异。';

  @override
  String get applianceGuidance => '请确认尺寸限制及内置电池的处理规定。';

  @override
  String get lampGuidance => '请分别确认荧光灯与LED灯泡的规定。';

  @override
  String get bulkyGuidance => '大件垃圾的处理规定因尺寸和品目而异。请查看区政府的品目说明及预约信息。';

  @override
  String collectionArea(String area) {
    return '垃圾收集区域：$area';
  }

  @override
  String get setupAreaTitle => '设置示例地区';

  @override
  String get confirmAreaTitle => '使用这个地区吗？';

  @override
  String candidateArea(String area) {
    return '将设置的地区：$area';
  }

  @override
  String currentArea(String area) {
    return '当前设置：$area';
  }

  @override
  String get confirmAreaAction => '保存这个地区';

  @override
  String get chooseAgain => '重新选择';

  @override
  String get savingArea => '正在保存…';

  @override
  String get setupRecovery => '无法读取地区设置。请重新选择。';

  @override
  String get cancel => '取消';

  @override
  String collectionDeadline(String time) {
    return '请在$time前投放';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item：请在$time前投放';
  }

  @override
  String get chooseCollectionItem => '请选择要送去回收的物品类型。';

  @override
  String backToItem(String item) {
    return '返回$item的说明';
  }

  @override
  String get close => '关闭';

  @override
  String get widgetLabel => '垃圾收集日程';

  @override
  String get widgetSample => '开发用示例';

  @override
  String get widgetNext => '下次安排';

  @override
  String get widgetOfferTitle => '在主屏幕显示垃圾收集日程';

  @override
  String get widgetOfferBody => '无需打开应用，即可查看日期和垃圾种类。';

  @override
  String get widgetAdd => '添加';

  @override
  String get widgetSkip => '跳过';

  @override
  String get widgetSettings => '主屏幕小组件';

  @override
  String get widgetAdded => '已添加到主屏幕';

  @override
  String get widgetRequested => '已请求添加。请在系统提示中确认。';

  @override
  String get widgetUnsupported => '长按主屏幕，选择“小组件”，然后添加“Gomimap”。';

  @override
  String get widgetFailure => '无法请求添加。请重试或从主屏幕添加。';

  @override
  String get widgetSaveError => '无法保存选择。请重试。';

  @override
  String get disposalDeadlinePassed => '已过垃圾投放截止时间';

  @override
  String get notifications => '垃圾收集提醒';

  @override
  String get notificationIntro => '在收集日早晨提醒您。';

  @override
  String get notificationEnabled => '早晨提醒';

  @override
  String get notificationEvening => '也在前一天晚上提醒';

  @override
  String get notificationSave => '保存';

  @override
  String get notificationLater => '稍后';

  @override
  String get notificationPermission => '此设备未允许通知';

  @override
  String get notificationOsSettings => '打开设备通知设置';

  @override
  String get notificationNone => '没有可预约的收集日期';

  @override
  String get notificationFixture => '普通版不会预约示例提醒';

  @override
  String notificationReserved(int count) {
    return '已预约：$count条';
  }

  @override
  String notificationPreview(int count) {
    return '测试时钟：预览$count条提醒';
  }

  @override
  String notificationNext(String when) {
    return '下次提醒：$when';
  }

  @override
  String get notificationError => '无法保存或应用更改。请检查设置和提醒预约。';

  @override
  String get notificationRetry => '重试';

  @override
  String get notificationTest => '显示测试通知';

  @override
  String notificationMorningTitle(String date) {
    return '今天$date的垃圾';
  }

  @override
  String notificationEveningTitle(String date) {
    return '为明天$date做准备';
  }

  @override
  String notificationTestTitle(String title) {
    return '测试：$title';
  }

  @override
  String get notificationChangedArea => '此提醒属于其他收集地区。显示当前地区。';

  @override
  String get notificationUpdated => '此提醒之后日程已更新。';

  @override
  String get notificationOfferTitle => '在收集日提醒我';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => '語言 / Language';

  @override
  String get languageSaveError => '無法儲存語言。下次請重新選擇。';

  @override
  String get about => '關於此原型';

  @override
  String get sampleBanner => '測試資料 · 請勿用於實際丟棄垃圾';

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get searchTab => '垃圾分類';

  @override
  String get placesTab => '資源回收點';

  @override
  String get chooseArea => '選擇地區';

  @override
  String get fictionalAreas => '這些是用於測試的虛構地區。';

  @override
  String areaName(String area) {
    return '豐島區 · 範例地區$area';
  }

  @override
  String get areaSaveError => '無法儲存。設定未變更。請再試一次。';

  @override
  String sourceOpenError(String url) {
    return '無法開啟官方網站。\n$url';
  }

  @override
  String demoDate(String date) {
    return '$date的顯示範例';
  }

  @override
  String get upcoming => '接下來的收集安排';

  @override
  String get officialToshima => '查看豐島區官方資訊（日文）';

  @override
  String get official => '查看官方資訊（日文）';

  @override
  String get checkTime => '請查看官方丟棄方式及時間';

  @override
  String get noCollection => '當天不收集';

  @override
  String get uncertain => '需要確認垃圾收集安排';

  @override
  String get burnable => '可燃垃圾';

  @override
  String get recyclables => '可回收資源';

  @override
  String get metals => '金屬、陶瓷和玻璃';

  @override
  String get searchTitle => '這是什麼垃圾？';

  @override
  String get searchSubtitle => '輸入物品名稱查詢。';

  @override
  String get itemName => '物品名稱';

  @override
  String get searchHint => '例如：電池、寶特瓶';

  @override
  String get noResults => '找不到結果。請嘗試其他名稱，或查看官方資訊。';

  @override
  String get disposal => '查看丟棄方式';

  @override
  String get disposalAndPlaces => '丟棄方式與專用回收點';

  @override
  String get sampleSorting => '垃圾分類範例';

  @override
  String get findPlaces => '尋找專用回收點';

  @override
  String get officialDisposal => '查看官方丟棄方式（日文）';

  @override
  String get placesSubtitle => '電池、小型家電及日光燈等的回收點。\n一般垃圾請查看「今天」。';

  @override
  String get damageQuestion => '是否膨脹或破損？';

  @override
  String get noDamage => '沒有';

  @override
  String get damagedOrUnknown => '有／不確定';

  @override
  String get damageWarning => '請勿放入一般回收箱。請確認物品狀況，並透過區政府官方資訊查找諮詢方式。';

  @override
  String get officialBattery => '查看官方電池回收方式與諮詢管道（日文）';

  @override
  String placesCount(int count) {
    return '範例回收點（$count處）';
  }

  @override
  String get fictionalPoints => '這些地點是虛構的。請勿前往。';

  @override
  String get noPoints => '尚無此物品的已確認回收點。請查看區政府官方說明。';

  @override
  String get conditions => '查看收受條件';

  @override
  String samplePoint(String point) {
    return '範例回收點$point';
  }

  @override
  String get samplePointDetail => '用於測試的虛構回收點';

  @override
  String acceptedItems(String items) {
    return '收受物品範例：$items';
  }

  @override
  String get pointConditions => '收受時間與條件：未登錄。\n此處並非實際回收點，不提供路線導引。';

  @override
  String get mapTitle => '回收點地圖';

  @override
  String get mapUnavailable => '地圖尚未連接。\n可透過下方清單試用。';

  @override
  String get aboutBody =>
      '此開發範例使用虛構的日程、地區與回收點。請勿用於實際垃圾投放。\n\n地區、語言與提醒設定儲存在裝置上。不取得照片或位置資訊。';

  @override
  String get dryBattery => '乾電池';

  @override
  String get rechargeable => '充電電池';

  @override
  String get appliance => '小型家電';

  @override
  String get lamp => '日光燈';

  @override
  String get dryBatteryHint => '請先確認電池種類與狀況，再選擇回收點。';

  @override
  String get rechargeableHint => '請勿放入乾電池回收箱。請確認適合其種類與狀況的回收方式。';

  @override
  String get applianceHint => '請確認收受品目、投入口大小及內建電池的處理規定。';

  @override
  String get lampHint => '破損燈管與LED燈泡的處理方式不同，請查看官方說明。';

  @override
  String get food => '廚餘';

  @override
  String get pet => '寶特瓶';

  @override
  String get cans => '罐與玻璃瓶';

  @override
  String get bulky => '家具及大型垃圾';

  @override
  String get foodGuidance => '可燃垃圾丟棄範例：丟棄前請瀝乾水分。';

  @override
  String get recyclingGuidance => '資源回收範例：請確認定期收集日期及丟棄方式。';

  @override
  String get dryBatteryGuidance => '請依電池種類確認回收方式。';

  @override
  String get rechargeableGuidance => '處理方式因種類及是否膨脹、破損而異。';

  @override
  String get applianceGuidance => '請確認尺寸限制及內建電池的處理規定。';

  @override
  String get lampGuidance => '請分別確認日光燈與LED燈泡的規定。';

  @override
  String get bulkyGuidance => '大型垃圾的處理規定因尺寸及品目而異。請查看區政府的品目說明及預約資訊。';

  @override
  String collectionArea(String area) {
    return '垃圾收集地區：$area';
  }

  @override
  String get setupAreaTitle => '設定範例地區';

  @override
  String get confirmAreaTitle => '使用這個地區嗎？';

  @override
  String candidateArea(String area) {
    return '將設定的地區：$area';
  }

  @override
  String currentArea(String area) {
    return '目前設定：$area';
  }

  @override
  String get confirmAreaAction => '儲存這個地區';

  @override
  String get chooseAgain => '重新選擇';

  @override
  String get savingArea => '正在儲存…';

  @override
  String get setupRecovery => '無法讀取地區設定。請重新選擇。';

  @override
  String get cancel => '取消';

  @override
  String collectionDeadline(String time) {
    return '請在$time前投放';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item：請在$time前投放';
  }

  @override
  String get chooseCollectionItem => '請選擇要送去回收的物品類型。';

  @override
  String backToItem(String item) {
    return '返回$item的說明';
  }

  @override
  String get close => '關閉';

  @override
  String get widgetLabel => '垃圾收集日程';

  @override
  String get widgetSample => '開發用範例';

  @override
  String get widgetNext => '下次安排';

  @override
  String get widgetOfferTitle => '在主畫面顯示垃圾收集日程';

  @override
  String get widgetOfferBody => '不用開啟應用程式，即可查看日期和垃圾種類。';

  @override
  String get widgetAdd => '加入';

  @override
  String get widgetSkip => '略過';

  @override
  String get widgetSettings => '主畫面小工具';

  @override
  String get widgetAdded => '已加入主畫面';

  @override
  String get widgetRequested => '已提出加入要求。請在系統提示中確認。';

  @override
  String get widgetUnsupported => '長按主畫面，選擇「小工具」，再加入「Gomimap」。';

  @override
  String get widgetFailure => '無法提出加入要求。請重試或從主畫面加入。';

  @override
  String get widgetSaveError => '無法儲存選擇。請重試。';

  @override
  String get disposalDeadlinePassed => '已過垃圾投放截止時間';

  @override
  String get notifications => '垃圾收集提醒';

  @override
  String get notificationIntro => '在收集日早晨提醒您。';

  @override
  String get notificationEnabled => '早晨提醒';

  @override
  String get notificationEvening => '也在前一天晚上提醒';

  @override
  String get notificationSave => '儲存';

  @override
  String get notificationLater => '稍後';

  @override
  String get notificationPermission => '此裝置未允許通知';

  @override
  String get notificationOsSettings => '開啟裝置通知設定';

  @override
  String get notificationNone => '沒有可預約的收集日期';

  @override
  String get notificationFixture => '一般版不會預約範例提醒';

  @override
  String notificationReserved(int count) {
    return '已預約：$count則';
  }

  @override
  String notificationPreview(int count) {
    return '測試時鐘：預覽$count則提醒';
  }

  @override
  String notificationNext(String when) {
    return '下次提醒：$when';
  }

  @override
  String get notificationError => '無法儲存或套用變更。請檢查設定及提醒預約。';

  @override
  String get notificationRetry => '重試';

  @override
  String get notificationTest => '顯示測試通知';

  @override
  String notificationMorningTitle(String date) {
    return '今天$date的垃圾';
  }

  @override
  String notificationEveningTitle(String date) {
    return '為明天$date做準備';
  }

  @override
  String notificationTestTitle(String title) {
    return '測試：$title';
  }

  @override
  String get notificationChangedArea => '此提醒屬於其他收集地區。顯示目前地區。';

  @override
  String get notificationUpdated => '此提醒之後日程已更新。';

  @override
  String get notificationOfferTitle => '在收集日提醒我';
}
