import Foundation

/// 地表防灾预报数据模型（对应 Android data/model/GeoHazard.kt）
///
/// 设计要点：推理引擎只产出「语言无关」的结构化结果（灾害类型 + 等级 + 数值 + 方位索引），
/// 具体文案在 UI 层用 HazardI18n 按当前语言拼装，因此切换语言无需重新请求与重新推理。

/// 预测等级：紧急 > 重要 > 一般（rawValue 越小越靠前展示）
enum HazardLevel: Int, Comparable {
    case emergency = 0
    case important = 1
    case normal = 2

    var colorHex: UInt32 {
        switch self {
        case .emergency: return 0xFFD50000
        case .important: return 0xFFFF6D00
        case .normal: return 0xFF1E88E5
        }
    }

    var deepColorHex: UInt32 {
        switch self {
        case .emergency: return 0xFFB71C1C
        case .important: return 0xFFBF5B00
        case .normal: return 0xFF0D47A1
        }
    }

    static func < (lhs: HazardLevel, rhs: HazardLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    /// 评分 -> 等级；cap 为该灾种可达到的最高等级（避免轻量灾害被判为紧急）
    static func fromScore(_ score: Double, cap: HazardLevel) -> HazardLevel? {
        let raw: HazardLevel
        if score >= 0.72 { raw = .emergency }
        else if score >= 0.48 { raw = .important }
        else if score >= 0.26 { raw = .normal }
        else { return nil }
        return raw.rawValue < cap.rawValue ? cap : raw
    }
}

/// 灾害发生的地形载体类型，决定地点名称从哪类 OSM 要素里挑
enum SiteKind: Int, CaseIterable {
    case slope = 0      // 山地/陡坡
    case lowland        // 城区低洼地带
    case road           // 道路/高速路段
    case river          // 河流/江道沿岸
    case coast          // 海岸线
    case reservoir      // 水库/湖泊
    case farmland       // 农田/村庄外围
}

/// 26 类地表灾害。rawValue 即 HazardI18n.hazards 的文案索引，切勿随意插入或重排。
enum HazardType: Int, CaseIterable {
    case debrisFlow = 0     // 泥石流
    case landslide          // 山体滑坡
    case rockfall           // 崩塌落石
    case slopeCollapse      // 路基边坡垮塌
    case flashFlood         // 山洪暴发
    case urbanWaterlog      // 路面积水
    case underpassFlood     // 下穿隧道/涵洞倒灌
    case riverFlood         // 河道涨水漫堤
    case reservoirSpill     // 水库超汛限泄洪
    case farmlandWaterlog   // 农田内涝
    case stormSurge         // 风暴潮增水
    case highWaves          // 近岸巨浪
    case tidalBackflow      // 潮水顶托倒灌
    case roadIce            // 道路结冰
    case bridgeIce          // 桥面/高架结冰
    case snowLoad           // 积雪荷载压塌
    case avalanche          // 雪崩
    case snowmeltFlood      // 融雪型洪水
    case frostHeave         // 冻融翻浆
    case windDamage         // 大风损毁
    case highwayFog         // 高速团雾
    case dustStorm          // 扬沙沙尘
    case wildfire           // 山林火险
    case soilCrack          // 土壤干裂
    case groundSubsidence   // 路面塌陷
    case erosion            // 水土流失

    /// (地点载体, 预测时效窗口小时, 最高等级封顶)
    private var spec: (SiteKind, Int, HazardLevel) {
        switch self {
        case .debrisFlow:       return (.slope, 6, .emergency)
        case .landslide:        return (.slope, 24, .emergency)
        case .rockfall:         return (.slope, 12, .important)
        case .slopeCollapse:    return (.road, 12, .emergency)
        case .flashFlood:       return (.slope, 3, .emergency)
        case .urbanWaterlog:    return (.lowland, 3, .emergency)
        case .underpassFlood:   return (.road, 3, .emergency)
        case .riverFlood:       return (.river, 24, .emergency)
        case .reservoirSpill:   return (.reservoir, 24, .important)
        case .farmlandWaterlog: return (.farmland, 24, .important)
        case .stormSurge:       return (.coast, 12, .emergency)
        case .highWaves:        return (.coast, 12, .important)
        case .tidalBackflow:    return (.river, 12, .important)
        case .roadIce:          return (.road, 12, .emergency)
        case .bridgeIce:        return (.road, 12, .emergency)
        case .snowLoad:         return (.lowland, 24, .important)
        case .avalanche:        return (.slope, 24, .emergency)
        case .snowmeltFlood:    return (.river, 48, .important)
        case .frostHeave:       return (.road, 24, .normal)
        case .windDamage:       return (.lowland, 12, .emergency)
        case .highwayFog:       return (.road, 12, .important)
        case .dustStorm:        return (.lowland, 12, .important)
        case .wildfire:         return (.slope, 48, .important)
        case .soilCrack:        return (.farmland, 48, .normal)
        case .groundSubsidence: return (.road, 24, .important)
        case .erosion:          return (.slope, 24, .normal)
        }
    }

    var siteKind: SiteKind { spec.0 }
    var windowHours: Int { spec.1 }
    var levelCap: HazardLevel { spec.2 }
}

/// 一条参与判定的关键因子。labelIndex 对应 HazardI18n.metricLabels 的位置，
/// text 为已格式化好的语言中立数值（含单位符号）。
struct HazardMetric: Identifiable {
    let labelIndex: Int
    let text: String

    var id: String { "\(labelIndex)|\(text)" }
}

/// 单条灾害预测（语言无关）
///
/// - featureName: OSM 命中的具体地名（街道/村/高速/河流…），无命中时为 nil 走方位回退文案
/// - bearingIndex: 相对城市中心的方位索引（0=北，顺时针，对应 Strings.windDirs）
/// - valueA/valueB: 文案模板里的 {a}/{b} 数值占位（如积水深度、增水高度）
struct HazardPrediction: Identifiable {
    let type: HazardType
    let level: HazardLevel
    let score: Double
    let featureName: String?
    let bearingIndex: Int
    let distanceKm: Double
    var valueA: String? = nil
    var valueB: String? = nil
    var metrics: [HazardMetric] = []

    var id: String { "\(type.rawValue)|\(featureName ?? "")|\(bearingIndex)" }
}

/// 卡片状态
struct HazardUiState {
    var isLoading = false
    var predictions: [HazardPrediction] = []
    var analyzed = false
}

// MARK: - 地形分析结果

/// 地形网格采样点
struct TerrainPoint {
    let lat: Double
    let lon: Double
    let elevation: Double
    var slopeDeg: Double = 0
}

/// 城市周边地形画像（网格尺度，非真实沟谷坡度）
struct TerrainProfile {
    let centerLat: Double
    let centerLon: Double
    let centerElevation: Double
    let minElevation: Double
    let maxElevation: Double
    let meanElevation: Double
    let relief: Double            // 高差 = max - min（米）
    let maxSlopeDeg: Double
    let meanSlopeDeg: Double
    let seaRatio: Double          // 海拔 <= 0.5 的采样点占比，用于判定沿海
    let lowlandRatio: Double      // 低于中心且低于均值的点占比，用于判定易涝
    let steepPoint: TerrainPoint?
    let lowPoint: TerrainPoint?
    let highPoint: TerrainPoint?
    let seaPoint: TerrainPoint?
    let gridSpacingKm: Double     // 网格间距（公里），坡度以此尺度计算

    var isCoastal: Bool { seaRatio > 0.04 }
    var isMountainous: Bool { relief >= 150 || maxSlopeDeg >= 4 }
}

/// OSM 地理要素类别
enum GeoFeatureKind {
    case settlement, road, river, coast, reservoir, peak
}

/// OSM 命中的一个具名地理要素
struct GeoFeature {
    let kind: GeoFeatureKind
    let name: String
    let lat: Double
    let lon: Double
}

// MARK: - API 响应模型

/// Open-Meteo 高程接口响应
struct ElevationResponse: Decodable {
    let elevation: [Double]?
}

/// Overpass API 响应
struct OverpassResponse: Decodable {
    let elements: [OverpassElement]?
}

struct OverpassElement: Decodable {
    let type: String?
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

struct OverpassCenter: Decodable {
    let lat: Double?
    let lon: Double?
}

/// 灾害推理专用的扩展逐小时要素（字段全部可空，部分模型不提供土壤/冻结高度）
struct HazardHourly: Decodable {
    var time: [String] = []
    var temperature: [Double?]?
    var humidity: [Int?]?
    var precipitation: [Double?]?
    var rain: [Double?]?
    var snowfall: [Double?]?
    var snowDepth: [Double?]?
    var precipProbability: [Int?]?
    var windSpeed: [Double?]?
    var windGusts: [Double?]?
    var windDirection: [Double?]?
    var visibility: [Double?]?
    var surfacePressure: [Double?]?
    var soilMoistureTop: [Double?]?
    var soilMoistureMid: [Double?]?
    var soilMoistureDeep: [Double?]?
    var soilTemperature: [Double?]?
    var freezingLevel: [Double?]?
    var cape: [Double?]?
    var weatherCode: [Int?]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case humidity = "relative_humidity_2m"
        case precipitation
        case rain
        case snowfall
        case snowDepth = "snow_depth"
        case precipProbability = "precipitation_probability"
        case windSpeed = "wind_speed_10m"
        case windGusts = "wind_gusts_10m"
        case windDirection = "wind_direction_10m"
        case visibility
        case surfacePressure = "surface_pressure"
        case soilMoistureTop = "soil_moisture_0_to_1cm"
        case soilMoistureMid = "soil_moisture_3_to_9cm"
        case soilMoistureDeep = "soil_moisture_27_to_81cm"
        case soilTemperature = "soil_temperature_0cm"
        case freezingLevel = "freezing_level_height"
        case cape
        case weatherCode = "weather_code"
    }
}

/// 当前时刻（仅取时间戳，用于对齐逐小时数组的起点）
struct HazardCurrent: Decodable {
    let time: String?
}

/// 灾害推理专用预报响应（顶层 elevation 为模型格点海拔）
struct HazardForecastResponse: Decodable {
    let elevation: Double?
    let current: HazardCurrent?
    let hourly: HazardHourly?
}
