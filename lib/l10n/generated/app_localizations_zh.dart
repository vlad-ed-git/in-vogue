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
  String get tagline => '以时尚穿搭，迎接明天的天气';

  @override
  String get welcomeDescription => '看看自己穿上为明天天气挑选的搭配，每件单品都附购买链接。';

  @override
  String get useMyLocation => '使用我的位置';

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
  String weatherFrom(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': '$time后有雨',
      'showers': '$time后有阵雨',
      'drizzle': '$time后有毛毛雨',
      'snow': '$time后有雪',
      'storm': '$time后有雷雨',
      'other': '$time后有大风',
    });
    return '$_temp0';
  }

  @override
  String weatherUntil(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': '雨持续到$time',
      'showers': '阵雨持续到$time',
      'drizzle': '毛毛雨持续到$time',
      'snow': '雪持续到$time',
      'storm': '雷雨持续到$time',
      'other': '大风持续到$time',
    });
    return '$_temp0';
  }

  @override
  String weatherAllDay(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': '全天有雨',
      'showers': '全天有阵雨',
      'drizzle': '全天有毛毛雨',
      'snow': '全天有雪',
      'storm': '全天有雷雨',
      'other': '全天大风',
    });
    return '$_temp0';
  }

  @override
  String weatherSky(String sky) {
    String _temp0 = intl.Intl.selectLogic(sky, {
      'clear': '晴',
      'partlyCloudy': '多云',
      'cloudy': '阴',
      'fog': '有雾',
      'other': '全天无雨',
    });
    return '$_temp0';
  }

  @override
  String dayDatePlace(String day, String date, String place) {
    return '$day，$date · $place';
  }

  @override
  String dayDate(String day, String date) {
    return '$day，$date';
  }

  @override
  String get weatherUnavailable => '无法获取天气。';

  @override
  String weatherSaved(String savedAt) {
    return '显示的是$savedAt保存的天气预报。';
  }

  @override
  String get picksTitle => '挑几件你喜欢的';

  @override
  String picksLine(String heart) {
    return '为这种天气挑几件，点 $heart 收藏。我们会记住你的喜好。';
  }

  @override
  String get heartSpoken => '爱心';

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
  String get gettingOutfitReady => '正在准备你的穿搭…';

  @override
  String get tryOnFailed => '这次没能为你换上穿搭。你的照片没有问题。';

  @override
  String get locationOff => 'In Vogue 需要你的位置来获取天气。';

  @override
  String get locationUnavailable => '我们找不到你的位置。';

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
  String get photoUnreadable => '无法打开这张照片，请换一张。';

  @override
  String get photoTooSmall => '这张照片太小了，请换一张更大的。';

  @override
  String get photoUnusable => '无法使用这张照片，请换一张。';

  @override
  String get photoConverted => '我们更改了这张照片的格式，以便使用。不喜欢？请换一张。';

  @override
  String get addPhotoOfYou => '添加一张你的照片';

  @override
  String get bodyPhotoWhy => '我们会用这张照片为你换上每套搭配。';

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

  @override
  String get signInWithApple => '通过 Apple 登录';

  @override
  String get signInWithGoogle => '通过 Google 登录';

  @override
  String get signInTitle => '登录';

  @override
  String get signInLine => '你的照片和收藏会一起保留。然后我们为你准备第一套穿搭。';

  @override
  String get signInFailed => '登录失败，请重试。';

  @override
  String get aboutYouTitle => '我们该怎么称呼你？';

  @override
  String get yourName => '你的名字';

  @override
  String get facePhotoTitle => '添加一张面部照片';

  @override
  String get facePhotoLine => '可选。让妆容更适合你。';

  @override
  String get addWidgetTitle => '把 In Vogue 添加到主屏幕';

  @override
  String get addWidgetLine => '无需打开应用，即可查看明天的天气和你的穿搭。';

  @override
  String get addToHomeScreen => '添加到主屏幕';

  @override
  String get skip => '跳过';

  @override
  String get widgetStepsTitle => '在 iPhone 上只需三步';

  @override
  String get widgetAddByHand => '请在主屏幕上添加：长按屏幕，点按“小组件”，选择 In Vogue。';

  @override
  String widgetPreviewSpoken(String weather) {
    return '$weather你的穿搭正在准备中。';
  }

  @override
  String get tryOnPhotoProblem => '这张照片无法换装。换一张照片或许可以。';

  @override
  String get tryOnNoCredit => '目前无法再生成新的穿搭。';

  @override
  String get tryOnUnavailable => '此版本暂不提供穿搭。';

  @override
  String get shop => '选购';

  @override
  String get shopThisOutfit => '选购这套穿搭';

  @override
  String get aboutThisOutfit => '关于这套穿搭';

  @override
  String tryOnPiece(int piece, int pieces) {
    return '第 $piece 件，共 $pieces 件';
  }

  @override
  String outfitPhotoSpoken(String about) {
    return '你从头到脚穿着这套穿搭。$about';
  }

  @override
  String get noPicks => '你还没有挑选任何单品。';

  @override
  String get removePickTitle => '从我的心选中移除？';

  @override
  String get remove => '移除';

  @override
  String get keep => '保留';

  @override
  String get outfitsTab => '穿搭';

  @override
  String get weatherHot => '炎热';

  @override
  String get weatherWarm => '温暖';

  @override
  String get weatherMild => '温和';

  @override
  String get weatherCool => '凉爽';

  @override
  String get weatherCold => '寒冷';

  @override
  String get weatherRain => '雨天';

  @override
  String feelsLikeFrom(int low) {
    return '体感 $low° 及以上';
  }

  @override
  String feelsLikeRange(int low, int high) {
    return '体感 $low–$high°';
  }

  @override
  String feelsLikeBelow(int high) {
    return '体感低于 $high°';
  }

  @override
  String get waterResistantPieces => '防泼水单品';

  @override
  String get edit => '编辑';

  @override
  String get replace => '更换';

  @override
  String get add => '添加';

  @override
  String get save => '保存';

  @override
  String signedInWith(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'apple': '已通过 Apple 登录',
      'other': '已通过 Google 登录',
    });
    return '$_temp0';
  }

  @override
  String get bodyPhoto => '全身照';

  @override
  String get bodyPhotoUse => '用于为你换装';

  @override
  String get facePhoto => '面部照片';

  @override
  String get facePhotoUse => '用于妆容';

  @override
  String get notAdded => '尚未添加';

  @override
  String get membership => '会员';

  @override
  String get planPro => 'Pro';

  @override
  String get planFreeName => '免费方案';

  @override
  String get location => '位置';

  @override
  String locationWhileUsing(String city) {
    return '$city，使用应用期间';
  }

  @override
  String get locationNotSet => '未设置';

  @override
  String get defaultDay => '默认日期';

  @override
  String get homeScreenWidget => '主屏幕小组件';

  @override
  String get defaultDayTomorrow => '明天；早上 6 点到 9 点显示今天';

  @override
  String get defaultDayTitle => '首页打开时显示';

  @override
  String get deleteAccountTitle => '删除你的账户？';

  @override
  String get deleteAccountLine =>
      '你的资料、照片、心选和穿搭将被删除。你需要通过 Apple 或 Google 确认。此操作无法撤销。';

  @override
  String get keepAccount => '保留我的账户';

  @override
  String get makeupFailed => '这次没能为你生成妆容。你的照片没有问题。';

  @override
  String get makeupPhotoProblem => '这张照片里找不到你的脸。在自然光下正面拍摄的近照效果最好。';

  @override
  String get makeupNoCredit => '目前无法再生成新的妆容。';

  @override
  String get makeupUnavailable => '此版本暂不提供妆容。';

  @override
  String makeupFor(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': '今天的妆容',
      'other': '明天的妆容',
    });
    return '$_temp0';
  }

  @override
  String get makeupStepsArriving => '每一步完成后就会出现在这里。';

  @override
  String makeupStepCount(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      'three': '三个步骤',
      'four': '四个步骤',
      'five': '五个步骤',
      'six': '六个步骤',
      'other': '步骤',
    });
    return '$_temp0';
  }

  @override
  String cheekColour(String colour) {
    String _temp0 = intl.Intl.selectLogic(colour, {
      'soft_pink': '柔粉色',
      'peach': '蜜桃色',
      'rose': '玫瑰色',
      'terracotta': '赤陶色',
      'other': '柔和',
    });
    return '$_temp0';
  }

  @override
  String lipColour(String colour) {
    String _temp0 = intl.Intl.selectLogic(colour, {
      'nude': '裸色',
      'rosy_nude': '玫瑰裸色',
      'rose': '玫瑰色',
      'terracotta': '赤陶色',
      'red': '红色',
      'berry': '莓果色',
      'brick': '砖红色',
      'other': '柔和',
    });
    return '$_temp0';
  }

  @override
  String lookSentence(String cheeks, String lips, String palette) {
    String _temp0 = intl.Intl.selectLogic(palette, {
      'warm': '你的暖调中性色',
      'cool': '你的冷调中性色',
      'mixed': '你的中性色',
      'other': '你身上的颜色',
    });
    return '$cheeks腮红配$lips唇妆，呼应$_temp0。';
  }

  @override
  String get makeupWaitsForOutfit => '妆容会搭配你的穿搭，穿搭正在准备中。';

  @override
  String makeupNeedsOutfit(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': '今天还没有可搭配的穿搭。',
      'other': '明天还没有可搭配的穿搭。',
    });
    return '$_temp0';
  }

  @override
  String get yourLastLook => '你上一次的妆容';

  @override
  String get makeupFacePhotoLine => '妆容会画在你自己的脸上。';

  @override
  String get makeupShadesNeutral => '想让色号更适合你，请使用在自然光下正面拍摄的面部照片。';
}
