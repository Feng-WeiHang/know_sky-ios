import SwiftUI

// MARK: - 背景配色与明暗判定（对应 Android WeatherBackdrop）

/// 天气动效类型
enum WeatherEffect {
    case cloud, rain, snow, sand, storm

    static func of(_ weatherCode: Int?) -> WeatherEffect {
        switch weatherCode ?? -1 {
        case 45, 48: return .sand // 雾/霾/沙尘：低能见度横扫粒子
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: return .rain
        case 71, 73, 75, 77, 85, 86: return .snow
        case 95, 96, 99: return .storm
        default: return .cloud
        }
    }
}

/// 背景配色与明暗判定（供前景文字/时钟自适应对比度）
enum WeatherBackdrop {

    static func currentHour() -> Int { Calendar.current.component(.hour, from: Date()) }

    /// 背景是否为深色（前景应使用浅色文字）
    static func isDark(_ weatherCode: Int?, hour: Int = currentHour()) -> Bool {
        switch WeatherEffect.of(weatherCode) {
        case .rain, .storm: return true
        case .sand, .snow: return false
        case .cloud: return !(5...18).contains(hour)
        }
    }

    /// 时段 × 天气 的渐变底色
    static func colors(_ weatherCode: Int?, hour: Int = currentHour()) -> [Color] {
        switch WeatherEffect.of(weatherCode) {
        case .rain: return [Color(hex: 0xFF37474F), Color(hex: 0xFF546E7A), Color(hex: 0xFF78909C)]
        case .storm: return [Color(hex: 0xFF1C2331), Color(hex: 0xFF37474F), Color(hex: 0xFF455A64)]
        case .snow: return [Color(hex: 0xFFCFD8DC), Color(hex: 0xFFE3F2FD), Color(hex: 0xFFF5F9FF)]
        case .sand: return [Color(hex: 0xFFC9A24B), Color(hex: 0xFFD9B96E), Color(hex: 0xFFE8D5A3)]
        case .cloud:
            switch hour {
            case 5...8, 17...18: return [Color(hex: 0xFFFF9E80), Color(hex: 0xFFFFC1A6), Color(hex: 0xFFFFE0CC)] // 晨曦橙粉
            case 9...16: return [Color(hex: 0xFF4FA8E8), Color(hex: 0xFF7BC2F2), Color(hex: 0xFFB3DDFA)]         // 午后明亮蓝
            default: return [Color(hex: 0xFF0D1B3E), Color(hex: 0xFF1A2B5C), Color(hex: 0xFF2C3E70)]             // 夜晚深蓝
            }
        }
    }
}

// MARK: - 动态天气背景（对应 Android DynamicWeatherBackground）

/// 单个粒子的随机种子（归一化 0..1，按下标确定性生成）
private struct Particle {
    let x: Double
    let y: Double
    let speed: Double
    let size: Double
    let phase: Double

    init(index: Int) {
        var seed = UInt64(index * 7919 + 13)
        func rnd() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double((seed >> 33) & 0x7FFF_FFFF) / Double(0x7FFF_FFFF)
        }
        x = rnd(); y = rnd(); speed = 0.5 + rnd(); size = rnd(); phase = rnd()
    }
}

/// 主界面动态天气背景：
/// 底色随时段渐变（清晨橙粉 / 午后明亮蓝 / 夜晚深蓝星空），
/// 粒子动效随天气切换（漂浮云彩 / 雨丝 / 雪花 / 沙尘横扫 / 雷暴闪烁）。
struct DynamicWeatherBackgroundView: View {
    let weatherCode: Int?

    private static let particles = (0..<48).map { Particle(index: $0) }

    var body: some View {
        let hour = WeatherBackdrop.currentHour()
        let effect = WeatherEffect.of(weatherCode)
        let colors = WeatherBackdrop.colors(weatherCode, hour: hour)
        let night = !(5...18).contains(hour)

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { ctx, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let t = (time.truncatingRemainder(dividingBy: 12)) / 12          // 主进度：粒子循环
                let flash = (time.truncatingRemainder(dividingBy: 3.6)) / 3.6    // 雷暴闪烁

                // 时段渐变底色
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(colors: colors),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                ))

                switch effect {
                case .cloud:
                    if night { drawStars(&ctx, size, t) }
                    drawClouds(&ctx, size, t, night: night, count: 5)
                case .rain:
                    drawClouds(&ctx, size, t, night: true, count: 3)
                    drawRain(&ctx, size, t)
                case .snow:
                    drawSnow(&ctx, size, t)
                case .sand:
                    drawSand(&ctx, size, t)
                case .storm:
                    drawClouds(&ctx, size, t, night: true, count: 3)
                    drawRain(&ctx, size, t)
                    // 闪电亮屏（周期内前 8% 时间闪两下）
                    let alpha: Double
                    if flash < 0.03 { alpha = (0.03 - flash) / 0.03 * 0.5 }
                    else if (0.06...0.08).contains(flash) { alpha = 0.35 }
                    else { alpha = 0 }
                    if alpha > 0 {
                        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(alpha)))
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    /// 微动漂浮云彩：多圆组合云团缓慢横移
    private func drawClouds(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, night: Bool, count: Int) {
        let cloudColor = Color.white.opacity(night ? 0.10 : 0.55)
        for (i, p) in Self.particles.prefix(count).enumerated() {
            let w = size.width, h = size.height
            let speed = 0.03 + p.speed * 0.02
            let dir: Double = i % 2 == 0 ? 1 : -1
            let cx = (((p.x + t * speed * dir).truncatingRemainder(dividingBy: 1) + 1)
                .truncatingRemainder(dividingBy: 1)) * (w * 1.4) - w * 0.2
            let cy = h * (0.12 + p.y * 0.45)
            let r = w * (0.10 + p.size * 0.08)
            // 云团 = 三个错落的圆
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(cloudColor))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + r * 0.9 - r * 0.75, y: cy + r * 0.15 - r * 0.75, width: r * 1.5, height: r * 1.5)), with: .color(cloudColor))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r * 0.85 - r * 0.65, y: cy + r * 0.2 - r * 0.65, width: r * 1.3, height: r * 1.3)), with: .color(cloudColor))
        }
    }

    /// 夜空星星：轻微闪烁
    private func drawStars(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for p in Self.particles.dropFirst(5).prefix(30) {
            let alpha = 0.3 + 0.7 * ((sin((t * 6.28 + p.phase * 6.28) * (1 + p.speed)) + 1) / 2)
            let r = 1.2 + p.size * 2
            let c = CGPoint(x: p.x * size.width, y: p.y * size.height * 0.7)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                     with: .color(.white.opacity(alpha * 0.8)))
        }
    }

    /// 下落雨丝
    private func drawRain(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for p in Self.particles {
            let fall = (p.y + t * (2.5 + p.speed * 2)).truncatingRemainder(dividingBy: 1)
            let x = p.x * size.width + fall * size.height * 0.12
            let y = fall * size.height
            let len = 18 + p.size * 22
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + len * 0.15, y: y + len))
            ctx.stroke(path, with: .color(Color(hex: 0xCCE1F5FE).opacity(0.25 + p.size * 0.35)),
                       style: StrokeStyle(lineWidth: 1.5 + p.size, lineCap: .round))
        }
    }

    /// 飘落雪花：左右摇摆下落
    private func drawSnow(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for p in Self.particles {
            let fall = (p.y + t * (0.6 + p.speed * 0.5)).truncatingRemainder(dividingBy: 1)
            let sway = sin((fall * 4 + p.phase) * 6.28) * size.width * 0.03
            let r = 2 + p.size * 4
            let c = CGPoint(x: p.x * size.width + sway, y: fall * size.height)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                     with: .color(.white.opacity(0.5 + p.size * 0.5)))
        }
    }

    /// 黄沙暴风粒子横扫
    private func drawSand(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let sandColor = Color(hex: 0xFF8D6E2F)
        for p in Self.particles {
            let drift = (p.x + t * (2 + p.speed * 3)).truncatingRemainder(dividingBy: 1)
            let x = drift * size.width * 1.2 - size.width * 0.1
            let y = p.y * size.height + sin((drift * 3 + p.phase) * 6.28) * 20
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + 24 + p.size * 30, y: y + 3))
            ctx.stroke(path, with: .color(sandColor.opacity(0.15 + p.size * 0.3)),
                       style: StrokeStyle(lineWidth: 1.5 + p.size * 2, lineCap: .round))
        }
    }
}

// MARK: - 指针式模拟时钟（对应 Android AnalogClock，Canvas 绘制）

struct AnalogClockView: View {
    var size: CGFloat = 200
    var primaryColor: Color = .accentColor
    var textColor: Color = .primary
    var showDigitalTime = true
    var language: AppLanguage = .simplifiedChinese

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let comps = Calendar.current.dateComponents(
                [.hour, .minute, .second, .year, .month, .day, .weekday], from: timeline.date)
            let hours = Double((comps.hour ?? 0) % 12)
            let minutes = Double(comps.minute ?? 0)
            let seconds = Double(comps.second ?? 0)

            VStack(spacing: 8) {
                Canvas { ctx, canvasSize in
                    let cx = canvasSize.width / 2
                    let cy = canvasSize.height / 2
                    let radius = min(cx, cy) * 0.92
                    let center = CGPoint(x: cx, y: cy)

                    // 外圈
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: cx - radius - 2, y: cy - radius - 2,
                                               width: (radius + 2) * 2, height: (radius + 2) * 2)),
                        with: .color(textColor.opacity(0.3)), lineWidth: 1.5)

                    // 刻度
                    for i in 0..<60 {
                        let angle = Double(i * 6 - 90) * .pi / 180
                        let isHour = i % 5 == 0
                        let innerR = radius * (isHour ? 0.82 : 0.9)
                        let outerR = radius * 0.95
                        var tick = Path()
                        tick.move(to: CGPoint(x: cx + innerR * cos(angle), y: cy + innerR * sin(angle)))
                        tick.addLine(to: CGPoint(x: cx + outerR * cos(angle), y: cy + outerR * sin(angle)))
                        ctx.stroke(tick, with: .color(textColor.opacity(isHour ? 0.8 : 0.3)),
                                   lineWidth: isHour ? 1.6 : 0.8)
                    }

                    // 小时数字
                    for h in 1...12 {
                        let angle = Double(h * 30 - 90) * .pi / 180
                        let textR = radius * 0.72
                        let pos = CGPoint(x: cx + textR * cos(angle), y: cy + textR * sin(angle))
                        ctx.draw(
                            Text("\(h)")
                                .font(.system(size: radius * 0.14, weight: .bold, design: .rounded))
                                .foregroundColor(textColor),
                            at: pos)
                    }

                    // 时针
                    drawHand(&ctx, center: center,
                             angle: (hours + minutes / 60) * 30 - 90,
                             length: radius * 0.52, tail: 4,
                             color: primaryColor, width: 4)
                    // 分针
                    drawHand(&ctx, center: center,
                             angle: (minutes + seconds / 60) * 6 - 90,
                             length: radius * 0.72, tail: 5,
                             color: primaryColor.opacity(0.85), width: 2.6)
                    // 秒针
                    drawHand(&ctx, center: center,
                             angle: seconds * 6 - 90,
                             length: radius * 0.78, tail: 8,
                             color: Color(hex: 0xFFE53935), width: 1.2)

                    // 中心点
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - 4.5, y: cy - 4.5, width: 9, height: 9)),
                             with: .color(primaryColor))
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - 2, y: cy - 2, width: 4, height: 4)),
                             with: .color(.white))
                }
                .frame(width: size, height: size)

                // 数字时间 + 本地化日期
                if showDigitalTime {
                    Text(digitalTime(timeline.date))
                        .font(.system(size: 40, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(textColor)
                    Text(I18n.fullDateLabel(
                        year: comps.year ?? 2026, month: comps.month ?? 1, day: comps.day ?? 1,
                        weekdayIndex: (comps.weekday ?? 1) - 1, language: language))
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
        }
    }

    private func drawHand(_ ctx: inout GraphicsContext, center: CGPoint, angle: Double,
                          length: CGFloat, tail: CGFloat, color: Color, width: CGFloat) {
        let rad = angle * .pi / 180
        var path = Path()
        path.move(to: CGPoint(x: center.x - tail * cos(rad), y: center.y - tail * sin(rad)))
        path.addLine(to: CGPoint(x: center.x + length * cos(rad), y: center.y + length * sin(rad)))
        ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func digitalTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: date)
    }
}
