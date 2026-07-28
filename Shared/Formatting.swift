import Foundation
import SwiftUI

// MARK: - 格式化工具（对应 Android FormatUtils）

enum FormatUtils {

    /// 格式化温度（按单位换算取整）
    static func formatTemp(_ celsius: Double, _ unit: TemperatureUnit) -> String {
        "\(Int(unit.convert(celsius).rounded()))\(unit.symbol)"
    }

    /// 温度数值（不带单位符号，用于 "28°" 风格）
    static func tempValue(_ celsius: Double, _ unit: TemperatureUnit) -> String {
        "\(Int(unit.convert(celsius).rounded()))°"
    }

    /// 格式化风速
    static func formatWindSpeed(_ kmh: Double, _ unit: WindSpeedUnit) -> String {
        String(format: "%.1f %@", unit.convert(kmh), unit.symbol)
    }

    /// 格式化可见距离
    static func formatVisibility(_ meters: Double?) -> String {
        guard let m = meters else { return "--" }
        return m >= 1000 ? String(format: "%.1f km", m / 1000) : "\(Int(m)) m"
    }

    /// 格式化气压
    static func formatPressure(_ hpa: Double?) -> String {
        guard let p = hpa else { return "--" }
        return "\(Int(p)) hPa"
    }

    /// 格式化湿度
    static func formatHumidity(_ humidity: Int?) -> String {
        guard let h = humidity else { return "--" }
        return "\(h)%"
    }

    /// ISO 时间 -> HH:mm（"2024-01-15T14:00" -> "14:00"）
    static func formatIsoTime(_ isoTime: String) -> String {
        isoTime.contains("T") ? String(isoTime.split(separator: "T").last!.prefix(5)) : isoTime
    }

    /// 解析 yyyy-MM-dd
    static func parseDate(_ dateStr: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.date(from: dateStr)
    }

    /// 是否今天
    static func isToday(_ dateStr: String) -> Bool {
        guard let d = parseDate(dateStr) else { return false }
        return Calendar.current.isDateInToday(d)
    }

    /// yyyy-MM-dd -> 星期下标（0=周日）
    static func weekdayIndex(_ dateStr: String) -> Int {
        guard let d = parseDate(dateStr) else { return 0 }
        return Calendar.current.component(.weekday, from: d) - 1
    }

    /// yyyy-MM-dd -> 本地化"月/日"
    static func dateLabel(_ dateStr: String, _ language: AppLanguage) -> String {
        guard let d = parseDate(dateStr) else { return dateStr }
        let comps = Calendar.current.dateComponents([.month, .day], from: d)
        return I18n.dateLabel(month: comps.month ?? 1, day: comps.day ?? 1, language: language)
    }
}

// MARK: - WMO 天气代码 -> SF Symbols 图标（对应 Android WeatherCodeMapper）

enum WeatherSymbols {

    /// 天气图标（SF Symbols，比 Android Material Icons 更细腻，支持多色渲染）
    static func symbol(for code: Int?) -> String {
        switch code ?? -1 {
        case 0: return "sun.max.fill"
        case 1: return "sun.min.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 56, 57, 66, 67: return "cloud.sleet.fill"
        case 61, 63: return "cloud.rain.fill"
        case 65: return "cloud.heavyrain.fill"
        case 71, 73, 75, 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.sun.rain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95: return "cloud.bolt.fill"
        case 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle"
        }
    }

    /// 夜间图标变体（动态背景用）
    static func nightSymbol(for code: Int?) -> String {
        switch code ?? -1 {
        case 0, 1: return "moon.stars.fill"
        case 2: return "cloud.moon.fill"
        case 80, 81, 82: return "cloud.moon.rain.fill"
        default: return symbol(for: code)
        }
    }
}

// MARK: - 小组件主题（对应 Android WidgetTheme）

/// 小组件主题样式
struct WidgetStyle {
    let gradient: [Color]        // 底板渐变
    let isDark: Bool             // 深色底 -> 白字
    let strokeColor: Color       // 描边

    var primaryText: Color { isDark ? .white : Color(hex: 0xFF2B2B2B) }
    var secondaryText: Color { isDark ? .white.opacity(0.85) : Color(hex: 0xFF5A5A5A) }
    var tertiaryText: Color { isDark ? .white.opacity(0.65) : Color(hex: 0xFF8A8A8A) }
    var divider: Color { isDark ? .white.opacity(0.25) : Color(hex: 0x33888888) }
}

enum WidgetTheme {

    /// 解析主题：0=动态（随天气/昼夜），1~5=固定配色（浅白/深空/晴空蓝/青碧绿/暮霭紫）
    static func resolve(themeIndex: Int, weatherCode: Int?, date: Date = Date()) -> WidgetStyle {
        switch themeIndex {
        case 1: // 浅白
            return WidgetStyle(gradient: [Color(hex: 0xFFFFFFFF), Color(hex: 0xFFF2F2F7)], isDark: false, strokeColor: Color(hex: 0x22000000))
        case 2: // 深空
            return WidgetStyle(gradient: [Color(hex: 0xFF2C2C40), Color(hex: 0xFF17171F)], isDark: true, strokeColor: Color(hex: 0x33FFFFFF))
        case 3: // 晴空蓝
            return WidgetStyle(gradient: [Color(hex: 0xFF4A90D9), Color(hex: 0xFF2B5EA7)], isDark: true, strokeColor: Color(hex: 0x40FFFFFF))
        case 4: // 青碧绿
            return WidgetStyle(gradient: [Color(hex: 0xFF34A08C), Color(hex: 0xFF1E6E5C)], isDark: true, strokeColor: Color(hex: 0x40FFFFFF))
        case 5: // 暮霭紫
            return WidgetStyle(gradient: [Color(hex: 0xFF7B5EA7), Color(hex: 0xFF4A3670)], isDark: true, strokeColor: Color(hex: 0x40FFFFFF))
        default:
            return dynamicStyle(weatherCode: weatherCode, date: date)
        }
    }

    /// 动态主题：按天气代码与昼夜切换
    static func dynamicStyle(weatherCode: Int?, date: Date = Date()) -> WidgetStyle {
        let hour = Calendar.current.component(.hour, from: date)
        let isNight = hour < 6 || hour >= 19
        if isNight {
            return WidgetStyle(gradient: [Color(hex: 0xFF2B3A67), Color(hex: 0xFF141B33)], isDark: true, strokeColor: Color(hex: 0x33FFFFFF))
        }
        switch weatherCode ?? 0 {
        case 0, 1: // 晴
            return WidgetStyle(gradient: [Color(hex: 0xFF64B5F6), Color(hex: 0xFF2286D4)], isDark: true, strokeColor: Color(hex: 0x40FFFFFF))
        case 2, 3, 45, 48: // 多云/雾
            return WidgetStyle(gradient: [Color(hex: 0xFF90A4AE), Color(hex: 0xFF546E7A)], isDark: true, strokeColor: Color(hex: 0x40FFFFFF))
        case 51...67, 80...82: // 雨
            return WidgetStyle(gradient: [Color(hex: 0xFF546E8C), Color(hex: 0xFF2F4156)], isDark: true, strokeColor: Color(hex: 0x33FFFFFF))
        case 71...77, 85, 86: // 雪
            return WidgetStyle(gradient: [Color(hex: 0xFFB3CDE0), Color(hex: 0xFF7C9CB8)], isDark: false, strokeColor: Color(hex: 0x33FFFFFF))
        case 95, 96, 99: // 雷暴
            return WidgetStyle(gradient: [Color(hex: 0xFF4A3670), Color(hex: 0xFF241A3D)], isDark: true, strokeColor: Color(hex: 0x33FFFFFF))
        default:
            return WidgetStyle(gradient: [Color(hex: 0xFF64B5F6), Color(hex: 0xFF2286D4)], isDark: true, strokeColor: Color(hex: 0x40FFFFFF))
        }
    }
}

// MARK: - Color 便捷扩展

extension Color {
    /// 从 0xAARRGGBB 构造
    init(hex: UInt32) {
        let a = Double((hex >> 24) & 0xFF) / 255.0
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
    }

    /// AQI 等级颜色
    static func aqiColor(_ level: AqiLevel) -> Color { Color(hex: level.colorHex) }

    /// 预警等级颜色
    static func severityColor(_ s: AlertSeverity) -> Color { Color(hex: s.colorHex) }
}
