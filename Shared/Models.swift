import Foundation

// MARK: - 语言 / 枚举设置（与 Android AppSettings.kt 一一对应）

/// 应用语言
enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case simplifiedChinese = "zh"
    case traditionalChinese = "zh-TW"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .russian: return "Русский"
        }
    }

    var code: String { rawValue }
}

/// 显示模式
enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
}

/// 温度单位
enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case celsius, fahrenheit
    var id: String { rawValue }

    var symbol: String { self == .celsius ? "°C" : "°F" }

    func convert(_ celsius: Double) -> Double {
        self == .celsius ? celsius : celsius * 9.0 / 5.0 + 32.0
    }
}

/// 风速单位
enum WindSpeedUnit: String, Codable, CaseIterable, Identifiable {
    case kmh, mph, ms
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .kmh: return "km/h"
        case .mph: return "mph"
        case .ms: return "m/s"
        }
    }

    func convert(_ kmh: Double) -> Double {
        switch self {
        case .kmh: return kmh
        case .mph: return kmh * 0.621371
        case .ms: return kmh / 3.6
        }
    }
}

/// 预警等级
enum AlertSeverity: String, Codable, CaseIterable, Identifiable {
    case warning, severe, extreme
    var id: String { rawValue }

    var priority: Int {
        switch self {
        case .warning: return 0
        case .severe: return 1
        case .extreme: return 2
        }
    }

    /// ARGB 颜色值（黄 / 橙 / 红）
    var colorHex: UInt32 {
        switch self {
        case .warning: return 0xFFFFD600
        case .severe: return 0xFFFF6D00
        case .extreme: return 0xFFD50000
        }
    }
}

/// 预警类型
enum AlertType: String, Codable {
    case strongWind, storm, heavyRain, heavySnow, sandstorm, fog
    case thunderstorm, hail, freezingRain, blizzard, extremeHeat, extremeCold
}

/// 用户设置（默认值与 Android 版一致）
struct AppSettings: Codable, Equatable {
    var language: AppLanguage = .simplifiedChinese
    var themeMode: ThemeMode = .system
    var themeColorIndex: Int = 0
    var temperatureUnit: TemperatureUnit = .celsius
    var windSpeedUnit: WindSpeedUnit = .kmh
    var alertEnabled: Bool = true
    var alertMinSeverity: AlertSeverity = .warning
    var refreshIntervalMinutes: Int = 30
    var clockWidgetOpacity: Int = 100      // 时钟小组件底板不透明度（20~100%）
    var weatherWidgetOpacity: Int = 100    // 气象小组件底板不透明度（20~100%）
    var widgetThemeIndex: Int = 0          // 小组件主题色：0=动态（随天气/时段），1~5=固定配色
}

// MARK: - 城市

/// 城市信息
struct CityInfo: Codable, Equatable, Identifiable, Hashable {
    let id: String                 // 唯一标识（经纬度拼接）
    var name: String               // 城市名（添加时语言，通常为中文）
    var country: String            // 国家
    var admin1: String?            // 省/州
    var latitude: Double
    var longitude: Double
    var timezone: String?
    var localizedNames: [String: String]?    // 语言code -> 本地化城市名
    var localizedAdmins: [String: String]?   // 语言code -> 本地化省/州名
    var geoId: Int?                          // open-meteo geocoding 地点 ID（跨语言取名用）

    /// 按语言取城市名（无缓存翻译时回退原始名）
    func nameFor(_ language: AppLanguage) -> String {
        if let n = localizedNames?[language.code], !n.isEmpty { return n }
        return name
    }

    /// 按语言取省/州名
    func admin1For(_ language: AppLanguage) -> String? {
        if let a = localizedAdmins?[language.code], !a.isEmpty { return a }
        return admin1
    }

    /// 按语言取显示标签（城市, 省/州）
    func displayNameFor(_ language: AppLanguage) -> String {
        let n = nameFor(language)
        if let a = admin1For(language), !a.isEmpty { return "\(n), \(a)" }
        return "\(n), \(country)"
    }
}

/// open-meteo geocoding API 响应
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

/// geocoding 单条结果
struct GeocodingResult: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let country_code: String?
    let admin1: String?
    let timezone: String?

    func toCityInfo() -> CityInfo {
        CityInfo(
            id: "\(latitude)_\(longitude)",
            name: name,
            country: country ?? "",
            admin1: admin1,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            localizedNames: nil,
            localizedAdmins: nil,
            // 负数 id 为内置离线条目标记，非 open-meteo geoId，不能用于按 ID 取名
            geoId: id > 0 ? id : nil
        )
    }
}

// MARK: - 天气数据（open-meteo forecast API）

struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String?
    let current: CurrentWeather?
    let hourly: HourlyWeather?
    let daily: DailyWeather?
}

/// 当前天气
struct CurrentWeather: Codable {
    let time: String
    let temperature: Double
    let humidity: Int
    let apparentTemperature: Double
    let weatherCode: Int
    let windSpeed: Double
    let windDirection: Double
    let pressure: Double?
    let visibility: Double?
    let dewPoint: Double?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case humidity = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case windDirection = "wind_direction_10m"
        case pressure = "surface_pressure"
        case visibility
        case dewPoint = "dew_point_2m"
    }
}

/// 逐小时天气（用于预警分析）
struct HourlyWeather: Codable {
    let time: [String]
    let temperature: [Double]?
    let precipitation: [Double]?
    let weatherCode: [Int]?
    let windSpeed: [Double]?
    let visibility: [Double]?
    var precipitationProbability: [Int]? = nil
    // 对流有效位能与冻结高度：用于冰雹物理可行性判定（雹暴需强对流能量且 0°C 层不能过高）
    var cape: [Double]? = nil
    var freezingLevelHeight: [Double]? = nil

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case visibility
        case precipitationProbability = "precipitation_probability"
        case cape
        case freezingLevelHeight = "freezing_level_height"
    }
}

/// 逐日天气
struct DailyWeather: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let precipitationSum: [Double]?
    let precipitationProbabilityMax: [Int]?

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

/// UI 层使用的一天预报数据
struct DayForecast: Identifiable {
    let date: String
    let weatherCode: Int
    let tempMax: Double
    let tempMin: Double
    let precipitationSum: Double
    let precipitationProbability: Int
    var id: String { date }
}

// MARK: - 空气质量

struct AirQualityResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: AirQualityCurrent?
}

struct AirQualityCurrent: Codable {
    let time: String
    let aqi: Double?
    let pm10: Double?
    let pm25: Double?
    var uvIndex: Double? = nil

    enum CodingKeys: String, CodingKey {
        case time
        case aqi = "us_aqi"
        case pm10
        case pm25 = "pm2_5"
        case uvIndex = "uv_index"
    }
}

/// AQI 等级（us_aqi 量纲 0-500，与 Android AqiLevel 一致）
enum AqiLevel: Int, CaseIterable {
    case excellent = 0, good, passable, mild, severe, toxic, deadly

    var colorHex: UInt32 {
        switch self {
        case .excellent: return 0xFF4CAF50
        case .good: return 0xFF8BC34A
        case .passable: return 0xFFFFC107
        case .mild: return 0xFFFF9800
        case .severe: return 0xFFF44336
        case .toxic: return 0xFF9C27B0
        case .deadly: return 0xFF7B1FA2
        }
    }

    static func from(aqi: Int) -> AqiLevel {
        switch aqi {
        case 0...30: return .excellent
        case 31...60: return .good
        case 61...90: return .passable
        case 91...150: return .mild
        case 151...199: return .severe
        case 200...299: return .toxic
        default: return .deadly
        }
    }
}

/// 紫外线强度等级（UVI 0-11+，与 Android UvLevel 一致）
enum UvLevel: Int, CaseIterable {
    case excellent = 0, passable, scorching, dizzy, deadly

    var colorHex: UInt32 {
        switch self {
        case .excellent: return 0xFF4CAF50
        case .passable: return 0xFFFFC107
        case .scorching: return 0xFFFF9800
        case .dizzy: return 0xFFF44336
        case .deadly: return 0xFF9C27B0
        }
    }

    static func from(uvi: Int) -> UvLevel {
        switch uvi {
        case 0...2: return .excellent
        case 3...4: return .passable
        case 5...6: return .scorching
        case 7...9: return .dizzy
        default: return .deadly
        }
    }
}

// MARK: - 单城市完整天气缓存（供 UI 与小组件共享）

struct CityWeatherData: Codable {
    let city: CityInfo
    let current: CurrentWeather?
    let hourly: HourlyWeather?
    let daily: DailyWeather?
    let airQuality: AirQualityCurrent?
    var lastUpdated: Date = Date()

    var dayForecasts: [DayForecast] {
        guard let d = daily else { return [] }
        return d.time.indices.map { i in
            DayForecast(
                date: d.time[i],
                weatherCode: d.weatherCode[i],
                tempMax: d.temperatureMax[i],
                tempMin: d.temperatureMin[i],
                precipitationSum: (d.precipitationSum?.indices.contains(i) == true) ? d.precipitationSum![i] : 0.0,
                precipitationProbability: (d.precipitationProbabilityMax?.indices.contains(i) == true) ? d.precipitationProbabilityMax![i] : 0
            )
        }
    }
}

// MARK: - 恶劣天气预警

struct WeatherAlert {
    let cityId: String
    let cityName: String
    let alertType: AlertType
    let severity: AlertSeverity
    let message: String
    let detail: String
    let detectedAt: Date
    let expectedTime: String
}

/// 预警阈值配置（与 Android AlertThresholds 一致）
enum AlertThresholds {
    // 风速阈值 (km/h)
    static let windWarning = 40.0
    static let windSevere = 60.0
    static let windExtreme = 80.0

    // 降水量阈值 (mm/h)
    static let rainWarning = 10.0
    static let rainSevere = 20.0
    static let rainExtreme = 40.0

    // 能见度阈值 (m)
    static let visibilitySevere = 1000.0
    static let visibilityWarning = 500.0

    // 极端天气 WMO 代码（语义修正版，参照 WMO 4677 标准，与 Android 一致）
    static let severeWeatherCodes: Set<Int> = [56, 57, 65, 66, 67, 71, 73, 75, 77, 82, 85, 86, 95, 96, 99]
    static let extremeWeatherCodes: Set<Int> = [67, 99]

    /// 天气码 -> (预警类型, 预警等级)，逐码精确映射
    /// 修正旧版把 95 纯雷暴误标为"雷暴+冰雹"、65 大雨误标为"暴风雪"等问题
    static func codeAlertSpec(_ code: Int) -> (AlertType, AlertSeverity)? {
        switch code {
        case 56, 57: return (.freezingRain, .warning)
        case 66: return (.freezingRain, .severe)
        case 67: return (.freezingRain, .extreme)
        case 65: return (.heavyRain, .warning)
        case 82: return (.heavyRain, .severe)
        case 71, 73, 77: return (.heavySnow, .warning)
        case 75: return (.heavySnow, .severe)
        case 85: return (.blizzard, .warning)
        case 86: return (.blizzard, .severe)
        case 95: return (.thunderstorm, .warning)
        case 96: return (.hail, .severe)
        case 99: return (.hail, .extreme)
        default: return nil
        }
    }
}

/// 天气码气候合理性校验（与 Android ClimatePlausibility 一致）
///
/// 背景：open-meteo 官方文档注明 "Thunderstorm forecast with hail (96/99)
/// is only available in Central Europe"——在中欧以外地区，96/99 冰雹码
/// 直接采信会造成大面积误报；但也不能一刀切抹除（中国部分地区在强对流
/// 条件下确实会出现冰雹，包括寒冷季节的冷涡冰雹）。
/// 因此对中欧以外地区改用物理条件判定：CAPE（对流有效位能）+ 冻结高度，
/// 两者同时满足才保留冰雹码，否则降级为纯雷暴（95）。
enum ClimatePlausibility {

    /// 冰雹预报仅在中欧地区默认可信（open-meteo 官方限制），近似矩形范围
    static func isCentralEurope(latitude: Double, longitude: Double) -> Bool {
        (42.0...56.0).contains(latitude) && (2.0...26.0).contains(longitude)
    }

    /// 冰雹物理门槛：对流有效位能(J/kg)，低于此值大气能量不足以支撑雹暴
    static let hailMinCape = 800.0

    /// 冰雹物理门槛：冻结高度(m)，0°C 层过高时冰雹在落地前几乎全部融化
    static let hailMaxFreezingLevelM = 4300.0

    /// 冰雹物理合理性判定（中欧以外地区 96/99 码的保留条件）：
    /// 需同时满足强对流能量（CAPE ≥ 800 J/kg）与足够低的冻结高度（≤ 4300 m）。
    /// 任一数据缺失时按不合理处理（保守降级，避免模型伪信号）。
    static func isHailPlausible(cape: Double?, freezingLevelHeight: Double?) -> Bool {
        guard let cape, let flh = freezingLevelHeight else { return false }
        return cape >= hailMinCape && flh <= hailMaxFreezingLevelM
    }

    /// 冰冻类天气码：冻毛毛雨/冻雨/降雪/雪粒/阵雪
    static let frozenCodes: Set<Int> = [56, 57, 66, 67, 71, 73, 75, 77, 85, 86]

    /// 冰冻类现象在气温高于此值(°C)时判定为不合理
    static let frozenMaxTempC = 3.0

    /// 天气码类预警要求的最低降水概率(%)，低于则视为模型噪声不告警
    static let minPrecipProbability = 50

    /// 归一化整份预报响应（current/hourly/daily 的天气码），供展示/小组件链路统一使用。
    ///
    /// 非中欧地区的 96/99 码逐小时做物理条件判定（CAPE + 冻结高度），
    /// 通过则保留冰雹展示，未通过降级为 95。daily.weather_code 取全天“最严重”
    /// 小时码，因此按日回查：当天存在至少 1 个通过判定的冰雹小时才保留。
    /// 地区判定用响应自带的模型格点经纬度。
    static func normalizeResponse(_ response: WeatherResponse) -> WeatherResponse {
        if isCentralEurope(latitude: response.latitude, longitude: response.longitude) { return response }
        let hourly = response.hourly
        let codes = hourly?.weatherCode

        // 该小时的 96/99 是否可保留（物理条件判定，数据缺失则保守降级）
        func hourAllowsHail(_ i: Int) -> Bool {
            guard let h = hourly else { return false }
            let cape = (h.cape?.indices.contains(i) == true) ? h.cape![i] : nil
            let flh = (h.freezingLevelHeight?.indices.contains(i) == true) ? h.freezingLevelHeight![i] : nil
            return isHailPlausible(cape: cape, freezingLevelHeight: flh)
        }

        var newHourly = hourly
        if let h = hourly, let hCodes = codes, hCodes.contains(where: { $0 == 96 || $0 == 99 }) {
            let fixed = hCodes.enumerated().map { i, c in
                (c == 96 || c == 99) && !hourAllowsHail(i) ? 95 : c
            }
            if fixed != hCodes {
                newHourly = HourlyWeather(
                    time: h.time, temperature: h.temperature, precipitation: h.precipitation,
                    weatherCode: fixed, windSpeed: h.windSpeed, visibility: h.visibility,
                    precipitationProbability: h.precipitationProbability,
                    cape: h.cape, freezingLevelHeight: h.freezingLevelHeight
                )
            }
        }

        // 当前天气：取同一小时的判定结果，找不到对应小时则保守降级
        var current = response.current
        if let c = current, c.weatherCode == 96 || c.weatherCode == 99 {
            let hourKey = String(c.time.prefix(13)) // "yyyy-MM-ddTHH"
            let idx = hourly?.time.firstIndex(where: { $0.hasPrefix(hourKey) })
            if !(idx != nil && hourAllowsHail(idx!)) {
                current = CurrentWeather(
                    time: c.time, temperature: c.temperature, humidity: c.humidity,
                    apparentTemperature: c.apparentTemperature, weatherCode: 95,
                    windSpeed: c.windSpeed, windDirection: c.windDirection,
                    pressure: c.pressure, visibility: c.visibility, dewPoint: c.dewPoint
                )
            }
        }

        // 逐日：当天任意一小时保留冰雹才保留，否则降级
        var daily = response.daily
        if let d = daily, d.weatherCode.contains(where: { $0 == 96 || $0 == 99 }) {
            let fixed = d.weatherCode.enumerated().map { i, c -> Int in
                guard c == 96 || c == 99 else { return c }
                guard let date = d.time.indices.contains(i) ? d.time[i] : nil,
                      let hCodes = codes, let h = hourly else { return 95 }
                let keep = hCodes.indices.contains { j in
                    (hCodes[j] == 96 || hCodes[j] == 99) &&
                        h.time.indices.contains(j) && h.time[j].hasPrefix(date) && hourAllowsHail(j)
                }
                return keep ? c : 95
            }
            if fixed != d.weatherCode {
                daily = DailyWeather(
                    time: d.time, weatherCode: fixed,
                    temperatureMax: d.temperatureMax, temperatureMin: d.temperatureMin,
                    precipitationSum: d.precipitationSum, precipitationProbabilityMax: d.precipitationProbabilityMax
                )
            }
        }
        return WeatherResponse(
            latitude: response.latitude, longitude: response.longitude,
            timezone: response.timezone, current: current, hourly: newHourly, daily: daily
        )
    }

    /// 判断天气码在当前气温下是否合理（temperatureC 为 nil 时不做温度门控）
    static func isPlausible(_ code: Int, temperatureC: Double?) -> Bool {
        if frozenCodes.contains(code), let t = temperatureC, t > frozenMaxTempC { return false }
        return true
    }

    /// 判断坐标是否位于中国范围内（粗略矩形，用于选择 CMA 交叉验证模型）
    static func isInChina(latitude: Double, longitude: Double) -> Bool {
        (18.0...54.0).contains(latitude) && (73.0...135.0).contains(longitude)
    }
}
