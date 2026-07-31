import Foundation

/// 全界面文案（按语言实例化，与 Android I18n.kt 完全一致）
struct Strings {
    let appName: String
    let refresh: String
    let settings: String
    let back: String
    let close: String
    let confirm: String
    let delete: String
    // 主页
    let citySettings: String
    let addCity: String
    let noCities: String
    let noCitySelected: String
    let noWeatherData: String
    let weatherFetchFailed: String
    // 天气
    let feelsLike: String
    let wind: String
    let windSuffix: String
    let humidity: String
    let pressure: String
    let visibility: String
    let airQuality: String
    let forecast5Day: String
    let today: String
    // 设置页
    let settingsAppearance: String
    let displayMode: String
    let themeColor: String
    let settingsUnits: String
    let tempUnit: String
    let windUnit: String
    let settingsAlerts: String
    let alertEnable: String
    let alertOnDesc: String
    let alertOffDesc: String
    let alertMinSeverity: String
    let currentLocationLabel: String
    let currentLocationUnknown: String
    let currentLocationFallbackName: String
    let settingsData: String
    let refreshInterval: String
    let minutesUnit: String
    let settingsAbout: String
    let version: String
    let dataSource: String
    // 系统设置
    let settingsSystem: String
    let languageLabel: String
    let saveSettings: String
    let settingsSaved: String
    // 城市设置页
    let searchCityHint: String
    let searchResults: String
    let addedCities: String
    let noSearchResults: String
    let alreadyAdded: String
    let dragHint: String
    // 小组件与通知
    let widgetLoading: String
    let widgetUpdatePrefix: String
    let widgetFetchFailed: String
    // 组件设置
    let settingsWidgets: String
    let clockWidgetOpacity: String
    let weatherWidgetOpacity: String
    let widgetThemeColor: String
    let dewPoint: String
    let sunrise: String
    let sunset: String
    // 预报详情八项标签（日出/日落复用上方字段）
    let tempMaxLabel: String
    let tempMinLabel: String
    let feelsMaxLabel: String
    let feelsMinLabel: String
    let precipSumLabel: String
    let precipProbLabel: String
    let hourly24Title: String        // 24 小时预报卡标题
    let widgetThemeNames: [String]   // 动态/浅白/深空/蓝/绿/紫
    // 枚举翻译表
    let themeModes: [String]         // 浅色/深色/跟随系统
    let tempUnitNames: [String]      // 摄氏度/华氏度
    let windUnitNames: [String]      // 公里时/英里时/米秒
    let severityNames: [String]      // 普通/严重/紧急预警
    let aqiLevels: [String]          // 极佳/优良/勉强及格/轻度污染/严重污染/小心中毒/要命了
    let aqiAdvices: [[String]]      // AQI 各级趣味建议（7 组，每组多条随机使用，与 aqiLevels 对齐）
    let uvIndex: String              // 紫外线强度
    let uvLevels: [String]           // 极佳/勉强/暴晒/晒晕了/要命了
    let uvAdvices: [[String]]       // UVI 各级趣味建议（5 组，每组多条随机使用，与 uvLevels 对齐）
    let weatherDescs: [String]       // 26 项天气描述
    let windDirs: [String]           // 北/东北/东/东南/南/西南/西/西北
    let daysOfWeek: [String]         // 周日..周六
}

enum I18n {

    private static let zhCN = Strings(
        appName: "识天",
        refresh: "刷新", settings: "设置", back: "返回", close: "关闭", confirm: "确认", delete: "删除",
        citySettings: "城市设置", addCity: "添加城市", noCities: "还没有添加城市",
        noCitySelected: "未选择城市", noWeatherData: "暂无天气数据", weatherFetchFailed: "获取天气数据失败",
        feelsLike: "体感", wind: "风力", windSuffix: "风", humidity: "湿度", pressure: "气压",
        visibility: "能见度", airQuality: "空气质量", forecast5Day: "5日天气预报", today: "今天",
        settingsAppearance: "外观", displayMode: "显示模式", themeColor: "主题颜色",
        settingsUnits: "单位", tempUnit: "温度单位", windUnit: "风速单位",
        settingsAlerts: "恶劣天气预警", alertEnable: "开启预警通知",
        alertOnDesc: "已开启，后台定期检测", alertOffDesc: "已关闭", alertMinSeverity: "最低预警等级",
        currentLocationLabel: "当前定位", currentLocationUnknown: "未获取到定位，空气质量与紫外线预警暂不推送",
        currentLocationFallbackName: "当前位置",
        settingsData: "数据", refreshInterval: "自动刷新间隔", minutesUnit: "分钟",
        settingsAbout: "关于", version: "版本", dataSource: "数据来源",
        settingsSystem: "系统", languageLabel: "语言", saveSettings: "保存设置", settingsSaved: "设置已保存",
        searchCityHint: "搜索城市（中文或拼音）", searchResults: "搜索结果", addedCities: "已添加城市",
        noSearchResults: "未找到相关城市", alreadyAdded: "已添加", dragHint: "长按拖动可调整顺序",
        widgetLoading: "加载中...", widgetUpdatePrefix: "更新", widgetFetchFailed: "天气数据获取失败",
        settingsWidgets: "组件", clockWidgetOpacity: "时钟组件底板透明度", weatherWidgetOpacity: "气象组件底板透明度",
        widgetThemeColor: "组件主题颜色", dewPoint: "露点",
        sunrise: "日出", sunset: "日落",
        tempMaxLabel: "最高温度", tempMinLabel: "最低温度",
        feelsMaxLabel: "体感最高", feelsMinLabel: "体感最低",
        precipSumLabel: "降水量", precipProbLabel: "降水概率",
        hourly24Title: "24小时预报",
        widgetThemeNames: ["动态", "浅白", "深空", "晴空蓝", "青碧绿", "暮霭紫"],
        themeModes: ["浅色", "深色", "跟随系统"],
        tempUnitNames: ["摄氏度", "华氏度"],
        windUnitNames: ["公里/时", "英里/时", "米/秒"],
        severityNames: ["普通预警", "严重预警", "紧急预警"],
        aqiLevels: ["极佳", "优良", "勉强及格", "轻度污染", "严重污染", "小心中毒", "要命了"],
        aqiAdvices: [
            ["快出去！吸天然氧吧！", "这空气比矿泉水还纯净！", "这空气，比海鲜都鲜！", "空气好到想打包带走！", "今天的肺是免费洗的！"],
            ["多出去走走，拥抱大自然。", "今天适合跑步逶弯。", "深呼吸..再呼吸..舒坦！", "微风不燥，空气正好。", "开窗通风，正是时候。"],
            ["上班去吧，问题不大。", "马马虎虎，戴不戴口罩随你。", "这气还行，凑合吸吧。", "空气马虎，你也别太讲究。", "敏感星人今天低调点。"],
            ["还敢不戴口罩？多准备几个吧。", "口罩戴好，别逗强。", "这空气...味不对啊！", "出门快去快回，别瞎溜达。", "今天少开窗，空气有点浑。"],
            ["敢问路在何方？根本看不清！", "今天能不出门就别出门了。", "这空气是不是过期了？！", "口罩焊在脸上，别摘！", "净化器拉满，窗户焊死。"],
            ["没事就别出去了，嗆人！", "出门必须N95，普通口罩扛不住。", "诶呀...呀..呀，有点麻了。", "空气有毒，宅家保平安。", "呼吸都费劲，快回屋！"],
            ["咳咳，还敢出去？不要命了？！", "保命要紧，能不出门绝不出门。", "危险！风紧扯呼！", "空气已报废，人别跟着报废！", "门都别开条缝！"]
        ],
        uvIndex: "紫外线强度",
        uvLevels: ["极佳", "勉强", "暴晒", "晒晕了", "要命了"],
        uvAdvices: [
            ["还等什么！实现说走就走的游玩！", "太阳和你一样温柔，不用怕。", "这阳光就像白开水，不冷不热。", "阳光温柔得像猫咪。", "尽情浪吧，太阳今天不咬人。"],
            ["做好防护防晒，快抹防晒霜，穿防晒服。", "别大意，遮阳伞打起来。", "如果你想白白的，就别与太阳争宠。", "防晒霜薄涂一层，稳了。", "太阳开始上强度了，防着点。"],
            ["加强防晒，多喝水，少运动。", "防晒霜SPF50+安排上，帽子墨镜别忘。", "别硬挺，小心晒成巧克力。", "中午别出门，太阳正凶。", "沿着阴凉走，别跟太阳对视。"],
            ["没啥事别出去浪，小心中暑！", "这太阳有毒！出门全副武装。", "你想成为烤红薯，就去外面走走。", "十分钟晒脱皮，别不信。", "遮阳伞是刚需，不是装饰。"],
            ["快藏起来，一定要好好活着！", "这紫外线能烤肉，赶紧躲室内。", "你闻闻，是不是什么烤焦了？", "太阳开了烧烤模式，快跑！", "出门五分钟，脱皮两星期。"]
        ],
        weatherDescs: [
            "晴", "大部晴朗", "局部多云", "多云", "雾", "小毛毛雨", "毛毛雨", "大毛毛雨",
            "小冻雨", "大冻雨", "小雨", "中雨", "大雨", "小雪", "中雪", "大雪", "雪粒",
            "小阵雨", "阵雨", "强阵雨", "小阵雪", "大阵雪", "雷暴", "雷暴+小冰雹", "雷暴+大冰雹", "未知"
        ],
        windDirs: ["北", "东北", "东", "东南", "南", "西南", "西", "西北"],
        daysOfWeek: ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    )

    private static let zhTW = Strings(
        appName: "識天",
        refresh: "重新整理", settings: "設定", back: "返回", close: "關閉", confirm: "確認", delete: "刪除",
        citySettings: "城市設定", addCity: "新增城市", noCities: "尚未新增城市",
        noCitySelected: "未選擇城市", noWeatherData: "暫無天氣資料", weatherFetchFailed: "取得天氣資料失敗",
        feelsLike: "體感", wind: "風力", windSuffix: "風", humidity: "濕度", pressure: "氣壓",
        visibility: "能見度", airQuality: "空氣品質", forecast5Day: "5日天氣預報", today: "今天",
        settingsAppearance: "外觀", displayMode: "顯示模式", themeColor: "主題顏色",
        settingsUnits: "單位", tempUnit: "溫度單位", windUnit: "風速單位",
        settingsAlerts: "惡劣天氣預警", alertEnable: "開啟預警通知",
        alertOnDesc: "已開啟，背景定期檢測", alertOffDesc: "已關閉", alertMinSeverity: "最低預警等級",
        currentLocationLabel: "目前定位", currentLocationUnknown: "未取得定位，空氣品質與紫外線預警暫不推送",
        currentLocationFallbackName: "目前位置",
        settingsData: "資料", refreshInterval: "自動重新整理間隔", minutesUnit: "分鐘",
        settingsAbout: "關於", version: "版本", dataSource: "資料來源",
        settingsSystem: "系統", languageLabel: "語言", saveSettings: "儲存設定", settingsSaved: "設定已儲存",
        searchCityHint: "搜尋城市（中文或拼音）", searchResults: "搜尋結果", addedCities: "已新增城市",
        noSearchResults: "未找到相關城市", alreadyAdded: "已新增", dragHint: "長按拖曳可調整順序",
        widgetLoading: "載入中...", widgetUpdatePrefix: "更新", widgetFetchFailed: "天氣資料取得失敗",
        settingsWidgets: "小工具", clockWidgetOpacity: "時鐘小工具底板透明度", weatherWidgetOpacity: "氣象小工具底板透明度",
        widgetThemeColor: "小工具主題顏色", dewPoint: "露點",
        sunrise: "日出", sunset: "日落",
        tempMaxLabel: "最高溫度", tempMinLabel: "最低溫度",
        feelsMaxLabel: "體感最高", feelsMinLabel: "體感最低",
        precipSumLabel: "降水量", precipProbLabel: "降水機率",
        hourly24Title: "24小時預報",
        widgetThemeNames: ["動態", "淺白", "深空", "晴空藍", "青碧綠", "暮靄紫"],
        themeModes: ["淺色", "深色", "跟隨系統"],
        tempUnitNames: ["攝氏度", "華氏度"],
        windUnitNames: ["公里/時", "英里/時", "米/秒"],
        severityNames: ["普通預警", "嚴重預警", "緊急預警"],
        aqiLevels: ["極佳", "優良", "勉強及格", "輕度污染", "嚴重污染", "小心中毒", "要命了"],
        aqiAdvices: [
            ["快出去！吸天然氧吧！", "這空氣比礦泉水還純淨！", "這空氣，比海鮮都鮮！", "空氣好到想打包帶走！", "今天的肺是免費洗的！"],
            ["多出去走走，擁抱大自然。", "今天適合跑步遛彎。", "深呼吸..再呼吸..舒坦！", "微風不燥，空氣正好。", "開窗通風，正是時候。"],
            ["上班去吧，問題不大。", "馬馬虎虎，戴不戴口罩隨你。", "這氣還行，湊合吸吧。", "空氣馬虎，你也別太講究。", "敏感星人今天低調點。"],
            ["還敢不戴口罩？多準備幾個吧。", "口罩戴好，別逗強。", "這空氣...味不對啊！", "出門快去快回，別瞎溜達。", "今天少開窗，空氣有點渾。"],
            ["敢問路在何方？根本看不清！", "今天能不出門就別出門了。", "這空氣是不是過期了？！", "口罩焊在臉上，別摘！", "淨化器拉滿，窗戶焊死。"],
            ["沒事就別出去了，嗆人！", "出門必須N95，普通口罩扛不住。", "誒呀...呀..呀，有點麻了。", "空氣有毒，宅家保平安。", "呼吸都費勁，快回屋！"],
            ["咳咳，還敢出去？不要命了？！", "保命要緊，能不出門絕不出門。", "危險！風緊扯呼！", "空氣已報廢，人別跟著報廢！", "門都別開條縫！"]
        ],
        uvIndex: "紫外線強度",
        uvLevels: ["極佳", "勉強", "暴曬", "曬暈了", "要命了"],
        uvAdvices: [
            ["還等什麼！實現說走就走的遊玩！", "太陽和你一樣溫柔，不用怕。", "這陽光就像白開水，不冷不熱。", "陽光溫柔得像貓咪。", "盡情浪吧，太陽今天不咬人。"],
            ["做好防曬，快抹防曬乳，穿防曬衣。", "別大意，遮陽傘打起來。", "如果你想白白的，就別與太陽爭寵。", "防曬乳薄塗一層，穩了。", "太陽開始上強度了，防著點。"],
            ["加強防曬，多喝水，少運動。", "防曬乳SPF50+安排上，帽子墨鏡別忘。", "別硬撐，小心曬成巧克力。", "中午別出門，太陽正兇。", "沿著陰涼走，別跟太陽對視。"],
            ["沒啥事別出去浪，小心中暑！", "這太陽有毒！出門全副武裝。", "你想成為烤紅薯，就去外面走走。", "十分鐘曬脫皮，別不信。", "遮陽傘是剛需，不是裝飾。"],
            ["快躲起來，一定要好好活著！", "這紫外線能烤肉，趕緊躲室內。", "你聞聞，是不是什麼烤焦了？", "太陽開了燒烤模式，快跑！", "出門五分鐘，脫皮兩星期。"]
        ],
        weatherDescs: [
            "晴", "大部晴朗", "局部多雲", "多雲", "霧", "小毛毛雨", "毛毛雨", "大毛毛雨",
            "小凍雨", "大凍雨", "小雨", "中雨", "大雨", "小雪", "中雪", "大雪", "雪粒",
            "小陣雨", "陣雨", "強陣雨", "小陣雪", "大陣雪", "雷暴", "雷暴+小冰雹", "雷暴+大冰雹", "未知"
        ],
        windDirs: ["北", "東北", "東", "東南", "南", "西南", "西", "西北"],
        daysOfWeek: ["週日", "週一", "週二", "週三", "週四", "週五", "週六"]
    )

    private static let en = Strings(
        appName: "SkySense",
        refresh: "Refresh", settings: "Settings", back: "Back", close: "Close", confirm: "Confirm", delete: "Delete",
        citySettings: "City Settings", addCity: "Add City", noCities: "No cities added yet",
        noCitySelected: "No city selected", noWeatherData: "No weather data", weatherFetchFailed: "Failed to fetch weather",
        feelsLike: "Feels like", wind: "Wind", windSuffix: "", humidity: "Humidity", pressure: "Pressure",
        visibility: "Visibility", airQuality: "Air Quality", forecast5Day: "5-Day Forecast", today: "Today",
        settingsAppearance: "Appearance", displayMode: "Display Mode", themeColor: "Theme Color",
        settingsUnits: "Units", tempUnit: "Temperature Unit", windUnit: "Wind Speed Unit",
        settingsAlerts: "Severe Weather Alerts", alertEnable: "Enable Alerts",
        alertOnDesc: "On, checked periodically in background", alertOffDesc: "Off", alertMinSeverity: "Minimum Alert Level",
        currentLocationLabel: "Current Location", currentLocationUnknown: "Location unavailable; air quality and UV alerts are paused",
        currentLocationFallbackName: "Current location",
        settingsData: "Data", refreshInterval: "Auto Refresh Interval", minutesUnit: "min",
        settingsAbout: "About", version: "Version", dataSource: "Data Source",
        settingsSystem: "System", languageLabel: "Language", saveSettings: "Save Settings", settingsSaved: "Settings saved",
        searchCityHint: "Search city (name or pinyin)", searchResults: "Search Results", addedCities: "Added Cities",
        noSearchResults: "No matching cities", alreadyAdded: "Added", dragHint: "Long-press and drag to reorder",
        widgetLoading: "Loading...", widgetUpdatePrefix: "Upd", widgetFetchFailed: "Weather fetch failed",
        settingsWidgets: "Widgets", clockWidgetOpacity: "Clock Widget Opacity", weatherWidgetOpacity: "Weather Widget Opacity",
        widgetThemeColor: "Widget Theme Color", dewPoint: "Dew point",
        sunrise: "Sunrise", sunset: "Sunset",
        tempMaxLabel: "High", tempMinLabel: "Low",
        feelsMaxLabel: "Feels high", feelsMinLabel: "Feels low",
        precipSumLabel: "Precip.", precipProbLabel: "Precip. chance",
        hourly24Title: "24-Hour Forecast",
        widgetThemeNames: ["Dynamic", "Light", "Dark", "Blue", "Green", "Purple"],
        themeModes: ["Light", "Dark", "System"],
        tempUnitNames: ["Celsius", "Fahrenheit"],
        windUnitNames: ["km/h", "mph", "m/s"],
        severityNames: ["Warning", "Severe", "Extreme"],
        aqiLevels: ["Excellent", "Good", "Barely OK", "Mild Pollution", "Heavy Pollution", "Toxic Alert", "Deadly"],
        aqiAdvices: [
            ["Get outside now — free natural oxygen bar!", "This air is purer than spring water!", "This air is fresher than seafood!", "Air so good you'll want it to go!", "Free lung cleansing today!"],
            ["Take a walk and hug Mother Nature.", "Perfect day for a jog or a stroll.", "Deep breath... again... so good!", "Gentle breeze, lovely air.", "Great time to open the windows."],
            ["Off to work you go, no big deal.", "So-so. Mask is up to you.", "Air's passable — breathe as is.", "The air is sloppy, don't be picky.", "Sensitive folks, take it easy today."],
            ["Still no mask?! Better stock up.", "Mask on tight, don't be a hero.", "This air... smells off!", "Run your errands fast, no wandering.", "Keep windows shut, air's murky today."],
            ["Where's the road? Can't see a thing!", "If you can stay in, stay in.", "Did this air pass its expiry date?!", "Weld that mask to your face!", "Purifier maxed out, windows sealed."],
            ["Just stay in — it's choking out there!", "N95 or nothing — regular masks can't cope.", "Uh oh... feeling a bit numb here.", "Toxic air — home sweet home.", "Even breathing is hard. Get inside!"],
            ["Cough cough... going out? Seriously?!", "Life first: don't go out unless you must.", "Danger! Run for it!", "The air is scrapped — don't get scrapped with it!", "Don't even crack the door open!"]
        ],
        uvIndex: "UV Index",
        uvLevels: ["Excellent", "Barely OK", "Scorching", "Dizzying", "Deadly"],
        uvAdvices: [
            ["What are you waiting for? Go have fun!", "The sun is as gentle as you. No worries.", "Sunshine mild as warm water today.", "Sunshine as soft as a kitten.", "Roam freely — the sun won't bite today."],
            ["Sunscreen on, sun-proof clothes ready.", "Don't slack — pop that umbrella open.", "Want to stay fair? Don't compete with the sun.", "A thin layer of sunscreen and you're set.", "The sun is stepping it up — stay guarded."],
            ["More sunscreen, more water, less exercise.", "SPF50+, hat and shades — full kit.", "Don't tough it out or you'll tan chocolate.", "Skip the noon sun, it's fierce.", "Stick to the shade, no staring contests with the sun."],
            ["Don't wander out — heatstroke alert!", "This sun is toxic! Gear up fully.", "Fancy being a roast sweet potato? Take a walk.", "Ten minutes to a sunburn peel — no joke.", "A sun umbrella is a must, not a prop."],
            ["Hide now. Stay alive, please!", "This UV could grill meat — get indoors!", "Sniff... is something burning?", "The sun turned on BBQ mode — run!", "Five minutes out, two weeks peeling."]
        ],
        weatherDescs: [
            "Clear", "Mainly clear", "Partly cloudy", "Overcast", "Fog", "Light drizzle", "Drizzle", "Dense drizzle",
            "Light freezing rain", "Freezing rain", "Light rain", "Rain", "Heavy rain", "Light snow", "Snow", "Heavy snow", "Snow grains",
            "Light showers", "Showers", "Violent showers", "Light snow showers", "Snow showers", "Thunderstorm",
            "Thunderstorm w/ hail", "Severe thunderstorm", "Unknown"
        ],
        windDirs: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"],
        daysOfWeek: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    )

    private static let ja = Strings(
        appName: "識天",
        refresh: "更新", settings: "設定", back: "戻る", close: "閉じる", confirm: "確認", delete: "削除",
        citySettings: "都市設定", addCity: "都市を追加", noCities: "都市が追加されていません",
        noCitySelected: "都市未選択", noWeatherData: "天気データなし", weatherFetchFailed: "天気データの取得に失敗",
        feelsLike: "体感", wind: "風", windSuffix: "の風", humidity: "湿度", pressure: "気圧",
        visibility: "視程", airQuality: "空気質", forecast5Day: "5日間予報", today: "今日",
        settingsAppearance: "外観", displayMode: "表示モード", themeColor: "テーマカラー",
        settingsUnits: "単位", tempUnit: "温度単位", windUnit: "風速単位",
        settingsAlerts: "悪天候警報", alertEnable: "警報通知を有効化",
        alertOnDesc: "オン、バックグラウンドで定期確認", alertOffDesc: "オフ", alertMinSeverity: "最低警報レベル",
        currentLocationLabel: "現在の位置", currentLocationUnknown: "位置を取得できません。大気質と紫外線の警報は停止中",
        currentLocationFallbackName: "現在地",
        settingsData: "データ", refreshInterval: "自動更新間隔", minutesUnit: "分",
        settingsAbout: "情報", version: "バージョン", dataSource: "データソース",
        settingsSystem: "システム", languageLabel: "言語", saveSettings: "設定を保存", settingsSaved: "設定を保存しました",
        searchCityHint: "都市を検索", searchResults: "検索結果", addedCities: "追加済みの都市",
        noSearchResults: "該当する都市がありません", alreadyAdded: "追加済み", dragHint: "長押しドラッグで並べ替え",
        widgetLoading: "読み込み中...", widgetUpdatePrefix: "更新", widgetFetchFailed: "天気データの取得に失敗",
        settingsWidgets: "ウィジェット", clockWidgetOpacity: "時計ウィジェットの不透明度", weatherWidgetOpacity: "天気ウィジェットの不透明度",
        widgetThemeColor: "ウィジェットのテーマカラー", dewPoint: "露点",
        sunrise: "日の出", sunset: "日の入り",
        tempMaxLabel: "最高気温", tempMinLabel: "最低気温",
        feelsMaxLabel: "体感最高", feelsMinLabel: "体感最低",
        precipSumLabel: "降水量", precipProbLabel: "降水確率",
        hourly24Title: "24時間予報",
        widgetThemeNames: ["ダイナミック", "ライト", "ダーク", "ブルー", "グリーン", "パープル"],
        themeModes: ["ライト", "ダーク", "システムに従う"],
        tempUnitNames: ["摂氏", "華氏"],
        windUnitNames: ["km/h", "mph", "m/s"],
        severityNames: ["注意報", "警報", "特別警報"],
        aqiLevels: ["極上", "良好", "ぎりぎり合格", "軽度汚染", "重度汚染", "中毒注意", "命の危険"],
        aqiAdvices: [
            ["今すぐ外へ！天然の酸素バーだよ！", "この空気、ミネラルウォーターよりピュア！", "この空気、海鮮より新鮮！", "持ち帰りたいくらい良い空気！", "今日は肺のクリーニングが無料！"],
            ["外に出て大自然を満喫しよう。", "今日はジョギングや散歩日和。", "深呼吸…もう一度…気持ちいい！", "風は穏やか、空気は最高。", "窓を開けて換気日和。"],
            ["仕事に行こう、問題なし。", "まあまあ、マスクはお好みで。", "まあ吸える、とりあえず吸とこう。", "空気が雑なので、こだわらないで。", "敏感な人は今日は控えめに。"],
            ["まだマスクなし？！多めに用意して。", "マスクをしっかり、無理しないで。", "この空気…味が変だ！", "用事は手短に、寄り道禁止。", "今日は窓開け控えめ、空気が濁ってる。"],
            ["道はどこ？何も見えない！", "出かけなくていいなら出ないで。", "この空気、賞味期限切れでは？！", "マスクを顔に溶接！外さないで！", "空気清浄機全開、窓は密閉。"],
            ["用がなければ外出しないで、むせるよ！", "外出はN95必須、普通のマスクでは無理。", "あれ…ちょっとシビレてきた…。", "空気が有毒、家にいるのが一番。", "呼吸すらしんどい、早く家へ！"],
            ["ゴホゴホ…まだ出かける気？！", "命が大事、外出は絶対に控えて。", "危険！逃げろー！", "空気はもう廃棄物、巻き込まれないで！", "ドアも隙間開けないで！"]
        ],
        uvIndex: "紫外線指数",
        uvLevels: ["極上", "ぎりぎり", "炎天下", "クラクラ", "命の危険"],
        uvAdvices: [
            ["何を待ってるの？思い立ったら即お出かけ！", "太陽は君のように優しい、怖くないよ。", "この日差しは白湯みたい、熱くも冷たくもない。", "子猫みたいに穏やかな日差し。", "今日の太陽は噛みつかない、思い切り遊ぼう！"],
            ["日焼け止めを塗って、UVカットの服を！", "油断しないで、日傘を忘れずに。", "白くいたいなら、太陽と張り合わないで。", "日焼け止めを薄く一層、これで安心。", "太陽が本気を出し始めた、油断禁物。"],
            ["日焼け対策強化、水分補給、運動控えめに。", "SPF50+に帽子とサングラスも忘れずに。", "意地を張るとチョコレート色に焼けるよ。", "正午の外出は避けて、太陽が凶暴。", "日陰を歩いて、太陽とにらめっこしないで。"],
            ["用もないのに出歩かないで、熱中症注意！", "この太陽は毒！完全装備で出かけて。", "焼き芋になりたいなら外を歩いてどうぞ。", "10分で皮がむける、嘘じゃないよ。", "日傘は必需品、飾りじゃない。"],
            ["早く隠れて、命を大事に！", "この紫外線は肉が焼けるレベル、室内へ！", "嗅いでみて、何か焦げてない？", "太陽がBBQモード起動、逃げて！", "外出5分、皮むけ2週間。"]
        ],
        weatherDescs: [
            "晴れ", "おおむね晴れ", "一部曇り", "曇り", "霧", "弱い霧雨", "霧雨", "強い霧雨",
            "弱い着氷性雨", "着氷性雨", "小雨", "雨", "大雨", "小雪", "雪", "大雪", "雪あられ",
            "弱いにわか雨", "にわか雨", "激しいにわか雨", "弱いにわか雪", "にわか雪", "雷雨",
            "雷雨と小さな雹", "激しい雷雨", "不明"
        ],
        windDirs: ["北", "北東", "東", "南東", "南", "南西", "西", "北西"],
        daysOfWeek: ["日", "月", "火", "水", "木", "金", "土"]
    )

    private static let ko = Strings(
        appName: "식천",
        refresh: "새로고침", settings: "설정", back: "뒤로", close: "닫기", confirm: "확인", delete: "삭제",
        citySettings: "도시 설정", addCity: "도시 추가", noCities: "추가된 도시가 없습니다",
        noCitySelected: "도시 미선택", noWeatherData: "날씨 데이터 없음", weatherFetchFailed: "날씨 데이터 가져오기 실패",
        feelsLike: "체감", wind: "바람", windSuffix: "풍", humidity: "습도", pressure: "기압",
        visibility: "가시거리", airQuality: "대기질", forecast5Day: "5일 예보", today: "오늘",
        settingsAppearance: "화면", displayMode: "표시 모드", themeColor: "테마 색상",
        settingsUnits: "단위", tempUnit: "온도 단위", windUnit: "풍속 단위",
        settingsAlerts: "악천후 경보", alertEnable: "경보 알림 켜기",
        alertOnDesc: "켜짐, 백그라운드에서 주기적 확인", alertOffDesc: "꺼짐", alertMinSeverity: "최소 경보 수준",
        currentLocationLabel: "현재 위치",
        currentLocationUnknown: "위치를 가져올 수 없어 대기질·자외선 경보가 중지됩니다",
        currentLocationFallbackName: "현재 위치",
        settingsData: "데이터", refreshInterval: "자동 새로고침 간격", minutesUnit: "분",
        settingsAbout: "정보", version: "버전", dataSource: "데이터 출처",
        settingsSystem: "시스템", languageLabel: "언어", saveSettings: "설정 저장", settingsSaved: "설정이 저장되었습니다",
        searchCityHint: "도시 검색", searchResults: "검색 결과", addedCities: "추가된 도시",
        noSearchResults: "일치하는 도시가 없습니다", alreadyAdded: "추가됨", dragHint: "길게 눌러 드래그로 순서 변경",
        widgetLoading: "로딩 중...", widgetUpdatePrefix: "업데이트", widgetFetchFailed: "날씨 데이터 가져오기 실패",
        settingsWidgets: "위젯", clockWidgetOpacity: "시계 위젯 배경 불투명도", weatherWidgetOpacity: "날씨 위젯 배경 불투명도",
        widgetThemeColor: "위젯 테마 색상", dewPoint: "이슬점",
        sunrise: "일출", sunset: "일몰",
        tempMaxLabel: "최고 기온", tempMinLabel: "최저 기온",
        feelsMaxLabel: "체감 최고", feelsMinLabel: "체감 최저",
        precipSumLabel: "강수량", precipProbLabel: "강수 확률",
        hourly24Title: "24시간 예보",
        widgetThemeNames: ["동적", "라이트", "다크", "블루", "그린", "퍼플"],
        themeModes: ["라이트", "다크", "시스템 따름"],
        tempUnitNames: ["섭씨", "화씨"],
        windUnitNames: ["km/h", "mph", "m/s"],
        severityNames: ["주의보", "경보", "긴급 경보"],
        aqiLevels: ["최상", "양호", "겨우 합격", "약한 오염", "심한 오염", "중독 주의", "치명적"],
        aqiAdvices: [
            ["얼른 나가요! 천연 산소 카페예요!", "이 공기, 생수보다 깨끗해요!", "이 공기, 해산물보다 신선해요!", "공기가 너무 좋아서 포장해 가고 싶어요!", "오늘은 폐 세척이 공짜예요!"],
            ["산책하며 자연을 만끽하세요.", "오늘은 조깅하기 딱 좋아요.", "깊게 숨 쉬고… 또 쉬고… 시원해!", "바람도 선선하고 공기도 좋아요.", "창문 열고 환기하기 좋은 때예요."],
            ["출근하세요, 별문제 없어요.", "그럭저럭, 마스크는 알아서 하세요.", "이 공기 그럭저럭, 대충 마셔요.", "공기가 대충이니 너무 따지지 마세요.", "민감한 분들은 오늘 조심하세요."],
            ["아직도 마스크 없이?! 여러 개 챙기세요.", "마스크 잘 쓰고, 무리하지 마세요.", "이 공기… 냄새가 이상해요!", "외출은 빨리 다녀오고 돌아다니지 마세요.", "오늘은 창문 열지 마세요, 공기가 탁해요."],
            ["길이 어디죠? 하나도 안 보여요!", "오늘은 웬만하면 나가지 마세요.", "이 공기 유통기한 지난 거 아니에요?!", "마스크를 얼굴에 용접하세요! 벗지 마요!", "공기청정기 풀가동, 창문은 밀봉!"],
            ["일 없으면 나가지 마세요, 숨 막혀요!", "외출은 N95 필수, 일반 마스크는 못 버텨요.", "어… 어라… 좀 얼얼한데요.", "공기가 독이에요, 집콕이 안전해요.", "숨쉬기도 힘들어요, 얼른 들어가세요!"],
            ["콜록콜록… 아직도 나가려고요?!", "목숨이 우선, 나갈 수 있으면 절대 나가지 마세요.", "위험해요! 얼른 튀세요!", "공기는 이미 폐기물, 사람까지 폐기되면 안 돼요!", "문틈도 열지 마세요!"]
        ],
        uvIndex: "자외선 지수",
        uvLevels: ["최상", "그럭저럭", "땡볕", "어질어질", "치명적"],
        uvAdvices: [
            ["뭐하세요! 지금 바로 떠나요!", "태양이 당신처럼 다정해요, 겁내지 마세요.", "이 햇살은 미지근한 물 같아요, 뜨겁지도 차갑지도 않아요.", "햇살이 고양이처럼 포근해요.", "맘껏 놀아요, 오늘 태양은 안 물어요."],
            ["선크림 바르고 자외선 차단 옷 입기.", "방심 금지, 양산 꼭 챙기세요.", "하얗게 살고 싶다면 태양과 겨루지 마세요.", "선크림 얇게 한 겹이면 든든해요.", "태양이 세게 나오기 시작했어요, 조심!"],
            ["자외선 차단 강화, 물 많이, 운동 자제.", "SPF50+ 선크림에 모자·선글라스까지!", "버티지 마세요, 초콜릿색으로 탈 수 있어요.", "한낮엔 나가지 마세요, 태양이 사나워요.", "그늘 따라 걷고 태양과 눈싸움하지 마세요."],
            ["괜히 돌아다니지 마세요, 열사병 조심!", "이 태양은 독이에요! 완전 무장하고 나가세요.", "군고구마가 되고 싶으면 밖을 걸어보세요.", "10분이면 피부가 벗겨져요, 진짜예요.", "양산은 필수품이지 장식이 아니에요."],
            ["얼른 숨으세요, 꼭 살아남아요!", "이 자외선은 고기도 굽는 수준, 실내로!", "맡아보세요, 뭔가 타는 냄새 안 나요?", "태양이 바비큐 모드 가동, 튀세요!", "외출 5분, 허물 2주."]
        ],
        weatherDescs: [
            "맑음", "대체로 맑음", "구름 조금", "흐림", "안개", "약한 이슬비", "이슬비", "강한 이슬비",
            "약한 어는 비", "어는 비", "약한 비", "비", "폭우", "약한 눈", "눈", "폭설", "싸락눈",
            "약한 소나기", "소나기", "강한 소나기", "약한 소낙눈", "소낙눈", "뇌우",
            "뇌우와 우박", "심한 뇌우", "알 수 없음"
        ],
        windDirs: ["북", "북동", "동", "남동", "남", "남서", "서", "북서"],
        daysOfWeek: ["일", "월", "화", "수", "목", "금", "토"]
    )

    private static let ru = Strings(
        appName: "SkySense",
        refresh: "Обновить", settings: "Настройки", back: "Назад", close: "Закрыть", confirm: "Подтвердить", delete: "Удалить",
        citySettings: "Настройки городов", addCity: "Добавить город", noCities: "Города не добавлены",
        noCitySelected: "Город не выбран", noWeatherData: "Нет данных о погоде", weatherFetchFailed: "Не удалось получить погоду",
        feelsLike: "Ощущается", wind: "Ветер", windSuffix: "", humidity: "Влажность", pressure: "Давление",
        visibility: "Видимость", airQuality: "Качество воздуха", forecast5Day: "Прогноз на 5 дней", today: "Сегодня",
        settingsAppearance: "Внешний вид", displayMode: "Режим отображения", themeColor: "Цвет темы",
        settingsUnits: "Единицы", tempUnit: "Единица температуры", windUnit: "Единица скорости ветра",
        settingsAlerts: "Штормовые предупреждения", alertEnable: "Включить уведомления",
        alertOnDesc: "Вкл., периодическая проверка в фоне", alertOffDesc: "Выкл.", alertMinSeverity: "Минимальный уровень",
        currentLocationLabel: "Текущее местоположение",
        currentLocationUnknown: "Местоположение недоступно, оповещения о качестве воздуха и УФ приостановлены",
        currentLocationFallbackName: "Текущее место",
        settingsData: "Данные", refreshInterval: "Интервал автообновления", minutesUnit: "мин",
        settingsAbout: "О приложении", version: "Версия", dataSource: "Источник данных",
        settingsSystem: "Система", languageLabel: "Язык", saveSettings: "Сохранить настройки", settingsSaved: "Настройки сохранены",
        searchCityHint: "Поиск города", searchResults: "Результаты поиска", addedCities: "Добавленные города",
        noSearchResults: "Городов не найдено", alreadyAdded: "Добавлен", dragHint: "Удерживайте и перетащите для сортировки",
        widgetLoading: "Загрузка...", widgetUpdatePrefix: "Обн", widgetFetchFailed: "Ошибка получения погоды",
        settingsWidgets: "Виджеты", clockWidgetOpacity: "Непрозрачность фона часов", weatherWidgetOpacity: "Непрозрачность фона погоды",
        widgetThemeColor: "Цвет темы виджетов", dewPoint: "Точка росы",
        sunrise: "Восход", sunset: "Закат",
        tempMaxLabel: "Макс.", tempMinLabel: "Мин.",
        feelsMaxLabel: "Ощущ. макс.", feelsMinLabel: "Ощущ. мин.",
        precipSumLabel: "Осадки", precipProbLabel: "Вероятн. осадков",
        hourly24Title: "Прогноз на 24 часа",
        widgetThemeNames: ["Динамич.", "Светлая", "Тёмная", "Синяя", "Зелёная", "Фиолет."],
        themeModes: ["Светлая", "Тёмная", "Как в системе"],
        tempUnitNames: ["Цельсий", "Фаренгейт"],
        windUnitNames: ["км/ч", "миль/ч", "м/с"],
        severityNames: ["Предупреждение", "Серьёзное", "Экстренное"],
        aqiLevels: ["Отлично", "Хорошо", "Едва сносно", "Лёгкое загрязнение", "Сильное загрязнение", "Риск отравления", "Смертельно"],
        aqiAdvices: [
            ["Скорее на улицу — природный кислородный бар!", "Этот воздух чище минералки!", "Этот воздух свежее морепродуктов!", "Воздух так хорош, что хочется забрать с собой!", "Сегодня лёгкие чистятся бесплатно!"],
            ["Гуляйте больше, обнимите природу.", "Отличный день для пробежки.", "Вдох… ещё вдох… красота!", "Ветер мягкий, воздух — то, что надо.", "Самое время открыть окна и проветрить."],
            ["Идите на работу, ничего страшного.", "Так себе. Маска — на ваше усмотрение.", "Воздух сойдёт, дышите как есть.", "Воздух небрежный — и вы не привередничайте.", "Чувствительным сегодня лучше не геройствовать."],
            ["Всё ещё без маски?! Запаситесь.", "Наденьте маску, не геройствуйте.", "Этот воздух… странно пахнет!", "Вышли — быстро по делам и домой.", "Сегодня окна лучше не открывать, воздух мутный."],
            ["Где дорога? Ничего не видно!", "Можете не выходить — не выходите.", "У этого воздуха истёк срок годности?!", "Приварите маску к лицу и не снимайте!", "Очиститель на максимум, окна наглухо."],
            ["Без нужды не выходите — душно!", "Только N95, обычная маска не спасёт.", "Ой… что-то уже пощипывает.", "Воздух ядовит, сидите дома.", "Дышать тяжело — скорее домой!"],
            ["Кхе-кхе… всё ещё хотите выйти?!", "Жизнь дороже: можете не выходить — не выходите.", "Опасно! Уносите ноги!", "Воздух уже списан — не списывайтесь вместе с ним!", "Даже щёлку в двери не открывайте!"]
        ],
        uvIndex: "УФ-индекс",
        uvLevels: ["Отлично", "Терпимо", "Пекло", "Голова кружится", "Смертельно"],
        uvAdvices: [
            ["Чего ждёте? Пора гулять!", "Солнце нежное, как вы, — не бойтесь.", "Это солнце как тёплая водичка — ни жарко, ни холодно.", "Солнышко ласковое, как котёнок.", "Гуляйте смело — сегодня солнце не кусается."],
            ["Крем от солнца и закрытая одежда!", "Не зевайте, раскрывайте зонтик.", "Хотите остаться белыми — не соперничайте с солнцем.", "Тонкий слой SPF — и порядок.", "Солнце набирает обороты, будьте начеку."],
            ["Больше защиты и воды, меньше нагрузок.", "SPF50+, шляпа и очки — всё по списку.", "Не упрямьтесь, а то станете шоколадкой.", "В полдень не выходите — солнце злющее.", "Держитесь тени и не переглядывайтесь с солнцем."],
            ["Не гуляйте зря — риск теплового удара!", "Это солнце ядовито! Полная экипировка.", "Хотите стать печёной картошкой — прогуляйтесь.", "Десять минут — и кожа слезет, честно.", "Зонт от солнца — необходимость, а не украшение."],
            ["Прячьтесь скорее, берегите себя!", "Этот ультрафиолет жарит мясо — бегом в помещение!", "Принюхайтесь: ничего не подгорело?", "Солнце включило режим барбекю — бегите!", "Пять минут на улице — две недели линьки."]
        ],
        weatherDescs: [
            "Ясно", "Преимущественно ясно", "Переменная облачность", "Пасмурно", "Туман", "Слабая морось", "Морось", "Сильная морось",
            "Слабый ледяной дождь", "Ледяной дождь", "Небольшой дождь", "Дождь", "Ливень", "Небольшой снег", "Снег", "Сильный снег", "Снежная крупа",
            "Небольшой ливень", "Ливневый дождь", "Сильный ливень", "Небольшой снегопад", "Снегопад", "Гроза",
            "Гроза с градом", "Сильная гроза", "Неизвестно"
        ],
        windDirs: ["С", "СВ", "В", "ЮВ", "Ю", "ЮЗ", "З", "СЗ"],
        daysOfWeek: ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
    )

    /// 获取指定语言的全部文案
    static func of(_ language: AppLanguage) -> Strings {
        switch language {
        case .simplifiedChinese: return zhCN
        case .traditionalChinese: return zhTW
        case .english: return en
        case .japanese: return ja
        case .korean: return ko
        case .russian: return ru
        }
    }

    /// WMO 天气代码 -> weatherDescs 下标
    static func weatherIndex(_ code: Int) -> Int {
        switch code {
        case 0: return 0
        case 1: return 1
        case 2: return 2
        case 3: return 3
        case 45, 48: return 4
        case 51: return 5
        case 53: return 6
        case 55: return 7
        case 56, 66: return 8
        case 57, 67: return 9
        case 61: return 10
        case 63: return 11
        case 65: return 12
        case 71: return 13
        case 73: return 14
        case 75: return 15
        case 77: return 16
        case 80: return 17
        case 81: return 18
        case 82: return 19
        case 85: return 20
        case 86: return 21
        case 95: return 22
        case 96: return 23
        case 99: return 24
        default: return 25
        }
    }

    /// 天气描述（按语言）
    static func weatherDesc(_ code: Int, _ language: AppLanguage) -> String {
        of(language).weatherDescs[weatherIndex(code)]
    }

    /// 风向描述（按语言，如"东北"/"NE"）
    static func windDirection(_ degrees: Double, _ language: AppLanguage) -> String {
        let dirs = of(language).windDirs
        let idx: Int
        switch degrees {
        case ..<22.5, 337.5...: idx = 0
        case ..<67.5: idx = 1
        case ..<112.5: idx = 2
        case ..<157.5: idx = 3
        case ..<202.5: idx = 4
        case ..<247.5: idx = 5
        case ..<292.5: idx = 6
        default: idx = 7
        }
        return dirs[idx]
    }

    /// 完整风向标签（含后缀，如"东北风"、"NE"）
    static func windLabel(_ degrees: Double, _ language: AppLanguage) -> String {
        windDirection(degrees, language) + of(language).windSuffix
    }

    /// 星期几（0=周日）
    static func dayOfWeek(_ index: Int, _ language: AppLanguage) -> String {
        let days = of(language).daysOfWeek
        return (0..<days.count).contains(index) ? days[index] : ""
    }

    /// 本地化日期标签（月/日）
    static func dateLabel(month: Int, day: Int, language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese, .traditionalChinese, .japanese: return "\(month)月\(day)日"
        case .korean: return "\(month)월 \(day)일"
        case .russian: return "\(day).\(month)"
        default: return "\(month)/\(day)"
        }
    }

    /// 完整本地化日期（含年份与星期，weekdayIndex: 0=周日）
    static func fullDateLabel(year: Int, month: Int, day: Int, weekdayIndex: Int, language: AppLanguage) -> String {
        let wd = dayOfWeek(weekdayIndex, language)
        switch language {
        case .simplifiedChinese, .traditionalChinese, .japanese:
            return "\(year)年\(month)月\(day)日 \(wd)"
        case .korean: return "\(year)년 \(month)월 \(day)일 \(wd)"
        case .russian: return "\(day).\(month).\(year), \(wd)"
        default: return "\(wd), \(month)/\(day)/\(year)"
        }
    }
}
