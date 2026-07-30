import WidgetKit
import SwiftUI

// MARK: - 气象小组件（对应 Android WeatherWidget：精简 / 详细网格 / 5日预报三档）

struct WeatherEntry: TimelineEntry {
    let date: Date
    let settings: AppSettings
    let city: CityInfo?
    let weather: CityWeatherData?
}

struct WeatherProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), settings: AppSettings(), city: nil, weather: nil)
    }

    func snapshot(for configuration: SelectCityIntent, in context: Context) async -> WeatherEntry {
        entryNow(for: configuration)
    }

    func timeline(for configuration: SelectCityIntent, in context: Context) async -> Timeline<WeatherEntry> {
        let settings = AppStore.shared.getSettings()
        var entry = entryNow(for: configuration)

        // 在线拉取最新数据（成功即写缓存；失败回退缓存离线展示）
        if let city = entry.city,
           let fresh = try? await WeatherRepository.shared.fetchCityWeather(city) {
            entry = WeatherEntry(date: Date(), settings: settings, city: city, weather: fresh)
        }

        // 下次刷新跟随设置的自动刷新间隔
        let next = Date(timeIntervalSinceNow: TimeInterval(settings.refreshIntervalMinutes * 60))
        return Timeline(entries: [entry], policy: .after(next))
    }

    /// 用缓存数据构造当前时刻的条目
    private func entryNow(for configuration: SelectCityIntent) -> WeatherEntry {
        let store = AppStore.shared
        let settings = store.getSettings()
        let city = WidgetHelper.resolveCity(configuration)
        let cached = city.flatMap { store.getCachedWeather(cityId: $0.id) }
        return WeatherEntry(date: Date(), settings: settings, city: city, weather: cached)
    }
}

struct WeatherWidgetView: View {
    var entry: WeatherEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let settings = entry.settings
        let strings = I18n.of(settings.language)
        let current = entry.weather?.current
        // 底板：动态（随天气×时段）或用户选择的固定主题色，叠加自定义透明度
        let style = WidgetTheme.resolve(themeIndex: settings.widgetThemeIndex,
                                        weatherCode: current?.weatherCode)

        Group {
            if entry.city == nil {
                Text(strings.noCities)
                    .font(.subheadline)
                    .foregroundStyle(style.primaryText)
            } else if let current {
                switch family {
                case .systemSmall:
                    compactView(current, strings: strings, style: style)
                case .systemMedium:
                    detailView(current, strings: strings, style: style, showForecast: false)
                default:
                    detailView(current, strings: strings, style: style, showForecast: true)
                }
            } else {
                Text(strings.widgetLoading)
                    .font(.subheadline)
                    .foregroundStyle(style.secondaryText)
            }
        }
        .containerBackground(for: .widget) {
            WidgetHelper.background(style: style, opacityPercent: settings.weatherWidgetOpacity)
        }
        .widgetURL(URL(string: "skysense://open"))
    }

    // MARK: 精简档（对应 Android 2×2：城市/温度/图标/描述/体感/AQI）

    private func compactView(_ current: CurrentWeather, strings: Strings, style: WidgetStyle) -> some View {
        let settings = entry.settings
        let language = settings.language

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(entry.city?.nameFor(language) ?? "--")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(style.primaryText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: WeatherSymbols.symbol(for: current.weatherCode))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 18))
            }
            Text(FormatUtils.formatTemp(current.temperature, settings.temperatureUnit))
                .font(.system(size: 34, weight: .light, design: .rounded))
                .foregroundStyle(style.primaryText)
            Text(I18n.weatherDesc(current.weatherCode, language))
                .font(.caption)
                .foregroundStyle(style.secondaryText)
            Text("\(strings.feelsLike) \(FormatUtils.formatTemp(current.apparentTemperature, settings.temperatureUnit))")
                .font(.caption2)
                .foregroundStyle(style.tertiaryText)
            if let aqi = entry.weather?.airQuality?.aqi.map({ Int($0) }) {
                Text("AQI \(aqi)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.aqiColor(AqiLevel.from(aqi: aqi)))
            }
            if let uvi = entry.weather?.airQuality?.uvIndex.map({ Int($0.rounded()) }) {
                Text("UVI \(uvi)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.uvColor(UvLevel.from(uvi: uvi)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: 详细档（对应 Android 4×2 / 4×3：头部 + 数据网格 + 可选预报行）

    private func detailView(_ current: CurrentWeather, strings: Strings, style: WidgetStyle,
                            showForecast: Bool) -> some View {
        let settings = entry.settings
        let language = settings.language
        let tempUnit = settings.temperatureUnit
        let aqi = entry.weather?.airQuality?.aqi.map { Int($0) }
        let uvi = entry.weather?.airQuality?.uvIndex.map { Int($0.rounded()) }
        let daily = entry.weather?.daily

        return VStack(alignment: .leading, spacing: 7) {
            // 头部：城市 + 温度 + 图标/描述
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.city?.nameFor(language) ?? "--")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(style.primaryText)
                    Text(FormatUtils.formatTemp(current.temperature, tempUnit))
                        .font(.system(size: 30, weight: .light, design: .rounded))
                        .foregroundStyle(style.primaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: WeatherSymbols.symbol(for: current.weatherCode))
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 24))
                    Text(I18n.weatherDesc(current.weatherCode, language))
                        .font(.caption)
                        .foregroundStyle(style.secondaryText)
                }
            }

            Rectangle().fill(style.divider).frame(height: 0.6)

            // 详细气象数据网格：体感/风/湿度/能见度 + 气压/紫外线/空气质量/今日高低温
            let columns = Array(repeating: GridItem(.flexible(), alignment: .leading), count: 4)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                gridCell(strings.feelsLike, FormatUtils.formatTemp(current.apparentTemperature, tempUnit), style)
                gridCell("\(strings.wind) \(I18n.windDirection(current.windDirection, language))",
                         FormatUtils.formatWindSpeed(current.windSpeed, settings.windSpeedUnit), style)
                gridCell(strings.humidity, "\(current.humidity)%", style)
                gridCell(strings.visibility,
                         current.visibility.map { String(format: "%.1f km", $0 / 1000) } ?? "--", style)
                gridCell(strings.pressure,
                         current.pressure.map { String(format: "%.0f hPa", $0) } ?? "--", style)
                gridCell(strings.uvIndex,
                         uvi.map { "\($0) \(strings.uvLevels[UvLevel.from(uvi: $0).rawValue])" } ?? "--", style)
                gridCell(strings.airQuality,
                         aqi.map { "\($0) \(strings.aqiLevels[AqiLevel.from(aqi: $0).rawValue])" } ?? "--", style)
                gridCell(strings.today, todayHiLo(daily, tempUnit), style)
            }

            if showForecast {
                Rectangle().fill(style.divider).frame(height: 0.6)

                // 近 5 日天气预报行：星期/今天 + 图标 + 高低温
                HStack {
                    ForEach(0..<5, id: \.self) { i in
                        forecastCell(daily, index: i, strings: strings, language: language,
                                     tempUnit: tempUnit, style: style)
                        if i < 4 { Spacer() }
                    }
                }

                // 数据更新时间戳
                Text("\(strings.widgetUpdatePrefix) \(FormatUtils.formatIsoTime(isoNow()))")
                    .font(.system(size: 9))
                    .foregroundStyle(style.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func gridCell(_ label: String, _ value: String, _ style: WidgetStyle) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(style.tertiaryText)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(style.primaryText)
                .lineLimit(1)
        }
    }

    private func forecastCell(_ daily: DailyWeather?, index: Int, strings: Strings,
                              language: AppLanguage, tempUnit: TemperatureUnit,
                              style: WidgetStyle) -> some View {
        let date = daily?.time.indices.contains(index) == true ? daily!.time[index] : nil
        let label = index == 0 ? strings.today
            : date.map { I18n.dayOfWeek(FormatUtils.weekdayIndex($0), language) } ?? "--"
        let code = daily?.weatherCode.indices.contains(index) == true ? daily!.weatherCode[index] : nil
        let hi = daily?.temperatureMax.indices.contains(index) == true ? daily!.temperatureMax[index] : nil
        let lo = daily?.temperatureMin.indices.contains(index) == true ? daily!.temperatureMin[index] : nil

        return VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(style.tertiaryText)
            Image(systemName: WeatherSymbols.symbol(for: code))
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 13))
            Text(hi != nil && lo != nil
                 ? "\(Int(tempUnit.convert(hi!).rounded()))°/\(Int(tempUnit.convert(lo!).rounded()))°"
                 : "--")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(style.secondaryText)
        }
    }

    private func todayHiLo(_ daily: DailyWeather?, _ tempUnit: TemperatureUnit) -> String {
        guard let hi = daily?.temperatureMax.first, let lo = daily?.temperatureMin.first else { return "--" }
        return "↑\(Int(tempUnit.convert(hi).rounded()))° ↓\(Int(tempUnit.convert(lo).rounded()))°"
    }

    private func isoNow() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return fmt.string(from: entry.date)
    }
}

struct WeatherWidget: Widget {
    let kind = "SkySenseWeatherWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCityIntent.self, provider: WeatherProvider()) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("识天气象")
        .description("实时天气 + 详细数据 + 5日预报（长按可为每个组件单独选择城市）")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
