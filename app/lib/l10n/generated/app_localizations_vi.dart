// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => 'Ngôn ngữ / Language';

  @override
  String get languageSaveError =>
      'Không lưu được ngôn ngữ. Vui lòng chọn lại vào lần sau.';

  @override
  String get about => 'Về bản thử nghiệm';

  @override
  String get sampleBanner => 'Dữ liệu mẫu · Không dùng để đổ rác thực tế';

  @override
  String get today => 'Hôm nay';

  @override
  String get tomorrow => 'Ngày mai';

  @override
  String get searchTab => 'Phân loại rác';

  @override
  String get placesTab => 'Điểm tái chế';

  @override
  String get chooseArea => 'Chọn khu vực';

  @override
  String get fictionalAreas => 'Các khu vực giả định để thử nghiệm.';

  @override
  String areaName(String area) {
    return 'Toshima · Khu vực mẫu $area';
  }

  @override
  String get areaSaveError =>
      'Không lưu được. Thiết lập chưa thay đổi. Vui lòng thử lại.';

  @override
  String sourceOpenError(String url) {
    return 'Không mở được trang chính thức.\n$url';
  }

  @override
  String demoDate(String date) {
    return 'Ví dụ cho ngày $date';
  }

  @override
  String get upcoming => 'Lịch thu gom sắp tới';

  @override
  String get officialToshima => 'Thông tin chính thức của Toshima (tiếng Nhật)';

  @override
  String get official => 'Thông tin chính thức (tiếng Nhật)';

  @override
  String get checkTime => 'Xem hướng dẫn và giờ đổ rác chính thức';

  @override
  String get noCollection => 'Không thu gom';

  @override
  String get uncertain => 'Cần xác nhận lịch thu gom';

  @override
  String get burnable => 'Rác cháy được';

  @override
  String get recyclables => 'Tài nguyên tái chế';

  @override
  String get metals => 'Kim loại, gốm sứ và thủy tinh';

  @override
  String get searchTitle => 'Bỏ món này thế nào?';

  @override
  String get searchSubtitle => 'Tìm theo tên đồ vật.';

  @override
  String get itemName => 'Tên đồ vật';

  @override
  String get searchHint => 'Ví dụ: pin, chai nhựa';

  @override
  String get noResults =>
      'Không tìm thấy. Hãy thử tên khác hoặc xem thông tin chính thức.';

  @override
  String get disposal => 'Hướng dẫn bỏ rác';

  @override
  String get disposalAndPlaces => 'Cách bỏ và điểm thu gom';

  @override
  String get sampleSorting => 'Hướng dẫn phân loại mẫu';

  @override
  String get findPlaces => 'Tìm điểm thu gom';

  @override
  String get officialDisposal => 'Hướng dẫn bỏ rác chính thức (tiếng Nhật)';

  @override
  String get placesSubtitle =>
      'Nơi nhận pin, thiết bị điện nhỏ và đèn huỳnh quang.\nVới rác thông thường, xem Hôm nay.';

  @override
  String get damageQuestion => 'Có bị phồng hoặc hỏng không?';

  @override
  String get noDamage => 'Không';

  @override
  String get damagedOrUnknown => 'Có / Không rõ';

  @override
  String get damageWarning =>
      'Không bỏ vào hộp thu gom thông thường. Kiểm tra tình trạng và xem hướng dẫn chính thức của quận để tìm nơi liên hệ.';

  @override
  String get officialBattery => 'Hướng dẫn thu gom pin và liên hệ (tiếng Nhật)';

  @override
  String placesCount(int count) {
    return 'Điểm thu gom mẫu ($count)';
  }

  @override
  String get fictionalPoints =>
      'Đây là địa điểm giả định. Không đến các địa điểm này.';

  @override
  String get noPoints =>
      'Chưa có điểm thu gom đã xác minh cho đồ vật này. Hãy xem hướng dẫn chính thức của quận.';

  @override
  String get conditions => 'Xem điều kiện tiếp nhận';

  @override
  String samplePoint(String point) {
    return 'Điểm thu gom mẫu $point';
  }

  @override
  String get samplePointDetail => 'Điểm thu gom giả định để thử nghiệm';

  @override
  String acceptedItems(String items) {
    return 'Ví dụ về đồ vật tiếp nhận: $items';
  }

  @override
  String get pointConditions =>
      'Giờ và điều kiện tiếp nhận: chưa đăng ký.\nĐây không phải nơi tiếp nhận thực tế. Không cung cấp chỉ đường.';

  @override
  String get mapTitle => 'Bản đồ thu gom';

  @override
  String get mapUnavailable =>
      'Chưa kết nối bản đồ.\nBạn có thể dùng thử danh sách bên dưới.';

  @override
  String get aboutBody =>
      'Lịch, khu vực và điểm thu gom là giả định, lấy ngày 5 tháng 10 năm 2026 làm mốc. Không dùng để đổ rác thực tế.\n\nChưa có thông báo, tiện ích và cài đặt vị trí. Bản thử nghiệm này không gửi thông báo.\n\nChỉ lưu khu vực mẫu và ngôn ngữ đã chọn. Không thu thập ảnh hay vị trí.';

  @override
  String get dryBattery => 'Pin khô';

  @override
  String get rechargeable => 'Pin sạc';

  @override
  String get appliance => 'Thiết bị điện nhỏ';

  @override
  String get lamp => 'Đèn huỳnh quang';

  @override
  String get dryBatteryHint =>
      'Kiểm tra loại và tình trạng pin trước khi chọn điểm thu gom.';

  @override
  String get rechargeableHint =>
      'Không bỏ vào hộp thu gom pin khô. Kiểm tra cách xử lý phù hợp với loại và tình trạng pin.';

  @override
  String get applianceHint =>
      'Kiểm tra đồ vật được nhận, kích thước khe bỏ và quy định về pin gắn trong.';

  @override
  String get lampHint =>
      'Đèn bị vỡ và bóng LED có cách xử lý khác. Hãy xem hướng dẫn chính thức.';

  @override
  String get food => 'Rác thực phẩm';

  @override
  String get pet => 'Chai PET';

  @override
  String get cans => 'Lon và chai thủy tinh';

  @override
  String get bulky => 'Đồ nội thất và rác cồng kềnh';

  @override
  String get foodGuidance =>
      'Ví dụ về rác cháy được: để ráo nước trước khi bỏ.';

  @override
  String get recyclingGuidance =>
      'Ví dụ về tái chế: kiểm tra ngày thu gom định kỳ và cách chuẩn bị.';

  @override
  String get dryBatteryGuidance => 'Kiểm tra cách thu gom theo loại pin.';

  @override
  String get rechargeableGuidance =>
      'Cách xử lý khác nhau tùy loại pin và tình trạng phồng hoặc hỏng.';

  @override
  String get applianceGuidance =>
      'Kiểm tra giới hạn kích thước và quy định về pin gắn trong.';

  @override
  String get lampGuidance =>
      'Kiểm tra riêng quy định về đèn huỳnh quang và bóng LED.';

  @override
  String get bulkyGuidance =>
      'Quy định về rác cồng kềnh tùy kích thước và loại đồ vật. Xem danh mục và thông tin đăng ký của quận.';

  @override
  String collectionArea(String area) {
    return 'Khu vực thu gom rác: $area';
  }

  @override
  String get setupAreaTitle => 'Chọn khu vực mẫu';

  @override
  String get confirmAreaTitle => 'Dùng khu vực này?';

  @override
  String candidateArea(String area) {
    return 'Khu vực sẽ lưu: $area';
  }

  @override
  String currentArea(String area) {
    return 'Thiết lập hiện tại: $area';
  }

  @override
  String get confirmAreaAction => 'Lưu khu vực này';

  @override
  String get chooseAgain => 'Chọn lại';

  @override
  String get savingArea => 'Đang lưu…';

  @override
  String get setupRecovery =>
      'Không đọc được thiết lập khu vực. Vui lòng chọn lại.';

  @override
  String get cancel => 'Hủy';
}
