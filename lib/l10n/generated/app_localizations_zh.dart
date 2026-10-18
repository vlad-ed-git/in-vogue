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
  String get tabHome => '首页';

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
  String planFree(int outfits) {
    return '免费版 · 还剩 $outfits 套穿搭';
  }

  @override
  String get planNoOutfits => '免费版 · 穿搭已用完';

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
  String get logOut => '退出登录';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get proName => 'In Vogue Pro';

  @override
  String get proLine => '更多穿搭，更多选择。';

  @override
  String get proBenefitDaily => '每天一套新穿搭';

  @override
  String get proBenefitChoice => '更多穿搭任你挑选';

  @override
  String get proBenefitCollection => '浏览完整系列';

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
  String get facePhotoTitle => '添加一张自拍';

  @override
  String get facePhotoLine => '可选。用于肤色与色彩分析。';

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
  String get facePhotoUse => '用于色彩分析';

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
  String get loading => '加载中';

  @override
  String get photoLookStraight => '这张照片里你的脸转向一侧或歪斜。请选择一张直视前方的照片。';

  @override
  String get photoMoveCloser => '这张照片里你的脸太小了。请选择一张更近的照片。';

  @override
  String get photoShowWholeFace => '这张照片里你的脸有一部分被裁掉了。请选择一张能看到整张脸的照片。';

  @override
  String get photoOnlyYou => '这张照片里不止一个人。请选择一张只有你的照片。';

  @override
  String get photoStandHeadToToe => '这张照片里看不到你站立的样子。请选择一张从头到脚的站姿照片。';

  @override
  String get tabMirror => '镜子';

  @override
  String get selfieTitle => '找到适合你的颜色';

  @override
  String get selfieLine => '添加一张自拍，用于肤色与色彩分析。';

  @override
  String get readingColours => '正在分析你的颜色…';

  @override
  String get yourSeason => '你的色彩季型';

  @override
  String get seasonLightSpring => '浅春型';

  @override
  String get seasonTrueSpring => '暖春型';

  @override
  String get seasonBrightSpring => '净春型';

  @override
  String get seasonLightSummer => '浅夏型';

  @override
  String get seasonTrueSummer => '冷夏型';

  @override
  String get seasonSoftSummer => '柔夏型';

  @override
  String get seasonSoftAutumn => '柔秋型';

  @override
  String get seasonTrueAutumn => '暖秋型';

  @override
  String get seasonDarkAutumn => '深秋型';

  @override
  String get seasonDarkWinter => '深冬型';

  @override
  String get seasonTrueWinter => '冷冬型';

  @override
  String get seasonBrightWinter => '净冬型';

  @override
  String get adviceLightSpring => '清新柔和的颜色最适合你：蜜桃色、珊瑚色和暖调水绿色。';

  @override
  String get adviceTrueSpring => '明亮阳光的颜色最适合你：罂粟红、金黄色和绿松石色。';

  @override
  String get adviceBrightSpring => '鲜艳的暖色最适合你：亮珊瑚色、柠檬黄和天蓝色。';

  @override
  String get adviceLightSummer => '轻盈的粉彩色最适合你：粉蓝、薰衣草紫和玫瑰粉。';

  @override
  String get adviceTrueSummer => '柔和的冷色最适合你：石板蓝、覆盆子红和柔和的蓝绿色。';

  @override
  String get adviceSoftSummer => '低饱和的烟熏色最适合你：灰粉色、鼠尾草绿和灰蓝色。';

  @override
  String get adviceSoftAutumn => '低饱和的大地色最适合你：卡其色、苔藓绿和暖灰褐色。';

  @override
  String get adviceTrueAutumn => '浓郁的大地色最适合你：铁锈红、橄榄绿、芥末黄和蓝绿色。';

  @override
  String get adviceDarkAutumn => '深沉的暖色最适合你：巧克力色、森林绿和焦橙色。';

  @override
  String get adviceDarkWinter => '深沉的冷色最适合你：酒红色、松绿色和深海军蓝。';

  @override
  String get adviceTrueWinter => '清透的冷色最适合你：正红色、宝蓝色和祖母绿。';

  @override
  String get adviceBrightWinter => '鲜艳冰冷的颜色最适合你：紫红色、钴蓝色和纯白色。';

  @override
  String colourFacts(String undertone, String depth, String contrast) {
    String _temp0 = intl.Intl.selectLogic(undertone, {
      'warm': '暖',
      'cool': '冷',
      'other': '中性',
    });
    String _temp1 = intl.Intl.selectLogic(depth, {
      'light': '浅',
      'deep': '深',
      'other': '中等',
    });
    String _temp2 = intl.Intl.selectLogic(contrast, {
      'high': '高',
      'low': '低',
      'other': '中',
    });
    return '$_temp0调 · $_temp1色度 · $_temp2对比';
  }

  @override
  String get coloursSuit => '适合你的颜色';

  @override
  String get coloursNeutrals => '你的中性色';

  @override
  String get coloursGoEasy => '少穿这些颜色';

  @override
  String get coloursUnclear => '照片不够清晰，所以这只是一个参考。白天光线下正面的自拍效果更好。';

  @override
  String get wardrobeTitle => '我的衣橱';

  @override
  String get colourFailed => '这次没能分析出你的颜色。';

  @override
  String get colourPhotoProblem => '这张照片无法识别你的脸。白天光线下正面的特写效果最好。';

  @override
  String get colourNoCredit => '暂时无法再进行色彩分析。';

  @override
  String get colourUnavailable => '此版本暂不支持色彩分析。';

  @override
  String get redoAnalysisTitle => '要重新进行肤色分析吗？';

  @override
  String get redoAnalysisLine => '你的颜色保持不变：换一张照片不会改变你。重新分析即可从这张照片读取。';

  @override
  String get redoAnalysis => '重新分析肤色';

  @override
  String get keepColours => '保留我的颜色';

  @override
  String get coloursUpdated => '你的颜色已更新。';

  @override
  String get wardrobeEmpty => '添加你自己衣服搭配的照片。';

  @override
  String get addOutfit => '添加一套搭配';

  @override
  String get addOutfitLine => '一张你自己的搭配照片，以及它适合什么。';

  @override
  String get outfitName => '名称';

  @override
  String get outfitColours => '颜色';

  @override
  String get outfitWeather => '天气';

  @override
  String get outfitOccasion => '场合';

  @override
  String get saveOutfit => '保存到我的衣橱';

  @override
  String get removeOutfit => '从我的衣橱移除';

  @override
  String get removeOutfitTitle => '要移除这套搭配吗？';

  @override
  String get colourBlack => '黑色';

  @override
  String get colourWhite => '白色';

  @override
  String get colourGrey => '灰色';

  @override
  String get colourBeige => '米色';

  @override
  String get colourBrown => '棕色';

  @override
  String get colourNavy => '藏青色';

  @override
  String get colourBlue => '蓝色';

  @override
  String get colourGreen => '绿色';

  @override
  String get colourRed => '红色';

  @override
  String get colourPink => '粉色';

  @override
  String get colourPurple => '紫色';

  @override
  String get colourYellow => '黄色';

  @override
  String get colourOrange => '橙色';

  @override
  String get colourMixed => '多色';

  @override
  String colourName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'white': '白色',
      'ivory': '象牙白',
      'cream': '奶油色',
      'stone': '石色',
      'beige': '米色',
      'sand': '沙色',
      'camel': '驼色',
      'tan': '棕褐色',
      'taupe': '灰褐色',
      'greige': '灰米色',
      'lightGrey': '浅灰色',
      'silver': '银色',
      'grey': '灰色',
      'charcoal': '炭灰色',
      'black': '黑色',
      'chocolate': '巧克力色',
      'espresso': '浓缩咖啡色',
      'coffee': '咖啡色',
      'brown': '棕色',
      'cinnamon': '肉桂色',
      'rust': '铁锈红',
      'brick': '砖红色',
      'terracotta': '赤陶色',
      'burntOrange': '焦橙色',
      'orange': '橙色',
      'apricot': '杏色',
      'peach': '蜜桃色',
      'salmon': '三文鱼色',
      'coral': '珊瑚色',
      'poppy': '罂粟红',
      'red': '红色',
      'burgundy': '酒红色',
      'wine': '葡萄酒色',
      'blush': '浅粉色',
      'orchid': '兰花色',
      'dustyRose': '灰粉色',
      'mauve': '藕荷色',
      'raspberry': '覆盆子红',
      'berry': '浆果色',
      'fuchsia': '紫红色',
      'hotPink': '亮粉色',
      'watermelon': '西瓜红',
      'lemon': '柠檬黄',
      'buttercup': '奶油黄',
      'mustard': '芥末黄',
      'gold': '金色',
      'ochre': '赭石色',
      'mint': '薄荷绿',
      'sage': '鼠尾草绿',
      'moss': '苔藓绿',
      'olive': '橄榄绿',
      'khaki': '卡其色',
      'leafGreen': '叶绿色',
      'lime': '青柠色',
      'emerald': '祖母绿',
      'jade': '玉绿色',
      'forestGreen': '森林绿',
      'pine': '松绿色',
      'teal': '蓝绿色',
      'deepTeal': '深蓝绿色',
      'turquoise': '绿松石色',
      'aqua': '水绿色',
      'skyBlue': '天蓝色',
      'powderBlue': '粉蓝色',
      'periwinkle': '长春花蓝',
      'cornflower': '矢车菊蓝',
      'denim': '牛仔蓝',
      'slateBlue': '石板蓝',
      'royalBlue': '宝蓝色',
      'cobalt': '钴蓝色',
      'azure': '蔚蓝色',
      'navy': '藏青色',
      'midnight': '午夜蓝',
      'lavender': '薰衣草紫',
      'lilac': '丁香紫',
      'violet': '紫罗兰色',
      'purple': '紫色',
      'plum': '李子色',
      'aubergine': '茄紫色',
      'other': '颜色',
    });
    return '$_temp0';
  }

  @override
  String get tipSuits => '适合靠近脸部穿：上衣、衬衫、针织衫和外套。';

  @override
  String get tipNeutrals => '能搭配你的颜色的基础色：裤子、裙子和大衣。';

  @override
  String get tipGoEasy => '远离脸部，或穿在下身：裤子和裙子。';

  @override
  String get analysisLink => '查看完整分析';

  @override
  String get analysisTitle => '你的肤色分析';

  @override
  String get analysisRead => '从你的照片读取';

  @override
  String get featureSkin => '皮肤';

  @override
  String get featureHair => '头发';

  @override
  String get featureBrows => '眉毛';

  @override
  String get featureEyes => '眼睛';

  @override
  String get featureLips => '嘴唇';

  @override
  String get analysisUndertone => '肤色底调';

  @override
  String get analysisDepth => '深浅';

  @override
  String get analysisContrast => '对比度';

  @override
  String undertoneAbout(String undertone) {
    String _temp0 = intl.Intl.selectLogic(undertone, {
      'warm': '暖调：你的皮肤偏金黄，所以温暖的大地色和金色会让你更有光彩。',
      'cool': '冷调：你的皮肤偏粉，所以清爽的冷色最适合你。',
      'other': '中性：你的皮肤介于金黄与粉之间，两种都能穿；你的发色会决定偏向。',
    });
    return '$_temp0';
  }

  @override
  String depthAbout(String depth) {
    String _temp0 = intl.Intl.selectLogic(depth, {
      'light': '浅：你的皮肤和头发偏浅，所以更浅、更柔和的颜色让你更出众。',
      'deep': '深：你的整体色彩偏深，所以浓郁深沉的颜色最适合你。',
      'other': '中等：你的整体色彩居中，所以中等深浅的颜色最适合你。',
    });
    return '$_temp0';
  }

  @override
  String contrastAbout(String contrast) {
    String _temp0 = intl.Intl.selectLogic(contrast, {
      'high': '高：你的发色与肤色对比鲜明，所以大胆的搭配最适合你。',
      'low': '低：你的五官色彩柔和融合，所以同色系搭配最适合你。',
      'other': '中等：你的五官对比柔和，所以中等对比效果最好。',
    });
    return '$_temp0';
  }

  @override
  String get analysisNote => 'YouCam 从你的照片读取这些颜色。季型是我们据此给出的建议。';
}
