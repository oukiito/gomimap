// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => '언어 / Language';

  @override
  String get languageSaveError => '언어를 저장하지 못했습니다. 다음에 다시 선택해 주세요.';

  @override
  String get about => '시제품 정보';

  @override
  String get sampleBanner => '테스트 데이터 · 실제 쓰레기 배출에 사용하지 마세요';

  @override
  String get today => '오늘';

  @override
  String get tomorrow => '내일';

  @override
  String get searchTab => '분리배출';

  @override
  String get placesTab => '자원 회수 장소';

  @override
  String get chooseArea => '지역 선택';

  @override
  String get fictionalAreas => '테스트용 가상 지역입니다.';

  @override
  String areaName(String area) {
    return '도시마구 · 샘플 지역 $area';
  }

  @override
  String get areaSaveError => '저장하지 못했습니다. 설정은 변경되지 않았습니다. 다시 시도해 주세요.';

  @override
  String sourceOpenError(String url) {
    return '공식 페이지를 열지 못했습니다.\n$url';
  }

  @override
  String demoDate(String date) {
    return '$date 표시 예시';
  }

  @override
  String get upcoming => '앞으로의 수거 일정';

  @override
  String get officialToshima => '도시마구 공식 정보 확인 (일본어)';

  @override
  String get official => '공식 정보 확인 (일본어)';

  @override
  String get checkTime => '배출 방법과 시간은 공식 정보를 확인하세요';

  @override
  String get noCollection => '수거 없음';

  @override
  String get uncertain => '수거 일정 확인이 필요합니다';

  @override
  String get burnable => '태우는 쓰레기';

  @override
  String get recyclables => '재활용 자원';

  @override
  String get metals => '금속·도자기·유리';

  @override
  String get searchTitle => '어떻게 버리나요?';

  @override
  String get searchSubtitle => '물품 이름으로 검색하세요.';

  @override
  String get itemName => '물품 이름';

  @override
  String get searchHint => '예: 건전지, 페트병';

  @override
  String get noResults => '검색 결과가 없습니다. 다른 이름으로 검색하거나 공식 정보를 확인하세요.';

  @override
  String get disposal => '배출 방법 확인';

  @override
  String get disposalAndPlaces => '배출 방법 및 전용 회수 장소';

  @override
  String get sampleSorting => '분리배출 안내 예시';

  @override
  String get findPlaces => '전용 회수 장소 찾기';

  @override
  String get officialDisposal => '공식 배출 방법 확인 (일본어)';

  @override
  String get placesSubtitle =>
      '전지·소형 가전·형광등 등의 반납 장소입니다.\n일반 쓰레기는 ‘오늘’에서 확인하세요.';

  @override
  String get damageQuestion => '부풀거나 파손되었나요?';

  @override
  String get noDamage => '아니요';

  @override
  String get damagedOrUnknown => '예 / 모르겠어요';

  @override
  String get damageWarning => '일반 회수함에 넣지 마세요. 상태를 확인하고 구청 공식 안내에서 문의처를 확인하세요.';

  @override
  String get officialBattery => '공식 전지 회수 방법 및 문의처 (일본어)';

  @override
  String placesCount(int count) {
    return '샘플 회수 장소 ($count곳)';
  }

  @override
  String get fictionalPoints => '가상의 장소입니다. 방문하지 마세요.';

  @override
  String get noPoints => '이 물품의 확인된 회수 장소가 아직 없습니다. 구청 공식 안내를 확인하세요.';

  @override
  String get conditions => '접수 조건 확인';

  @override
  String samplePoint(String point) {
    return '샘플 회수 장소 $point';
  }

  @override
  String get samplePointDetail => '테스트용 가상 회수 장소';

  @override
  String acceptedItems(String items) {
    return '접수 품목 예시: $items';
  }

  @override
  String get pointConditions =>
      '접수 시간·조건: 미등록\n실제 반납 장소가 아니며 경로 안내를 제공하지 않습니다.';

  @override
  String get mapTitle => '회수 장소 지도';

  @override
  String get mapUnavailable => '지도가 아직 연결되지 않았습니다.\n아래 목록에서 시제품을 이용해 볼 수 있습니다.';

  @override
  String get aboutBody =>
      '가상의 일정, 지역, 회수 장소를 사용하는 개발용 예시입니다. 실제 쓰레기 배출에는 사용하지 마세요.\n\n지역, 언어, 알림 설정은 기기에 저장됩니다. 사진이나 위치 정보는 수집하지 않습니다.';

  @override
  String get dryBattery => '건전지';

  @override
  String get rechargeable => '충전지';

  @override
  String get appliance => '소형 가전';

  @override
  String get lamp => '형광등';

  @override
  String get dryBatteryHint => '전지 종류와 상태를 확인한 후 회수 장소를 선택하세요.';

  @override
  String get rechargeableHint => '건전지 회수함에 넣지 마세요. 종류와 상태에 맞는 방법을 확인하세요.';

  @override
  String get applianceHint => '접수 품목, 투입구 크기, 내장 전지 처리 규정을 확인하세요.';

  @override
  String get lampHint => '깨진 형광등과 LED 전구는 처리 방법이 다르므로 공식 안내를 확인하세요.';

  @override
  String get food => '음식물 쓰레기';

  @override
  String get pet => '페트병';

  @override
  String get cans => '캔·유리병';

  @override
  String get bulky => '가구·대형 쓰레기';

  @override
  String get foodGuidance => '태우는 쓰레기 안내 예시: 물기를 제거한 후 배출하세요.';

  @override
  String get recyclingGuidance => '재활용 자원 안내 예시: 정기 수거일과 배출 방법을 확인하세요.';

  @override
  String get dryBatteryGuidance => '전지 종류에 맞는 회수 방법을 확인하세요.';

  @override
  String get rechargeableGuidance => '종류와 부풀음·파손 여부에 따라 처리 방법이 다릅니다.';

  @override
  String get applianceGuidance => '크기 제한과 내장 전지 처리 규정을 확인하세요.';

  @override
  String get lampGuidance => '형광등과 LED 전구의 규정을 각각 확인하세요.';

  @override
  String get bulkyGuidance =>
      '대형 쓰레기 규정은 크기와 품목에 따라 다릅니다. 구청의 품목 안내와 신청 정보를 확인하세요.';

  @override
  String collectionArea(String area) {
    return '쓰레기 수거 지역: $area';
  }

  @override
  String get setupAreaTitle => '샘플 지역 설정';

  @override
  String get confirmAreaTitle => '이 지역을 사용할까요?';

  @override
  String candidateArea(String area) {
    return '설정할 지역: $area';
  }

  @override
  String currentArea(String area) {
    return '현재 설정: $area';
  }

  @override
  String get confirmAreaAction => '이 지역 저장';

  @override
  String get chooseAgain => '다시 선택';

  @override
  String get savingArea => '저장 중…';

  @override
  String get setupRecovery => '지역 설정을 읽을 수 없습니다. 다시 선택해 주세요.';

  @override
  String get cancel => '취소';

  @override
  String collectionDeadline(String time) {
    return '$time까지 배출';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item: $time까지 배출';
  }

  @override
  String get chooseCollectionItem => '가져갈 물품의 종류를 선택해 주세요.';

  @override
  String backToItem(String item) {
    return '$item 안내로 돌아가기';
  }

  @override
  String get close => '닫기';

  @override
  String get widgetLabel => '쓰레기 수거 일정';

  @override
  String get widgetSample => '개발용 예시';

  @override
  String get widgetNext => '다음 일정';

  @override
  String get widgetOfferTitle => '홈 화면에 쓰레기 수거 일정 표시';

  @override
  String get widgetOfferBody => '앱을 열지 않고 날짜와 쓰레기 종류를 확인합니다.';

  @override
  String get widgetAdd => '추가';

  @override
  String get widgetSkip => '건너뛰기';

  @override
  String get widgetSettings => '홈 화면 위젯';

  @override
  String get widgetAdded => '홈 화면에 추가되었습니다';

  @override
  String get widgetRequested => '추가를 요청했습니다. 시스템 창에서 확인하세요.';

  @override
  String get widgetUnsupported => '홈 화면을 길게 누르고 위젯에서 Gomimap을 추가하세요.';

  @override
  String get widgetFailure => '추가 요청에 실패했습니다. 다시 시도하거나 홈 화면에서 추가하세요.';

  @override
  String get widgetSaveError => '선택을 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get disposalDeadlinePassed => '쓰레기 배출 마감 시간이 지났습니다';

  @override
  String get notifications => '쓰레기 수거 알림';

  @override
  String get notificationIntro => '수거일 아침에 알려드립니다.';

  @override
  String get notificationEnabled => '아침 알림';

  @override
  String get notificationEvening => '전날 저녁에도 알림';

  @override
  String get notificationSave => '저장';

  @override
  String get notificationLater => '나중에';

  @override
  String get notificationPermission => '이 기기에서 알림이 허용되지 않았습니다';

  @override
  String get notificationOsSettings => '기기 알림 설정 열기';

  @override
  String get notificationNone => '예약할 수 있는 수거 일정이 없습니다';

  @override
  String get notificationFixture => '일반 앱은 예시 알림을 예약하지 않습니다';

  @override
  String notificationReserved(int count) {
    return '예약됨: $count개';
  }

  @override
  String notificationPreview(int count) {
    return '시험 시계: 알림 $count개 미리보기';
  }

  @override
  String notificationNext(String when) {
    return '다음 알림: $when';
  }

  @override
  String get notificationError => '저장하거나 적용하지 못했습니다. 설정과 알림 예약을 확인하세요.';

  @override
  String get notificationRetry => '다시 시도';

  @override
  String get notificationTest => '시험 알림 표시';

  @override
  String notificationMorningTitle(String date) {
    return '오늘 $date의 쓰레기';
  }

  @override
  String notificationEveningTitle(String date) {
    return '내일 $date 준비';
  }

  @override
  String notificationTestTitle(String title) {
    return '시험: $title';
  }

  @override
  String get notificationChangedArea => '다른 수거 지역의 알림입니다. 현재 지역을 표시합니다.';

  @override
  String get notificationUpdated => '이 알림 이후 일정이 변경되었습니다.';

  @override
  String get notificationOfferTitle => '수거일에 알림 받기';
}
