import WidgetKit
import SwiftUI

// MARK: - 时钟小组件（对应 Android ClockWidget：质感表盘 + 数字时间 + 本地化日期）

struct ClockEntry: TimelineEntry {
    let date: Date
    let settings: AppSettings
}

struct ClockProvider: TimelineProvider {

    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: Date(), settings: AppSettings())
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(ClockEntry(date: Date(), settings: AppStore.shared.getSettings()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let settings = AppStore.shared.getSettings()
        // 每分钟一条时间线（指针走时按分钟推进，数字时间由系统 Text(.time) 实时驱动）
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.nextDate(after: now, matching: DateComponents(second: 0),
                                      matchingPolicy: .nextTime) ?? now
        var entries = [ClockEntry(date: now, settings: settings)]
        for minute in 0..<60 {
            if let date = calendar.date(byAdding: .minute, value: minute, to: start) {
                entries.append(ClockEntry(date: date, settings: settings))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct ClockWidgetView: View {
    var entry: ClockEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        // 底板：主题色（0=动态时保持默认浅白底板）+ 用户自定义透明度
        let themeIndex = entry.settings.widgetThemeIndex
        let style: WidgetStyle = themeIndex > 0
            ? WidgetTheme.resolve(themeIndex: themeIndex, weatherCode: nil)
            : WidgetStyle(gradient: [Color(hex: 0xFFFFFFFF), Color(hex: 0xFFEDF1F7)],
                          isDark: false, strokeColor: Color(hex: 0x22000000))
        let language = entry.settings.language

        Group {
            if family == .systemSmall {
                VStack(spacing: 4) {
                    ClockFaceView(date: entry.date, faceDark: style.isDark)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(8)
            } else {
                HStack(spacing: 14) {
                    ClockFaceView(date: entry.date, faceDark: style.isDark)
                        .aspectRatio(1, contentMode: .fit)

                    VStack(alignment: .leading, spacing: 4) {
                        // 数字时间：系统驱动实时走时
                        Text(entry.date, style: .time)
                            .font(.system(size: 34, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(style.primaryText)
                        Text(localizedDate(entry.date, language))
                            .font(.footnote)
                            .foregroundStyle(style.secondaryText)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
        }
        .containerBackground(for: .widget) {
            WidgetHelper.background(style: style, opacityPercent: entry.settings.clockWidgetOpacity)
        }
    }

    /// 本地化日期（对应 Android 按语言切换日期格式）
    private func localizedDate(_ date: Date, _ language: AppLanguage) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day, .weekday], from: date)
        return I18n.fullDateLabel(
            year: comps.year ?? 2026, month: comps.month ?? 1, day: comps.day ?? 1,
            weekdayIndex: (comps.weekday ?? 1) - 1, language: language)
    }
}

/// 质感表盘（金属渐变边圈 + 立体表面 + 刻度 + 数字 + 时分针）
struct ClockFaceView: View {
    let date: Date
    let faceDark: Bool

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2, cy = size.height / 2
            let center = CGPoint(x: cx, y: cy)
            let radius = min(cx, cy) * 0.94

            // 金属渐变外圈
            let ringWidth = radius * 0.07
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - radius + ringWidth / 2, y: cy - radius + ringWidth / 2,
                                       width: (radius - ringWidth / 2) * 2, height: (radius - ringWidth / 2) * 2)),
                with: .conicGradient(
                    Gradient(colors: [
                        Color(hex: 0xFFE8EDF4), Color(hex: 0xFFB9C4D4), Color(hex: 0xFFF5F8FC),
                        Color(hex: 0xFFA9B6C9), Color(hex: 0xFFE8EDF4)
                    ]),
                    center: center, angle: .zero),
                lineWidth: ringWidth)

            // 表盘面（径向渐变营造立体感）
            let faceRadius = radius - ringWidth
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - faceRadius, y: cy - faceRadius,
                                       width: faceRadius * 2, height: faceRadius * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: 0xFFFFFFFF), Color(hex: 0xFFF2F5F9), Color(hex: 0xFFDDE4EC)]),
                    center: CGPoint(x: cx - faceRadius * 0.25, y: cy - faceRadius * 0.25),
                    startRadius: 0, endRadius: faceRadius * 1.6))

            // 内阴影圈
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - faceRadius * 0.98, y: cy - faceRadius * 0.98,
                                       width: faceRadius * 1.96, height: faceRadius * 1.96)),
                with: .color(.black.opacity(0.1)), lineWidth: faceRadius * 0.02)

            let tickColor = Color(hex: 0xFF3D3D3D)

            // 刻度
            for i in 0..<60 {
                let angle = Double(i * 6 - 90) * .pi / 180
                let isHour = i % 5 == 0
                let innerR = faceRadius * (isHour ? 0.82 : 0.89)
                let outerR = faceRadius * 0.94
                var tick = Path()
                tick.move(to: CGPoint(x: cx + innerR * cos(angle), y: cy + innerR * sin(angle)))
                tick.addLine(to: CGPoint(x: cx + outerR * cos(angle), y: cy + outerR * sin(angle)))
                ctx.stroke(tick, with: .color(tickColor.opacity(isHour ? 0.82 : 0.35)),
                           style: StrokeStyle(lineWidth: isHour ? 2 : 1, lineCap: .round))
            }

            // 数字
            for h in 1...12 {
                let angle = Double(h * 30 - 90) * .pi / 180
                let textR = faceRadius * 0.68
                ctx.draw(
                    Text("\(h)")
                        .font(.system(size: faceRadius * 0.17, weight: .bold, design: .rounded))
                        .foregroundColor(tickColor),
                    at: CGPoint(x: cx + textR * cos(angle), y: cy + textR * sin(angle)))
            }

            // 时分针（按分钟推进）
            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
            let hours = Double((comps.hour ?? 0) % 12)
            let minutes = Double(comps.minute ?? 0)

            drawHand(&ctx, center: center, angle: (hours + minutes / 60) * 30 - 90,
                     length: faceRadius * 0.5, color: Color(hex: 0xFF2B2B2B), width: faceRadius * 0.045)
            drawHand(&ctx, center: center, angle: minutes * 6 - 90,
                     length: faceRadius * 0.7, color: Color(hex: 0xFF2B2B2B).opacity(0.85), width: faceRadius * 0.03)

            // 中轴（立体双层圆点）
            let dotR = faceRadius * 0.055
            ctx.fill(Path(ellipseIn: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)),
                     with: .color(Color(hex: 0xFF2B7FFF)))
            let dotR2 = faceRadius * 0.028
            ctx.fill(Path(ellipseIn: CGRect(x: cx - dotR2, y: cy - dotR2, width: dotR2 * 2, height: dotR2 * 2)),
                     with: .color(.white))
        }
    }

    private func drawHand(_ ctx: inout GraphicsContext, center: CGPoint, angle: Double,
                          length: CGFloat, color: Color, width: CGFloat) {
        let rad = angle * .pi / 180
        var path = Path()
        path.move(to: CGPoint(x: center.x - length * 0.15 * cos(rad),
                              y: center.y - length * 0.15 * sin(rad)))
        path.addLine(to: CGPoint(x: center.x + length * cos(rad), y: center.y + length * sin(rad)))
        ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

struct ClockWidget: Widget {
    let kind = "SkySenseClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("识天时钟")
        .description("质感指针表盘 + 数字时间与本地化日期")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
