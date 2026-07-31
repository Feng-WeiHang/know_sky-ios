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
    let widgetThemeNames: [String]   // 动态/浅白/深空/蓝/绿/紫
    // 枚举翻译表
    let themeModes: [String]         // 浅色/深色/跟随系统
    let tempUnitNames: [String]      // 摄氏度/华氏度
    let windUnitNames: [String]      // 公里时/英里时/米秒
    let severityNames: [String]      // 普通/严重/紧急预警
    let aqiLevels: [String]          // 极佳/优良/勉强及格/轻度污染/严重污染/小心中毒/要命了
    let aqiAdvices: [String]         // AQI 各级趣味建议（与 aqiLevels 一一对应）
    let uvIndex: String              // 紫外线强度
    let uvLevels: [String]           // 极佳/勉强/暴晒/晒晕了/要命了
    let uvAdvices: [String]          // UVI 各级趣味建议（与 uvLevels 一一对应）
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
        widgetThemeNames: ["动态", "浅白", "深空", "晴空蓝", "青碧绿", "暮霭紫"],
        themeModes: ["浅色", "深色", "跟随系统"],
        tempUnitNames: ["摄氏度", "华氏度"],
        windUnitNames: ["公里/时", "英里/时", "米/秒"],
        severityNames: ["普通预警", "严重预警", "紧急预警"],
        aqiLevels: ["极佳", "优良", "勉强及格", "轻度污染", "严重污染", "小心中毒", "要命了"],
        aqiAdvices: [
            "快出去！嘻嘻吸天然氧吧！", "多出去走走，拥抱大自然。", "上班去吧，问题不大。",
            "还敢不戴口罩？！多准备几个吧。", "敢问路在何方？根本看不清！", "没事就别出去了，呛人！",
            "咳咳，还敢出去？不要命了？！"
        ],
        uvIndex: "紫外线强度",
        uvLevels: ["极佳", "勉强", "暴晒", "晒晕了", "要命了"],
        uvAdvices: [
            "还等什么！来一场说走就走的游玩！", "做好防护防晒，快抹防晒霜，穿防晒服。", "加强防晒，多喝水，少运动。",
            "没啥事别出去浪，小心中暑！", "快藏起来，一定要好好活着！"
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
        widgetThemeNames: ["動態", "淺白", "深空", "晴空藍", "青碧綠", "暮靄紫"],
        themeModes: ["淺色", "深色", "跟隨系統"],
        tempUnitNames: ["攝氏度", "華氏度"],
        windUnitNames: ["公里/時", "英里/時", "米/秒"],
        severityNames: ["普通預警", "嚴重預警", "緊急預警"],
        aqiLevels: ["極佳", "優良", "勉強及格", "輕度污染", "嚴重污染", "小心中毒", "要命了"],
        aqiAdvices: [
            "快出去！嘻嘻吸天然氧吧！", "多出去走走，擁抱大自然。", "上班去吧，問題不大。",
            "還敢不戴口罩？！多準備幾個吧。", "敢問路在何方？根本看不清！", "沒事就別出去了，嗆人！",
            "咳咳，還敢出去？不要命了？！"
        ],
        uvIndex: "紫外線強度",
        uvLevels: ["極佳", "勉強", "暴曬", "曬暈了", "要命了"],
        uvAdvices: [
            "還等什麼！來一場說走就走的遊玩！", "做好防曬，快抹防曬乳，穿防曬衣。", "加強防曬，多喝水，少運動。",
            "沒啥事別出去浪，小心中暑！", "快躲起來，一定要好好活著！"
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
        widgetThemeNames: ["Dynamic", "Light", "Dark", "Blue", "Green", "Purple"],
        themeModes: ["Light", "Dark", "System"],
        tempUnitNames: ["Celsius", "Fahrenheit"],
        windUnitNames: ["km/h", "mph", "m/s"],
        severityNames: ["Warning", "Severe", "Extreme"],
        aqiLevels: ["Excellent", "Good", "Barely OK", "Mild Pollution", "Heavy Pollution", "Toxic Alert", "Deadly"],
        aqiAdvices: [
            "Get outside now — free natural oxygen bar!", "Take a walk and hug Mother Nature.", "Off to work you go, no big deal.",
            "Still no mask?! Better stock up.", "Where's the road? Can't see a thing!", "Just stay in — it's choking out there!",
            "Cough cough... going out? Seriously?!"
        ],
        uvIndex: "UV Index",
        uvLevels: ["Excellent", "Barely OK", "Scorching", "Dizzying", "Deadly"],
        uvAdvices: [
            "What are you waiting for? Go have fun!", "Sunscreen on, sun-proof clothes ready.", "More sunscreen, more water, less exercise.",
            "Don't wander out — heatstroke alert!", "Hide now. Stay alive, please!"
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
        widgetThemeNames: ["ダイナミック", "ライト", "ダーク", "ブルー", "グリーン", "パープル"],
        themeModes: ["ライト", "ダーク", "システムに従う"],
        tempUnitNames: ["摂氏", "華氏"],
        windUnitNames: ["km/h", "mph", "m/s"],
        severityNames: ["注意報", "警報", "特別警報"],
        aqiLevels: ["極上", "良好", "ぎりぎり合格", "軽度汚染", "重度汚染", "中毒注意", "命の危険"],
        aqiAdvices: [
            "今すぐ外へ！天然の酸素バーだよ！", "外に出て大自然を満喫しよう。", "仕事に行こう、問題なし。",
            "まだマスクなし？！多めに用意して。", "道はどこ？何も見えない！", "用がなければ外出しないで、むせるよ！",
            "ゴホゴホ…まだ出かける気？！"
        ],
        uvIndex: "紫外線指数",
        uvLevels: ["極上", "ぎりぎり", "炎天下", "クラクラ", "命の危険"],
        uvAdvices: [
            "何を待ってるの？思い立ったら即お出かけ！", "日焼け止めを塗って、UVカットの服を！", "日焼け対策強化、水分補給、運動控えめに。",
            "用もないのに出歩かない、熱中症注意！", "早く隠れて、命を大事に！"
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
        widgetThemeNames: ["동적", "라이트", "다크", "블루", "그린", "퍼플"],
        themeModes: ["라이트", "다크", "시스템 따름"],
        tempUnitNames: ["섭씨", "화씨"],
        windUnitNames: ["km/h", "mph", "m/s"],
        severityNames: ["주의보", "경보", "긴급 경보"],
        aqiLevels: ["최상", "양호", "겨우 합격", "약한 오염", "심한 오염", "중독 주의", "치명적"],
        aqiAdvices: [
            "얼른 나가요! 천연 산소 카페예요!", "산책하며 자연을 만끽하세요.", "출근하세요, 별문제 없어요.",
            "아직도 마스크 없이?! 여러 개 챙기세요.", "길이 어디죠? 하나도 안 보여요!", "일 없으면 나가지 마세요, 숨 막혀요!",
            "콜록콜록… 아직도 나가려고요?!"
        ],
        uvIndex: "자외선 지수",
        uvLevels: ["최상", "그럭저럭", "땡볕", "어질어질", "치명적"],
        uvAdvices: [
            "뭐하세요! 지금 바로 떠나요!", "선크림 바르고 자외선 차단 옷 입기.", "자외선 차단 강화, 물 많이, 운동 자제.",
            "괜히 돌아다니지 마세요, 열사병 조심!", "얼른 숨으세요, 꼭 살아남아요!"
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
        widgetThemeNames: ["Динамич.", "Светлая", "Тёмная", "Синяя", "Зелёная", "Фиолет."],
        themeModes: ["Светлая", "Тёмная", "Как в системе"],
        tempUnitNames: ["Цельсий", "Фаренгейт"],
        windUnitNames: ["км/ч", "миль/ч", "м/с"],
        severityNames: ["Предупреждение", "Серьёзное", "Экстренное"],
        aqiLevels: ["Отлично", "Хорошо", "Едва сносно", "Лёгкое загрязнение", "Сильное загрязнение", "Риск отравления", "Смертельно"],
        aqiAdvices: [
            "Скорее на улицу — природный кислородный бар!", "Гуляйте больше, обнимите природу.", "Идите на работу, ничего страшного.",
            "Всё ещё без маски?! Запаситесь.", "Где дорога? Ничего не видно!", "Без нужды не выходите — душно!",
            "Кхе-кхе… всё ещё хотите выйти?!"
        ],
        uvIndex: "УФ-индекс",
        uvLevels: ["Отлично", "Терпимо", "Пекло", "Голова кружится", "Смертельно"],
        uvAdvices: [
            "Чего ждёте? Пора гулять!", "Крем от солнца и закрытая одежда!", "Больше защиты и воды, меньше нагрузок.",
            "Не гуляйте зря — риск теплового удара!", "Прячьтесь скорее, берегите себя!"
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
