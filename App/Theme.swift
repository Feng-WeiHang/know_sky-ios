import SwiftUI

/// 主题色板（对应 Android ui/theme/Color.kt 的 8 组预设主题）
struct ThemePalette {
    let name: String
    let surface: Color
    let primary: Color
}

enum AppTheme {

    /// 预设主题色板（下标与 Android themeColors 一致）
    static let palettes: [ThemePalette] = [
        ThemePalette(name: "奶油白", surface: Color(hex: 0xFFFFF8F0), primary: Color(hex: 0xFF3D3D3D)),
        ThemePalette(name: "天空蓝", surface: Color(hex: 0xFFE3F2FD), primary: Color(hex: 0xFF1565C0)),
        ThemePalette(name: "薄荷绿", surface: Color(hex: 0xFFE8F5E9), primary: Color(hex: 0xFF2E7D32)),
        ThemePalette(name: "樱花粉", surface: Color(hex: 0xFFFCE4EC), primary: Color(hex: 0xFFC62828)),
        ThemePalette(name: "薰衣草紫", surface: Color(hex: 0xFFF3E5F5), primary: Color(hex: 0xFF6A1B9A)),
        ThemePalette(name: "暖阳橙", surface: Color(hex: 0xFFFFF3E0), primary: Color(hex: 0xFFE65100)),
        ThemePalette(name: "深海蓝", surface: Color(hex: 0xFFE0F7FA), primary: Color(hex: 0xFF00695C)),
        ThemePalette(name: "石墨灰", surface: Color(hex: 0xFFECEFF1), primary: Color(hex: 0xFF37474F))
    ]

    static func palette(_ index: Int) -> ThemePalette {
        palettes.indices.contains(index) ? palettes[index] : palettes[0]
    }

    // 深色模式颜色
    static let darkSurface = Color(hex: 0xFF1E1E2E)
    static let darkSurfaceVariant = Color(hex: 0xFF2A2A3C)
    static let darkOnSurface = Color(hex: 0xFFE0E0E0)
    static let darkPrimary = Color(hex: 0xFF82B1FF)

    /// 卡片背景（跟随深浅色模式与主题色）
    static func cardBackground(_ colorScheme: ColorScheme, paletteIndex: Int) -> Color {
        colorScheme == .dark ? darkSurfaceVariant : Color.white.opacity(0.72)
    }

    /// 页面背景（跟随深浅色模式与主题色）
    static func pageBackground(_ colorScheme: ColorScheme, paletteIndex: Int) -> Color {
        colorScheme == .dark ? darkSurface : palette(paletteIndex).surface
    }
}

/// 动态天气背景渐变（对应 Android DynamicWeatherBackground）
enum DynamicBackground {

    /// 按天气代码与昼夜返回全屏背景渐变
    static func gradient(weatherCode: Int?, colorScheme: ColorScheme, date: Date = Date()) -> LinearGradient {
        let hour = Calendar.current.component(.hour, from: date)
        let isNight = hour < 6 || hour >= 19
        let colors: [Color]

        if colorScheme == .dark || isNight {
            switch weatherCode ?? 0 {
            case 51...67, 80...82: colors = [Color(hex: 0xFF1B2735), Color(hex: 0xFF090A0F)]
            case 95, 96, 99: colors = [Color(hex: 0xFF2C1B47), Color(hex: 0xFF0D0716)]
            default: colors = [Color(hex: 0xFF1F2A44), Color(hex: 0xFF0E1526)]
            }
        } else {
            switch weatherCode ?? 0 {
            case 0, 1: colors = [Color(hex: 0xFF87CEEB), Color(hex: 0xFFE0F2FF)]           // 晴
            case 2, 3: colors = [Color(hex: 0xFFB0C4D8), Color(hex: 0xFFE8EEF4)]           // 多云
            case 45, 48: colors = [Color(hex: 0xFFC5CCD4), Color(hex: 0xFFECEFF2)]         // 雾
            case 51...67, 80...82: colors = [Color(hex: 0xFF7E9BB5), Color(hex: 0xFFD3DEE8)] // 雨
            case 71...77, 85, 86: colors = [Color(hex: 0xFFD5E2EC), Color(hex: 0xFFF6FAFD)]  // 雪
            case 95, 96, 99: colors = [Color(hex: 0xFF6B5B95), Color(hex: 0xFFC0B6D9)]      // 雷暴
            default: colors = [Color(hex: 0xFF87CEEB), Color(hex: 0xFFE0F2FF)]
            }
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}
