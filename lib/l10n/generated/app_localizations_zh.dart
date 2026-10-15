// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'In Vogue';

  @override
  String get tagline => '以时尚穿搭，迎接明天的天气。';

  @override
  String get welcomeDescription => '穿搭随天气，妆容配风格。';

  @override
  String get language => '语言';

  @override
  String get cacheFailure => '无法保存更改，请重试。';

  @override
  String get networkFailure => '网络已断开，请检查网络连接。';

  @override
  String get serverFailure => '出现了一些问题，请重试。';

  @override
  String get startupFailure => 'In Vogue 无法启动，请重试。';

  @override
  String get retry => '重试';

  @override
  String get back => '返回';

  @override
  String get close => '关闭';

  @override
  String setupFolio(int step, int total) {
    return '$step / $total';
  }

  @override
  String get yourPicks => '我的心选';

  @override
  String yourPicksCount(int count) {
    return '我的心选 · $count';
  }

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get before => '妆前';

  @override
  String get after => '妆后';

  @override
  String get tabHome => '首页';

  @override
  String get tabMakeup => '妆容';

  @override
  String get tabSettings => '设置';

  @override
  String temperatureSpoken(int temperature) {
    return '$temperature 度';
  }

  @override
  String feelsLike(int temperature) {
    return '体感 $temperature°';
  }

  @override
  String weatherSpoken(int temperature, String condition, int feelsLike) {
    return '$temperature 度，$condition，体感 $feelsLike 度。';
  }

  @override
  String weatherSpokenWithDay(
    String day,
    int temperature,
    String condition,
    int feelsLike,
  ) {
    return '$day，$temperature 度，$condition，体感 $feelsLike 度。';
  }

  @override
  String get occasionWork => '工作';

  @override
  String get occasionCasual => '休闲';

  @override
  String get occasionGoingOut => '外出';

  @override
  String get occasionStayingIn => '宅家';

  @override
  String get occasionWorkKicker => '工作日';

  @override
  String get occasionCasualKicker => '休闲';

  @override
  String get occasionGoingOutKicker => '外出';

  @override
  String get occasionStayingInKicker => '宅家';

  @override
  String get change => '更改';

  @override
  String dayIs(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': '今天是',
      'other': '明天是',
    });
    return '$_temp0';
  }

  @override
  String aiPreviewCredit(String brand) {
    return 'AI 预览 · 服装来自 $brand';
  }

  @override
  String outfitsByCredit(String brand) {
    return '服装来自 $brand';
  }

  @override
  String get gettingOutfitReady => '正在准备你的穿搭…';

  @override
  String get tryOnFailed => '这次没能为你换上穿搭。你的照片没有问题。';

  @override
  String get locationOff => 'In Vogue 需要你的位置来获取天气。';

  @override
  String get openSettings => '打开设置';

  @override
  String offlineSaved(String savedAt) {
    return '当前离线。这是 $savedAt 保存的穿搭。';
  }

  @override
  String savedAt(String date, String time) {
    return '$date $time';
  }

  @override
  String everyLookSeen(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': '适合今天的穿搭你都看过了。新单品即将上架。',
      'other': '适合明天的穿搭你都看过了。新单品即将上架。',
    });
    return '$_temp0';
  }

  @override
  String get notFullLength => '这张照片没有拍到你的全身。';

  @override
  String get chooseAnotherPhoto => '选择另一张照片';

  @override
  String get chooseDifferentPhoto => '换一张照片';

  @override
  String get chooseFromPhotos => '从“照片”中选择';

  @override
  String get chooseFromGallery => '从相册中选择';

  @override
  String get continueAction => '继续';

  @override
  String get example => '示例';

  @override
  String get yourPhoto => '你的照片';

  @override
  String get photoPasses => '照片符合要求';

  @override
  String get photoHeadToToe => '全身入镜';

  @override
  String get photoStanding => '站立，面向镜头';

  @override
  String get photoGoodLight => '光线充足';

  @override
  String get photoJustYou => '仅你一人';

  @override
  String get photoCloseUp => '近景';

  @override
  String get photoFacingForward => '面向镜头';

  @override
  String get photoDaylight => '自然光';

  @override
  String get photoHairOff => '头发不遮脸';

  @override
  String get bodyPhotoPrivacy => '你的照片只用于为你换上穿搭，可随时更换。';

  @override
  String get exampleBodySpoken => '示例：一位女性的全身正面照，光线均匀';

  @override
  String get exampleFaceSpoken => '示例：一张在自然光下拍摄的正面脸部近照';

  @override
  String get otherOutfitsPreparing => '其他穿搭正在准备中。';

  @override
  String get otherOutfitsLocked => '其他穿搭为 Pro 专享。';

  @override
  String get goPro => '升级 Pro';

  @override
  String outfitTileSpoken(int index, int count) {
    return '第 $index 套，共 $count 套';
  }

  @override
  String outfitTileShownSpoken(int index, int count) {
    return '第 $index 套，共 $count 套，当前显示';
  }

  @override
  String get lockedSpoken => 'Pro 专享';

  @override
  String planFree(int outfits, int looks) {
    return '免费版 · 还剩 $outfits 套穿搭和 $looks 次妆容';
  }

  @override
  String get planNoOutfits => '免费版 · 穿搭已用完';

  @override
  String planMakeupLeft(int looks) {
    return '免费版 · 还剩 $looks 次妆容';
  }

  @override
  String get onProList => '已加入 Pro 名单 ✓';

  @override
  String loveSpoken(String name) {
    return '喜欢 $name';
  }

  @override
  String get loved => '已喜欢';

  @override
  String get loveThisColour => '喜欢这个颜色';

  @override
  String colourCount(int count) {
    return '$count 种颜色';
  }

  @override
  String moreColours(int count) {
    return '+$count';
  }

  @override
  String get proceed => '继续';

  @override
  String get done => '完成';

  @override
  String buyAt(String brand) {
    return '在 $brand 购买';
  }

  @override
  String noLongerAvailable(String brand) {
    return '$brand 已无货';
  }

  @override
  String catalogPhotoSpoken(String name, String colour) {
    return '$name，$colour，目录照片';
  }

  @override
  String get preparing => '准备中';

  @override
  String faceAfterStep(int step) {
    return '第 $step 步后的你';
  }

  @override
  String get faceWithLook => '完成妆容后的你';

  @override
  String get facePhotoSpoken => '你的脸部照片';

  @override
  String get logOut => '退出登录';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get proName => 'In Vogue Pro';

  @override
  String get proLine => '更多穿搭，更多选择，每套都有妆容。';

  @override
  String get proBenefitDaily => '每天一套新穿搭';

  @override
  String get proBenefitChoice => '更多穿搭任你挑选';

  @override
  String get proBenefitCollection => '浏览完整系列';

  @override
  String get proBenefitMakeup => '每套穿搭都有妆容';

  @override
  String get proPrice => '每月 \$7.99 · 或每年 \$59.99';

  @override
  String get onTheList => '你已在名单上。';

  @override
  String get proSoon => 'Pro 即将开放，你会第一个知道。';

  @override
  String get backToInVogue => '返回 In Vogue';

  @override
  String get widgetStepHold => '长按主屏幕';

  @override
  String get widgetStepPlus => '轻点 +';

  @override
  String get widgetStepChoose => '选择 In Vogue';

  @override
  String get widgetGettingReady => '准备中';

  @override
  String widgetSaved(String when) {
    return '保存于 $when';
  }
}
