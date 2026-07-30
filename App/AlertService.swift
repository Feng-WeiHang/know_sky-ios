import Foundation
import UserNotifications

/// 恶劣天气预警服务：分析逐小时数据并推送本地通知
/// 对应 Android AlertCheckWorker + AlertNotificationHelper
final class AlertService {

    static let shared = AlertService()
    private let store = AppStore.shared

    /// 遍历所有城市，检测未来 1-6 小时是否出现极端天气
    func checkAllCities() async {
        let settings = store.getSettings()
        guard settings.alertEnabled else { return }

        let cities = store.getCities()
        guard !cities.isEmpty else { return }

        store.cleanExpiredAlertKeys()
        let recentKeys = store.getRecentAlertKeys()
        let language = settings.language

        for city in cities {
            guard let forecast = try? await WeatherAPI.getForecast(
                latitude: city.latitude, longitude: city.longitude,
                hourly: "precipitation,weather_code,wind_speed_10m,visibility,temperature_2m,precipitation_probability,cape,freezing_level_height"
            ), let hourly = forecast.hourly else { continue }

            // 中国城市额外拉取中国气象局 CMA GRAPES 模型数据，对天气码类预警做交叉验证
            var cmaHourly: HourlyWeather? = nil
            if ClimatePlausibility.isInChina(latitude: city.latitude, longitude: city.longitude) {
                cmaHourly = try? await WeatherAPI.getForecast(
                    latitude: city.latitude, longitude: city.longitude,
                    hourly: "weather_code,temperature_2m",
                    models: "cma_grapes_global"
                ).hourly
            }

            var alerts = analyzeHourlyData(city: city, hourly: hourly, cmaHourly: cmaHourly, settings: settings)

            // 逐小时空气质量/紫外线预警（数据获取失败静默，不阻断天气类预警）
            let airHourly = try? await WeatherAPI.getAirQuality(
                latitude: city.latitude, longitude: city.longitude,
                hourly: "us_aqi,uv_index"
            ).hourly
            alerts += analyzeAirHourlyData(city: city, airHourly: airHourly ?? nil, settings: settings)

            for alert in alerts {
                // 去重：同一城市同一类型 2 小时内不重复推送
                let key = "\(alert.cityId)_\(alert.alertType.rawValue)"
                guard !recentKeys.contains(key) else { continue }
                await sendNotification(alert, language: language)
                store.addAlertKey(key)
            }
        }
    }

    // MARK: - 逐小时数据分析（阈值与 Android 完全一致）

    func analyzeHourlyData(city: CityInfo, hourly: HourlyWeather, cmaHourly: HourlyWeather? = nil, settings: AppSettings) -> [WeatherAlert] {
        var alerts: [WeatherAlert] = []
        let minSeverity = settings.alertMinSeverity
        let now = Date()

        // 找到当前小时对应的索引
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        var startIndex = -1
        for (i, t) in hourly.time.enumerated() {
            if let time = fmt.date(from: t), time >= now { startIndex = i; break }
        }
        guard startIndex >= 0 else { return [] }

        // 检查未来 6 小时
        let endIndex = min(startIndex + 6, hourly.time.count - 1)

        for i in startIndex...endIndex {
            let hoursAhead = i - startIndex + 1
            let timeStr = FormatUtils.formatIsoTime(hourly.time[i])

            // 1. 风速
            let windSpeed = hourly.windSpeed?.indices.contains(i) == true ? hourly.windSpeed![i] : 0.0
            if let a = checkWind(city, windSpeed, hoursAhead, timeStr, minSeverity) { alerts.append(a) }

            // 2. 降水量
            let precipitation = hourly.precipitation?.indices.contains(i) == true ? hourly.precipitation![i] : 0.0
            if let a = checkRain(city, precipitation, hoursAhead, timeStr, minSeverity) { alerts.append(a) }

            // 3. 能见度
            if let vis = hourly.visibility?.indices.contains(i) == true ? hourly.visibility![i] : nil,
               let a = checkFog(city, vis, hoursAhead, timeStr, minSeverity) { alerts.append(a) }

            // 4. WMO 天气代码（含气候合理性门控与 CMA 交叉验证）
            if let a = checkWeatherCode(city, hourly: hourly, cmaHourly: cmaHourly, index: i, hoursAhead: hoursAhead, timeStr: timeStr, settings: settings) { alerts.append(a) }
        }

        // 每种类型只保留最早的一个
        var seen = Set<AlertType>()
        return alerts.filter { seen.insert($0.alertType).inserted }
    }

    // MARK: - 逐小时空气质量/紫外线分析（阈值与 Android 完全一致）

    func analyzeAirHourlyData(city: CityInfo, airHourly: AirQualityHourly?, settings: AppSettings) -> [WeatherAlert] {
        guard let airHourly else { return [] }
        var alerts: [WeatherAlert] = []
        let minSeverity = settings.alertMinSeverity
        let strings = I18n.of(settings.language)
        let now = Date()

        // 找到当前小时对应的索引
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        var startIndex = -1
        for (i, t) in airHourly.time.enumerated() {
            if let time = fmt.date(from: t), time >= now { startIndex = i; break }
        }
        guard startIndex >= 0 else { return [] }

        // 检查未来 6 小时
        let endIndex = min(startIndex + 6, airHourly.time.count - 1)

        for i in startIndex...endIndex {
            let hoursAhead = i - startIndex + 1
            let timeStr = FormatUtils.formatIsoTime(airHourly.time[i])

            // 1. 空气质量指数（>120 普通 / >160 严重 / >210 紧急）
            if let v = airHourly.aqi?.indices.contains(i) == true ? airHourly.aqi![i] : nil,
               let a = checkAqi(city, Int(v), hoursAhead, timeStr, minSeverity, strings) { alerts.append(a) }

            // 2. 紫外线指数（3-4 普通 / 5-6 严重 / >6 紧急）
            if let v = airHourly.uvIndex?.indices.contains(i) == true ? airHourly.uvIndex![i] : nil,
               let a = checkUv(city, Int(v.rounded()), hoursAhead, timeStr, minSeverity, strings) { alerts.append(a) }
        }

        // 每种类型只保留最早的一个
        var seen = Set<AlertType>()
        return alerts.filter { seen.insert($0.alertType).inserted }
    }

    private func checkAqi(_ city: CityInfo, _ aqi: Int, _ hoursAhead: Int, _ timeStr: String, _ minSeverity: AlertSeverity, _ strings: Strings) -> WeatherAlert? {
        let severity: AlertSeverity
        if aqi > AlertThresholds.aqiExtreme { severity = .extreme }
        else if aqi > AlertThresholds.aqiSevere { severity = .severe }
        else if aqi > AlertThresholds.aqiWarning { severity = .warning }
        else { return nil }
        guard severity.priority >= minSeverity.priority else { return nil }

        let level = AqiLevel.from(aqi: aqi)
        let levelName = strings.aqiLevels.indices.contains(level.rawValue) ? strings.aqiLevels[level.rawValue] : ""
        return WeatherAlert(
            cityId: city.id, cityName: city.name, alertType: .airPollution, severity: severity,
            message: "预计\(hoursAhead)小时后空气质量指数升至 \(aqi)（\(levelName)），请减少外出并佩戴口罩",
            detail: "AQI：\(aqi)（\(levelName)）", detectedAt: Date(), expectedTime: timeStr
        )
    }

    private func checkUv(_ city: CityInfo, _ uvi: Int, _ hoursAhead: Int, _ timeStr: String, _ minSeverity: AlertSeverity, _ strings: Strings) -> WeatherAlert? {
        let severity: AlertSeverity
        if uvi >= AlertThresholds.uviExtreme { severity = .extreme }
        else if uvi >= AlertThresholds.uviSevere { severity = .severe }
        else if uvi >= AlertThresholds.uviWarning { severity = .warning }
        else { return nil }
        guard severity.priority >= minSeverity.priority else { return nil }

        let level = UvLevel.from(uvi: uvi)
        let levelName = strings.uvLevels.indices.contains(level.rawValue) ? strings.uvLevels[level.rawValue] : ""
        return WeatherAlert(
            cityId: city.id, cityName: city.name, alertType: .highUv, severity: severity,
            message: "预计\(hoursAhead)小时后紫外线指数达 \(uvi)（\(levelName)），外出请做好防晒",
            detail: "UVI：\(uvi)（\(levelName)）", detectedAt: Date(), expectedTime: timeStr
        )
    }

    private func checkWind(_ city: CityInfo, _ windSpeed: Double, _ hoursAhead: Int, _ timeStr: String, _ minSeverity: AlertSeverity) -> WeatherAlert? {
        let severity: AlertSeverity
        switch windSpeed {
        case AlertThresholds.windExtreme...: severity = .extreme
        case AlertThresholds.windSevere...: severity = .severe
        case AlertThresholds.windWarning...: severity = .warning
        default: return nil
        }
        guard severity.priority >= minSeverity.priority else { return nil }
        return WeatherAlert(
            cityId: city.id, cityName: city.name, alertType: .strongWind, severity: severity,
            message: "预计\(hoursAhead)小时后出现强风天气，风力 \(Int(windSpeed)) km/h",
            detail: "风力：\(Int(windSpeed)) km/h", detectedAt: Date(), expectedTime: timeStr
        )
    }

    private func checkRain(_ city: CityInfo, _ precipitation: Double, _ hoursAhead: Int, _ timeStr: String, _ minSeverity: AlertSeverity) -> WeatherAlert? {
        let severity: AlertSeverity
        switch precipitation {
        case AlertThresholds.rainExtreme...: severity = .extreme
        case AlertThresholds.rainSevere...: severity = .severe
        case AlertThresholds.rainWarning...: severity = .warning
        default: return nil
        }
        guard severity.priority >= minSeverity.priority else { return nil }
        return WeatherAlert(
            cityId: city.id, cityName: city.name, alertType: .heavyRain, severity: severity,
            message: String(format: "预计%d小时后出现暴雨天气，降水量 %.1f mm/h", hoursAhead, precipitation),
            detail: String(format: "降水量：%.1f mm/h", precipitation), detectedAt: Date(), expectedTime: timeStr
        )
    }

    private func checkFog(_ city: CityInfo, _ visibility: Double, _ hoursAhead: Int, _ timeStr: String, _ minSeverity: AlertSeverity) -> WeatherAlert? {
        let severity: AlertSeverity
        if visibility < AlertThresholds.visibilityWarning { severity = .severe }
        else if visibility < AlertThresholds.visibilitySevere { severity = .warning }
        else { return nil }
        guard severity.priority >= minSeverity.priority else { return nil }
        return WeatherAlert(
            cityId: city.id, cityName: city.name, alertType: .fog, severity: severity,
            message: "预计\(hoursAhead)小时后能见度极低（\(Int(visibility)) m），可能为沙尘暴或浓雾",
            detail: "能见度：\(Int(visibility)) m", detectedAt: Date(), expectedTime: timeStr
        )
    }

    private func checkWeatherCode(_ city: CityInfo, hourly: HourlyWeather, cmaHourly: HourlyWeather?, index: Int, hoursAhead: Int, timeStr: String, settings: AppSettings) -> WeatherAlert? {
        guard let rawCode = hourly.weatherCode?.indices.contains(index) == true ? hourly.weatherCode![index] : nil else { return nil }

        // 冰雹码（96/99）科学化判定：非中欧地区不再一刀切降级，而是用
        // CAPE（对流能量）+ 冻结高度的物理条件判定（寒冬冷涡冰雹同样满足），
        // 中国城市另叠加 CMA 同小时确认（CMA 有值但 <95 则降级为纯雷暴）
        var code = rawCode
        if (rawCode == 96 || rawCode == 99),
           !ClimatePlausibility.isCentralEurope(latitude: city.latitude, longitude: city.longitude) {
            let cape = hourly.cape?.indices.contains(index) == true ? hourly.cape![index] : nil
            let flh = hourly.freezingLevelHeight?.indices.contains(index) == true ? hourly.freezingLevelHeight![index] : nil
            let cmaCode = cmaCodeAt(cmaHourly, time: hourly.time.indices.contains(index) ? hourly.time[index] : nil)
            let physicsOk = ClimatePlausibility.isHailPlausible(cape: cape, freezingLevelHeight: flh)
            let cmaOk = cmaCode == nil || cmaCode! >= 95
            if !(physicsOk && cmaOk) { code = 95 }
        }
        guard AlertThresholds.severeWeatherCodes.contains(code) else { return nil }

        guard let (alertType, severity) = AlertThresholds.codeAlertSpec(code) else { return nil }
        guard severity.priority >= settings.alertMinSeverity.priority else { return nil }

        // 温度门控：气温明显高于冰点时剔除冻雨/降雪类误报
        let temperature = hourly.temperature?.indices.contains(index) == true ? hourly.temperature![index] : nil
        guard ClimatePlausibility.isPlausible(code, temperatureC: temperature) else { return nil }

        // 概率门控：降水概率过低视为模型噪声
        if let probability = hourly.precipitationProbability?.indices.contains(index) == true ? hourly.precipitationProbability![index] : nil,
           probability < ClimatePlausibility.minPrecipProbability { return nil }

        // CMA 中国气象局模型交叉验证：两个模型都预报降水类天气才告警
        if let cmaHourly, !crossValidateWithCma(cmaHourly, time: hourly.time.indices.contains(index) ? hourly.time[index] : nil) { return nil }

        // 描述改用 I18n 精确文案（95=雷暴、96=雷暴+小冰雹、99=雷暴+大冰雹），随设置语言
        let desc = I18n.weatherDesc(code, settings.language)

        return WeatherAlert(
            cityId: city.id, cityName: city.name, alertType: alertType, severity: severity,
            message: "预计\(hoursAhead)小时后出现\(desc)天气，请注意防范",
            detail: "天气类型：\(desc)", detectedAt: Date(), expectedTime: timeStr
        )
    }

    /// 用 CMA GRAPES 模型交叉验证：同一时刻 CMA 也预报降水类天气（code >= 51）才确认
    /// 时间对不齐或 CMA 无数据时不阻断（退回单模型 + 门控）
    private func crossValidateWithCma(_ cmaHourly: HourlyWeather, time: String?) -> Bool {
        guard let time, let idx = cmaHourly.time.firstIndex(of: time),
              let cmaCode = cmaHourly.weatherCode?.indices.contains(idx) == true ? cmaHourly.weatherCode![idx] : nil
        else { return true }
        return cmaCode >= 51
    }

    /// 取 CMA 模型同一时刻的天气码（用于冰雹确认）；CMA 无数据或时间对不齐返回 nil
    private func cmaCodeAt(_ cmaHourly: HourlyWeather?, time: String?) -> Int? {
        guard let cmaHourly, let time, let idx = cmaHourly.time.firstIndex(of: time) else { return nil }
        return cmaHourly.weatherCode?.indices.contains(idx) == true ? cmaHourly.weatherCode![idx] : nil
    }

    // MARK: - 本地通知

    private func sendNotification(_ alert: WeatherAlert, language: AppLanguage) async {
        let strings = I18n.of(language)
        let severityName = strings.severityNames[alert.severity.priority]

        let content = UNMutableNotificationContent()
        content.title = "⚠️ \(alert.cityName) · \(severityName)"
        content.body = "\(alert.message)（\(alert.expectedTime)）"
        content.sound = alert.severity == .extreme ? .defaultCritical : .default
        content.interruptionLevel = alert.severity == .extreme ? .timeSensitive : .active

        let request = UNNotificationRequest(
            identifier: "alert_\(alert.cityId)_\(alert.alertType.rawValue)_\(Int(alert.detectedAt.timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
