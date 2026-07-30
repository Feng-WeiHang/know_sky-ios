import SwiftUI

// MARK: - 当前天气卡片（对应 Android WeatherCard）

struct WeatherCardView: View {
    let current: CurrentWeather?
    let cityName: String
    let tempUnit: TemperatureUnit
    let windUnit: WindSpeedUnit
    let strings: Strings
    let language: AppLanguage

    var body: some View {
        Group {
            if let current {
                content(current)
            } else {
                // 空态
                Text(strings.noWeatherData)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func content(_ current: CurrentWeather) -> some View {
        let weatherDesc = I18n.weatherDesc(current.weatherCode, language)

        return VStack(alignment: .leading, spacing: 0) {
            // 城市名 + 天气图标（SF Symbols 多色渲染）
            HStack(spacing: 12) {
                Image(systemName: WeatherSymbols.symbol(for: current.weatherCode))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 2) {
                    Text(cityName)
                        .font(.headline)
                    Text(weatherDesc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Spacer().frame(height: 16)

            // 温度 + 体感
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(FormatUtils.formatTemp(current.temperature, tempUnit))
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .contentTransition(.numericText())
                Text("\(strings.feelsLike) \(FormatUtils.formatTemp(current.apparentTemperature, tempUnit))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }

            Spacer().frame(height: 12)
            Divider()
            Spacer().frame(height: 12)

            // 详细信息网格：风力 / 湿度 / 气压 / 能见度
            HStack {
                DetailItemView(icon: "wind", label: strings.wind,
                               value: "\(I18n.windLabel(current.windDirection, language)) \(FormatUtils.formatWindSpeed(current.windSpeed, windUnit))")
                Spacer()
                DetailItemView(icon: "drop.fill", label: strings.humidity,
                               value: FormatUtils.formatHumidity(current.humidity))
                Spacer()
                DetailItemView(icon: "gauge.with.dots.needle.bottom.50percent", label: strings.pressure,
                               value: FormatUtils.formatPressure(current.pressure))
                Spacer()
                DetailItemView(icon: "eye.fill", label: strings.visibility,
                               value: FormatUtils.formatVisibility(current.visibility))
            }
        }
        .padding(20)
    }
}

/// 详情项（图标 + 标签 + 值）
private struct DetailItemView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.tint)
                .opacity(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - AQI 空气质量指示条（对应 Android AqiBar）

struct AqiBarView: View {
    let airQuality: AirQualityCurrent?
    let strings: Strings

    var body: some View {
        if let aqiValue = airQuality?.aqi {
            let aqi = Int(aqiValue)
            let level = AqiLevel.from(aqi: aqi)
            let aqiColor = Color.aqiColor(level)

            VStack(spacing: 12) {
                HStack {
                    Text(strings.airQuality)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("AQI \(aqi)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(aqiColor)
                    Text(strings.aqiLevels.indices.contains(level.rawValue) ? strings.aqiLevels[level.rawValue] : "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(aqiColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(aqiColor.opacity(0.15), in: Capsule())
                }

                // 趣味建议文案
                if strings.aqiAdvices.indices.contains(level.rawValue) {
                    Text(strings.aqiAdvices[level.rawValue])
                        .font(.caption)
                        .foregroundStyle(aqiColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // AQI 渐变条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(aqiColor.opacity(0.2))
                        Capsule()
                            .fill(aqiColor)
                            .frame(width: geo.size.width * min(max(Double(aqi) / 300.0, 0), 1))
                    }
                }
                .frame(height: 8)

                // PM 值
                HStack {
                    Text("PM2.5: \(airQuality?.pm25.map { String(format: "%.1f", $0) } ?? "--") μg/m³")
                    Spacer()
                    Text("PM10: \(airQuality?.pm10.map { String(format: "%.1f", $0) } ?? "--") μg/m³")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }
}

// MARK: - 紫外线强度指示条（对应 Android UvBar，仿 AQI 条，无 PM 行）

struct UvBarView: View {
    let airQuality: AirQualityCurrent?
    let strings: Strings

    var body: some View {
        if let uviValue = airQuality?.uvIndex {
            let uvi = Int(uviValue.rounded())
            let level = UvLevel.from(uvi: uvi)
            let uvColor = Color.uvColor(level)

            VStack(spacing: 12) {
                HStack {
                    Text(strings.uvIndex)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("UVI \(uvi)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(uvColor)
                    Text(strings.uvLevels.indices.contains(level.rawValue) ? strings.uvLevels[level.rawValue] : "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(uvColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(uvColor.opacity(0.15), in: Capsule())
                }

                // 趣味建议文案
                if strings.uvAdvices.indices.contains(level.rawValue) {
                    Text(strings.uvAdvices[level.rawValue])
                        .font(.caption)
                        .foregroundStyle(uvColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // UVI 渐变条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(uvColor.opacity(0.2))
                        Capsule()
                            .fill(uvColor)
                            .frame(width: geo.size.width * min(max(Double(uvi) / 11.0, 0), 1))
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }
}

// MARK: - 5日预报卡片（对应 Android ForecastCard，行可点击展开详情）

struct ForecastCardView: View {
    let forecasts: [DayForecast]
    let tempUnit: TemperatureUnit
    let strings: Strings
    let language: AppLanguage

    @State private var expandedDay: String?

    var body: some View {
        let days = Array(forecasts.prefix(6))
        let globalMin = forecasts.map(\.tempMin).min() ?? 0
        let globalMax = forecasts.map(\.tempMax).max() ?? 1

        VStack(alignment: .leading, spacing: 0) {
            Text(strings.forecast5Day)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                let isExpanded = expandedDay == day.date
                let dayLabel = FormatUtils.isToday(day.date)
                    ? strings.today
                    : I18n.dayOfWeek(FormatUtils.weekdayIndex(day.date), language)

                // 预报行
                Button {
                    withAnimation(.snappy) {
                        expandedDay = isExpanded ? nil : day.date
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(dayLabel)
                            .font(.subheadline)
                            .frame(width: 44, alignment: .leading)
                        Image(systemName: WeatherSymbols.symbol(for: day.weatherCode))
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 18))
                            .frame(width: 26)
                        Text(I18n.weatherDesc(day.weatherCode, language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(width: 56, alignment: .leading)
                        TemperatureBarView(minTemp: day.tempMin, maxTemp: day.tempMax,
                                           globalMin: globalMin, globalMax: globalMax,
                                           tempUnit: tempUnit)
                        if day.precipitationProbability > 0 {
                            Text("\(day.precipitationProbability)%")
                                .font(.caption2)
                                .foregroundStyle(.tint)
                                .opacity(0.8)
                        }
                    }
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // 展开详情
                if isExpanded {
                    DayDetailView(day: day, tempUnit: tempUnit, language: language)
                        .padding(.vertical, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if index < days.count - 1 {
                    Divider().opacity(0.5)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

/// 温度范围条（对应 Android TemperatureBar）
private struct TemperatureBarView: View {
    let minTemp: Double
    let maxTemp: Double
    let globalMin: Double
    let globalMax: Double
    let tempUnit: TemperatureUnit

    var body: some View {
        let range = max(globalMax - globalMin, 1)
        let startFraction = min(max((minTemp - globalMin) / range, 0), 1)
        let endFraction = min(max((maxTemp - globalMin) / range, 0), 1)

        HStack(spacing: 6) {
            Text(FormatUtils.formatTemp(minTemp, tempUnit))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(LinearGradient(colors: [.cyan, .orange],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * (endFraction - startFraction))
                        .offset(x: geo.size.width * startFraction)
                }
            }
            .frame(height: 5)

            Text(FormatUtils.formatTemp(maxTemp, tempUnit))
                .font(.caption)
                .frame(width: 34, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 日期展开详情卡片（对应 Android DetailCard）
private struct DayDetailView: View {
    let day: DayForecast
    let tempUnit: TemperatureUnit
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: WeatherSymbols.symbol(for: day.weatherCode))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(FormatUtils.dateLabel(day.date, language)) \(I18n.dayOfWeek(FormatUtils.weekdayIndex(day.date), language))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(I18n.weatherDesc(day.weatherCode, language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack {
                DetailColumnView(icon: "thermometer.high", label: "最高温度",
                                 value: FormatUtils.formatTemp(day.tempMax, tempUnit))
                Spacer()
                DetailColumnView(icon: "thermometer.low", label: "最低温度",
                                 value: FormatUtils.formatTemp(day.tempMin, tempUnit))
                Spacer()
                DetailColumnView(icon: "umbrella.fill", label: "降水量",
                                 value: String(format: "%.1f mm", day.precipitationSum))
                Spacer()
                DetailColumnView(icon: "drop.fill", label: "降水概率",
                                 value: "\(day.precipitationProbability)%")
            }
        }
        .padding(16)
        .background(Color.accentColor.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DetailColumnView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.tint)
                .opacity(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
