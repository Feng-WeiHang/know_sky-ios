import Foundation

/// 地表防灾预报文案（单条灾害的名称、预测说明、连锁影响）
///
/// desc 用 {t}/{a}/{b} 占位：{t} 为时效小时数，{a}/{b} 为引擎给出的数值（已带单位）。
struct HazardText {
    let name: String
    let desc: String
    let chain: String

    init(_ name: String, _ desc: String, _ chain: String) {
        self.name = name
        self.desc = desc
        self.chain = chain
    }
}

/// 一种语言下的全部防灾文案
///
/// - siteWords:    7 项，顺序同 SiteKind：坡地/低洼/路段/河道/海岸/水库/农田
/// - metricLabels: 18 项，顺序同 HazardEngine.M
/// - hazards:      26 项，顺序同 HazardType
struct HazardStrings {
    let cardTitle: String
    let cardLoading: String
    let cardEmpty: String
    let cardDisclaimer: String
    let chainLabel: String
    let factorLabel: String
    let levels: [String]
    let siteWords: [String]
    let metricLabels: [String]
    let knownLocTemplate: String
    let fallbackLocTemplate: String
    let nearCityTemplate: String
    let timeWindowTemplate: String
    let countTemplate: String
    let hazards: [HazardText]
}

enum HazardI18n {

    static func of(_ language: AppLanguage) -> HazardStrings {
        switch language {
        case .simplifiedChinese: return zhCN
        case .traditionalChinese: return zhTW
        case .english: return hazardEn
        case .japanese: return hazardJa
        case .korean: return hazardKo
        case .russian: return hazardRu
        }
    }

    // MARK: - 渲染

    /// 预测说明：填充时效与数值占位
    static func renderDesc(_ p: HazardPrediction, _ s: HazardStrings) -> String {
        s.hazards[p.type.rawValue].desc
            .replacingOccurrences(of: "{t}", with: "\(p.type.windowHours)")
            .replacingOccurrences(of: "{a}", with: p.valueA ?? "--")
            .replacingOccurrences(of: "{b}", with: p.valueB ?? "--")
    }

    /// 地点描述：命中具名要素时用地名，否则退回方位 + 地形载体
    static func renderLocation(_ p: HazardPrediction, _ s: HazardStrings, _ windDirs: [String]) -> String {
        let dir = p.bearingIndex < windDirs.count ? windDirs[p.bearingIndex] : (windDirs.first ?? "")
        let km = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), p.distanceKm)
        let kindIdx = p.type.siteKind.rawValue
        let site = kindIdx < s.siteWords.count ? s.siteWords[kindIdx] : ""
        if let name = p.featureName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return s.knownLocTemplate
                .replacingOccurrences(of: "{name}", with: name)
                .replacingOccurrences(of: "{dir}", with: dir)
                .replacingOccurrences(of: "{km}", with: km)
        }
        if p.distanceKm >= 1.0 {
            return s.fallbackLocTemplate
                .replacingOccurrences(of: "{dir}", with: dir)
                .replacingOccurrences(of: "{km}", with: km)
                .replacingOccurrences(of: "{site}", with: site)
        }
        return s.nearCityTemplate.replacingOccurrences(of: "{site}", with: site)
    }

    /// 时效标签
    static func renderWindow(_ p: HazardPrediction, _ s: HazardStrings) -> String {
        s.timeWindowTemplate.replacingOccurrences(of: "{t}", with: "\(p.type.windowHours)")
    }

    /// 条数标签
    static func renderCount(_ n: Int, _ s: HazardStrings) -> String {
        s.countTemplate.replacingOccurrences(of: "{n}", with: "\(n)")
    }

    // MARK: - 简体中文

    static let zhCN = HazardStrings(
        cardTitle: "地表防灾预报",
        cardLoading: "正在融合地形与气象数据推演…",
        cardEmpty: "未来 48 小时未发现明显地表灾害风险",
        cardDisclaimer: "本模块由地形高程网格、土壤与气象要素经本地多因子模型推演，属参考性提示，实际请以官方地质与气象预警为准。",
        chainLabel: "连锁影响",
        factorLabel: "关键因子",
        levels: ["紧急", "重要", "一般"],
        siteWords: ["山坡地带", "低洼地带", "主干路段", "河道沿岸", "海岸岸段", "水库周边", "农田片区"],
        metricLabels: [
            "网格坡度", "累计雨量", "小时雨强", "表层土壤含水", "深层土壤含水", "阵风",
            "积雪深度", "新增降雪", "最低气温", "最高气温", "冻融循环", "能见度",
            "相对湿度", "最低气压", "地形高差", "低洼占比", "对流能量", "最大风速"
        ],
        knownLocTemplate: "{name} 一带（城区{dir}方向约 {km} 公里）",
        fallbackLocTemplate: "城区{dir}方向约 {km} 公里的{site}",
        nearCityTemplate: "城区及近郊{site}",
        timeWindowTemplate: "未来 {t} 小时",
        countTemplate: "{n} 条",
        hazards: [
            HazardText(
                "泥石流",
                "未来{t}小时累计降雨可达 {a}，沟谷上游松散堆积体趋于饱和，易形成泥石流沿沟道下泄，冲毁沟口道路与房屋。",
                "泥石流堵塞沟道可形成堰塞体，短时溃决将造成下游二次涨水；携带的泥沙还会淤堵城市排水口，加重内涝。"
            ),
            HazardText(
                "山体滑坡",
                "{t}小时雨量 {a} 叠加深层土壤含水 {b}，坡体抗剪强度下降，坡面可能整体下滑。",
                "滑坡体可切断坡下道路与管线；滑塌土体入河后抬高河床，增大下游漫堤风险。"
            ),
            HazardText(
                "崩塌落石",
                "降雨与冻融作用使岩体裂隙扩张，未来{t}小时陡坡段易发生崩塌落石；该处网格尺度坡度约 {a}，坡脚道路与停车区域需避让。",
                "落石堆积可造成单车道中断，后续车辆紧急避让易引发二次事故。"
            ),
            HazardText(
                "路基边坡垮塌",
                "路基边坡长时间浸水，未来{t}小时 {a} 降雨可能造成路肩垮塌、护坡溜方，出现半幅通行甚至断道。",
                "边坡垮塌堵塞排水沟后，路面积水迅速抬升，进一步淘刷路基形成塌陷坑。"
            ),
            HazardText(
                "山洪暴发",
                "短时强降雨（{t}小时 {a}，最大小时雨强 {b}）在山区汇流迅速，溪沟水位可短时暴涨，河滩与露营地危险。",
                "山洪携带枯枝乱石堵塞桥涵，回水将淹没上游村道；洪峰下泄后叠加城区排水，抬高下游河段水位。"
            ),
            HazardText(
                "路面积水",
                "未来{t}小时降雨 {a} 超过城市排水能力，低洼路段积水预计涨高约 {b}，小型车辆涉水熄火风险高。",
                "积水淹没窨井后可能顶开井盖形成暗坑；浸泡地下车库与配电箱还会引发停电与电梯停运。"
            ),
            HazardText(
                "涵洞倒灌",
                "下穿隧道与铁路涵洞为汇水最低点，未来{t}小时可能倒灌积水约 {a}，深度超过 0.3 米即应禁止通行。",
                "涵洞积水造成车辆滞留后，抽排作业将长时间占用车道，周边路网出现连锁拥堵。"
            ),
            HazardText(
                "河道涨水漫堤",
                "流域{t}小时面雨量 {a}，河道水位预计上涨 {b}，低堤段与河滨步道可能漫水。",
                "河道涨水顶托支流与市政排口，沿河片区排水不畅，内涝退水时间延长数小时。"
            ),
            HazardText(
                "水库泄洪",
                "水库集雨区{t}小时来水 {a}，为腾出防洪库容可能开闸泄洪，下游河道流量短时增大。",
                "泄洪与降雨洪峰叠加时，下游河滩作业面与低水桥须提前撤离。"
            ),
            HazardText(
                "农田内涝",
                "农田{t}小时受雨 {a}，表层土壤含水已达 {b}，排水不畅田块将出现渍水，作物根系缺氧。",
                "渍水持续超过两天易诱发根腐与倒伏；退水后高温高湿还将加重病虫害流行。"
            ),
            HazardText(
                "风暴潮增水",
                "近岸气压降至 {a} 并伴强向岸风，预计海岸线水位增高约 {b}，叠加天文高潮时低洼岸段将过水。",
                "增水顶托入海河口使河口段水位同步抬升；海水倒灌还会造成岸边农田与地下管网盐渍化。"
            ),
            HazardText(
                "近岸巨浪",
                "阵风 {a} 作用下近岸有效波高可达 {b}，礁石区、堤坝与观浪平台存在卷人风险。",
                "巨浪冲毁护岸块石后，后续潮汐将持续淘刷堤脚，形成岸线蚀退。"
            ),
            HazardText(
                "潮水顶托倒灌",
                "高潮位顶托叠加上游{t}小时来水 {a}，感潮河段排水受阻，沿岸低地可能出现倒灌。",
                "倒灌咸水进入排水管网，退潮后管道淤积与腐蚀加剧，后续排涝能力下降。"
            ),
            HazardText(
                "道路结冰",
                "最低气温 {a} 且路面存在液态水膜，未来{t}小时易形成道路结冰，制动距离将延长数倍。",
                "结冰路段发生追尾后救援车辆通行受阻，封闭路段的绕行流量将压向次干道。"
            ),
            HazardText(
                "桥面暗冰",
                "桥面与高架上下表面同时散热，降温快于普通路面，最低气温 {a} 时{t}小时内可能出现暗冰。",
                "暗冰导致车辆失控撞击护栏，桥梁伸缩缝受损后需限速，通行能力长期下降。"
            ),
            HazardText(
                "积雪荷载",
                "累计新增降雪 {a}、积雪深度 {b}，简易棚架、大跨彩钢屋面与温室荷载超限风险上升。",
                "屋面压塌可砸断进户电线；融雪期屋顶滑落雪块还会威胁檐下通道行人。"
            ),
            HazardText(
                "雪崩",
                "高山积雪深度 {a} 并有 {b} 新雪覆盖，弱层结构不稳，陡坡背风侧可能发生雪崩。",
                "雪崩堆积体堵塞山谷道路与溪流，升温后融水下泄将形成融雪型洪水。"
            ),
            HazardText(
                "融雪型洪水",
                "气温回升至 {a}，积雪 {b} 进入快速消融期，未来{t}小时融雪径流叠加降雨将抬高河道水位。",
                "融雪水下渗使坡体含水饱和，滑坡与路基翻浆概率同步升高。"
            ),
            HazardText(
                "冻融翻浆",
                "未来{t}小时经历约 {a} 次冻融循环，含水路基反复胀缩，易出现翻浆、裂缝与坑槽。",
                "路面坑槽积水在夜间再次结冰形成局部冰坑，两轮车侧滑风险显著上升。"
            ),
            HazardText(
                "大风损毁",
                "阵风可达 {a}（约 {b} 级），广告牌、施工围挡、行道树与临时构筑物存在倒塌掀落风险。",
                "大风折断树枝压覆线路造成停电；高空坠物阻断人行道，须避开临街阳台与脚手架。"
            ),
            HazardText(
                "高速团雾",
                "高湿静风条件下能见度可能降至 {a} 米，高速与跨河桥段易生团雾，雾区内外能见度突变明显。",
                "团雾中一旦发生碰撞，后方车辆制动不及将扩大事故规模，路段封闭概率高。"
            ),
            HazardText(
                "扬沙沙尘",
                "地表干燥（相对湿度低至 {b}%）叠加阵风 {a}，裸露地表与工地易起沙扬尘，能见度短时下降。",
                "扬尘使空气质量迅速转差，呼吸道敏感人群症状加重；沙粒落于路面还会降低轮胎附着力。"
            ),
            HazardText(
                "山林火险",
                "连续少雨、相对湿度低至 {b}% 且最高气温 {a}，林区与草坡可燃物含水率低，火险等级偏高。",
                "山火沿坡向上蔓延迅速，过火后坡面失去植被固结，下一轮降雨极易引发水土流失与泥石流。"
            ),
            HazardText(
                "土壤干裂",
                "近{t}小时降水稀少，表层土壤含水降至 {a}，农田表层收缩开裂，作物出现旱情胁迫。",
                "裂隙加速深层水分散失；后续强降雨时雨水沿裂隙下渗，反而增加坡耕地滑塌可能。"
            ),
            HazardText(
                "路面塌陷",
                "强降雨冲刷叠加管网渗漏，未来{t}小时 {a} 雨量可能造成路基脱空塌陷，路面异常下沉或积水漩涡是前兆。",
                "塌陷坑损坏地下管线可能引发燃气泄漏或供水中断，抢修封路将改变周边交通组织。"
            ),
            HazardText(
                "水土流失",
                "坡面裸土在{t}小时 {a} 降雨冲刷下产生片蚀与细沟侵蚀，泥沙随径流进入下游沟道。",
                "泥沙淤积抬高河床与排水沟底，同等雨量下漫溢门槛降低，内涝与漫堤风险随之上升。"
            )
        ]
    )

    // MARK: - 繁體中文

    static let zhTW = HazardStrings(
        cardTitle: "地表防災預報",
        cardLoading: "正在融合地形與氣象資料推演…",
        cardEmpty: "未來 48 小時未發現明顯地表災害風險",
        cardDisclaimer: "本模組由地形高程網格、土壤與氣象要素經本地多因子模型推演，屬參考性提示，實際請以官方地質與氣象預警為準。",
        chainLabel: "連鎖影響",
        factorLabel: "關鍵因子",
        levels: ["緊急", "重要", "一般"],
        siteWords: ["山坡地帶", "低窪地帶", "主幹路段", "河道沿岸", "海岸岸段", "水庫周邊", "農田片區"],
        metricLabels: [
            "網格坡度", "累計雨量", "小時雨強", "表層土壤含水", "深層土壤含水", "陣風",
            "積雪深度", "新增降雪", "最低氣溫", "最高氣溫", "凍融循環", "能見度",
            "相對濕度", "最低氣壓", "地形高差", "低窪佔比", "對流能量", "最大風速"
        ],
        knownLocTemplate: "{name} 一帶（市區{dir}方向約 {km} 公里）",
        fallbackLocTemplate: "市區{dir}方向約 {km} 公里的{site}",
        nearCityTemplate: "市區及近郊{site}",
        timeWindowTemplate: "未來 {t} 小時",
        countTemplate: "{n} 條",
        hazards: [
            HazardText(
                "土石流",
                "未來{t}小時累計降雨可達 {a}，溝谷上游鬆散堆積體趨於飽和，易形成土石流沿溝道下洩，沖毀溝口道路與房屋。",
                "土石流堵塞溝道可形成堰塞體，短時潰決將造成下游二次漲水；攜帶的泥沙還會淤堵城市排水口，加重內澇。"
            ),
            HazardText(
                "山體滑坡",
                "{t}小時雨量 {a} 疊加深層土壤含水 {b}，坡體抗剪強度下降，坡面可能整體下滑。",
                "滑坡體可切斷坡下道路與管線；滑塌土體入河後抬高河床，增大下游漫堤風險。"
            ),
            HazardText(
                "崩塌落石",
                "降雨與凍融作用使岩體裂隙擴張，未來{t}小時陡坡段易發生崩塌落石；該處網格尺度坡度約 {a}，坡腳道路與停車區域需避讓。",
                "落石堆積可造成單車道中斷，後續車輛緊急避讓易引發二次事故。"
            ),
            HazardText(
                "路基邊坡垮塌",
                "路基邊坡長時間浸水，未來{t}小時 {a} 降雨可能造成路肩垮塌、護坡溜方，出現半幅通行甚至斷道。",
                "邊坡垮塌堵塞排水溝後，路面積水迅速抬升，進一步淘刷路基形成塌陷坑。"
            ),
            HazardText(
                "山洪暴發",
                "短時強降雨（{t}小時 {a}，最大小時雨強 {b}）在山區匯流迅速，溪溝水位可短時暴漲，河灘與露營地危險。",
                "山洪攜帶枯枝亂石堵塞橋涵，回水將淹沒上游村道；洪峰下洩後疊加市區排水，抬高下游河段水位。"
            ),
            HazardText(
                "路面積水",
                "未來{t}小時降雨 {a} 超過城市排水能力，低窪路段積水預計漲高約 {b}，小型車輛涉水熄火風險高。",
                "積水淹沒人孔後可能頂開井蓋形成暗坑；浸泡地下停車場與配電箱還會引發停電與電梯停運。"
            ),
            HazardText(
                "涵洞倒灌",
                "下穿隧道與鐵路涵洞為匯水最低點，未來{t}小時可能倒灌積水約 {a}，深度超過 0.3 公尺即應禁止通行。",
                "涵洞積水造成車輛滯留後，抽排作業將長時間佔用車道，周邊路網出現連鎖擁堵。"
            ),
            HazardText(
                "河道漲水漫堤",
                "流域{t}小時面雨量 {a}，河道水位預計上漲 {b}，低堤段與河濱步道可能漫水。",
                "河道漲水頂托支流與市政排口，沿河片區排水不暢，內澇退水時間延長數小時。"
            ),
            HazardText(
                "水庫洩洪",
                "水庫集雨區{t}小時來水 {a}，為騰出防洪庫容可能開閘洩洪，下游河道流量短時增大。",
                "洩洪與降雨洪峰疊加時，下游河灘作業面與低水橋須提前撤離。"
            ),
            HazardText(
                "農田內澇",
                "農田{t}小時受雨 {a}，表層土壤含水已達 {b}，排水不暢田塊將出現漬水，作物根系缺氧。",
                "漬水持續超過兩天易誘發根腐與倒伏；退水後高溫高濕還將加重病蟲害流行。"
            ),
            HazardText(
                "風暴潮增水",
                "近岸氣壓降至 {a} 並伴強向岸風，預計海岸線水位增高約 {b}，疊加天文高潮時低窪岸段將過水。",
                "增水頂托入海河口使河口段水位同步抬升；海水倒灌還會造成岸邊農田與地下管網鹽漬化。"
            ),
            HazardText(
                "近岸巨浪",
                "陣風 {a} 作用下近岸有效波高可達 {b}，礁石區、堤壩與觀浪平台存在捲人風險。",
                "巨浪沖毀護岸塊石後，後續潮汐將持續淘刷堤腳，形成岸線蝕退。"
            ),
            HazardText(
                "潮水頂托倒灌",
                "高潮位頂托疊加上游{t}小時來水 {a}，感潮河段排水受阻，沿岸低地可能出現倒灌。",
                "倒灌鹹水進入排水管網，退潮後管道淤積與腐蝕加劇，後續排澇能力下降。"
            ),
            HazardText(
                "道路結冰",
                "最低氣溫 {a} 且路面存在液態水膜，未來{t}小時易形成道路結冰，制動距離將延長數倍。",
                "結冰路段發生追撞後救援車輛通行受阻，封閉路段的繞行流量將壓向次幹道。"
            ),
            HazardText(
                "橋面暗冰",
                "橋面與高架上下表面同時散熱，降溫快於普通路面，最低氣溫 {a} 時{t}小時內可能出現暗冰。",
                "暗冰導致車輛失控撞擊護欄，橋樑伸縮縫受損後需限速，通行能力長期下降。"
            ),
            HazardText(
                "積雪荷載",
                "累計新增降雪 {a}、積雪深度 {b}，簡易棚架、大跨彩鋼屋面與溫室荷載超限風險上升。",
                "屋面壓塌可砸斷進戶電線；融雪期屋頂滑落雪塊還會威脅簷下通道行人。"
            ),
            HazardText(
                "雪崩",
                "高山積雪深度 {a} 並有 {b} 新雪覆蓋，弱層結構不穩，陡坡背風側可能發生雪崩。",
                "雪崩堆積體堵塞山谷道路與溪流，升溫後融水下洩將形成融雪型洪水。"
            ),
            HazardText(
                "融雪型洪水",
                "氣溫回升至 {a}，積雪 {b} 進入快速消融期，未來{t}小時融雪徑流疊加降雨將抬高河道水位。",
                "融雪水下滲使坡體含水飽和，滑坡與路基翻漿機率同步升高。"
            ),
            HazardText(
                "凍融翻漿",
                "未來{t}小時經歷約 {a} 次凍融循環，含水路基反覆脹縮，易出現翻漿、裂縫與坑槽。",
                "路面坑槽積水在夜間再次結冰形成局部冰坑，兩輪車側滑風險顯著上升。"
            ),
            HazardText(
                "大風損毀",
                "陣風可達 {a}（約 {b} 級），廣告招牌、施工圍擋、行道樹與臨時構築物存在倒塌掀落風險。",
                "大風折斷樹枝壓覆線路造成停電；高空墜物阻斷人行道，須避開臨街陽台與腳架。"
            ),
            HazardText(
                "高速團霧",
                "高濕靜風條件下能見度可能降至 {a} 公尺，高速與跨河橋段易生團霧，霧區內外能見度突變明顯。",
                "團霧中一旦發生碰撞，後方車輛制動不及將擴大事故規模，路段封閉機率高。"
            ),
            HazardText(
                "揚沙沙塵",
                "地表乾燥（相對濕度低至 {b}%）疊加陣風 {a}，裸露地表與工地易起沙揚塵，能見度短時下降。",
                "揚塵使空氣品質迅速轉差，呼吸道敏感人群症狀加重；沙粒落於路面還會降低輪胎附著力。"
            ),
            HazardText(
                "山林火險",
                "連續少雨、相對濕度低至 {b}% 且最高氣溫 {a}，林區與草坡可燃物含水率低，火險等級偏高。",
                "山火沿坡向上蔓延迅速，過火後坡面失去植被固結，下一輪降雨極易引發水土流失與土石流。"
            ),
            HazardText(
                "土壤乾裂",
                "近{t}小時降水稀少，表層土壤含水降至 {a}，農田表層收縮開裂，作物出現旱情脅迫。",
                "裂隙加速深層水分散失；後續強降雨時雨水沿裂隙下滲，反而增加坡耕地滑塌可能。"
            ),
            HazardText(
                "路面塌陷",
                "強降雨沖刷疊加管網滲漏，未來{t}小時 {a} 雨量可能造成路基脫空塌陷，路面異常下沉或積水漩渦是前兆。",
                "塌陷坑損壞地下管線可能引發燃氣洩漏或供水中斷，搶修封路將改變周邊交通組織。"
            ),
            HazardText(
                "水土流失",
                "坡面裸土在{t}小時 {a} 降雨沖刷下產生片蝕與細溝侵蝕，泥沙隨徑流進入下游溝道。",
                "泥沙淤積抬高河床與排水溝底，同等雨量下漫溢門檻降低，內澇與漫堤風險隨之上升。"
            )
        ]
    )
}
