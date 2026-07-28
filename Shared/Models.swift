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
            geoId: id
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

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case visibility
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

    enum CodingKeys: String, CodingKey {
        case time
        case aqi = "european_aqi"
        case pm10
        case pm25 = "pm2_5"
    }
}

/// AQI 等级（European AQI）
enum AqiLevel: Int, CaseIterable {
    case good = 0, fair, moderate, poor, veryPoor, extremelyPoor

    var colorHex: UInt32 {
        switch self {
        case .good: return 0xFF4CAF50
        case .fair: return 0xFFFFC107
        case .moderate: return 0xFFFF9800
        case .poor: return 0xFFF44336
        case .veryPoor: return 0xFF9C27B0
        case .extremelyPoor: return 0xFF7B1FA2
        }
    }

    static func from(aqi: Int) -> AqiLevel {
        switch aqi {
        case 0...20: return .good
        case 21...40: return .fair
        case 41...60: return .moderate
        case 61...80: return .poor
        case 81...100: return .veryPoor
        default: return .extremelyPoor
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

    // 极端天气 WMO 代码
    static let severeWeatherCodes: Set<Int> = [55, 56, 57, 65, 66, 67, 77, 85, 86, 95, 96, 99]
    static let extremeWeatherCodes: Set<Int> = [66, 67, 86, 96, 99]
}
