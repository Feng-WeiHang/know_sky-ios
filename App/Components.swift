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

/// 一天中的时段（决定晴/云天空的底色与景物，对应 Android DayPhase）
enum DayPhase {
    case dawn, morning, noon, afternoon, sunset, night
}

/// 背景配色与明暗判定（供前景文字/时钟自适应对比度）
enum WeatherBackdrop {

    static func currentHour() -> Int { Calendar.current.component(.hour, from: Date()) }

    /// 小时 → 时段：5-6黎明 / 7-10清晨 / 11-14晌午 / 15-17午后 / 18-19日落 / 20-4夜晚
    static func phaseOf(_ hour: Int) -> DayPhase {
        switch hour {
        case 5...6: return .dawn
        case 7...10: return .morning
        case 11...14: return .noon
        case 15...17: return .afternoon
        case 18...19: return .sunset
        default: return .night
        }
    }

    /// 背景是否为深色（前景应使用浅色文字）
    static func isDark(_ weatherCode: Int?, hour: Int = currentHour()) -> Bool {
        switch WeatherEffect.of(weatherCode) {
        case .rain, .storm: return true
        case .sand, .snow: return false
        case .cloud:
            switch phaseOf(hour) {
            case .dawn, .sunset, .night: return true
            default: return false
            }
        }
    }

    /// 时段 × 天气 的渐变底色（上→下）
    static func colors(_ weatherCode: Int?, hour: Int = currentHour()) -> [Color] {
        switch WeatherEffect.of(weatherCode) {
        case .rain: return [Color(hex: 0xFF37474F), Color(hex: 0xFF546E7A), Color(hex: 0xFF78909C)]
        case .storm: return [Color(hex: 0xFF1C2331), Color(hex: 0xFF37474F), Color(hex: 0xFF455A64)]
        case .snow: return [Color(hex: 0xFFCFD8DC), Color(hex: 0xFFE3F2FD), Color(hex: 0xFFF5F9FF)]
        case .sand: return [Color(hex: 0xFFC9A24B), Color(hex: 0xFFD9B96E), Color(hex: 0xFFE8D5A3)]
        case .cloud:
            switch phaseOf(hour) {
            // 黎明：夜色未退，地平线泛起鱼肚白与橙晕
            case .dawn: return [Color(hex: 0xFF1B2A52), Color(hex: 0xFF4A548C), Color(hex: 0xFFE8956D)]
            // 清晨：朝阳初升，天青透亮带暖金
            case .morning: return [Color(hex: 0xFF6DB3E8), Color(hex: 0xFFA3D3F5), Color(hex: 0xFFFFE3B8)]
            // 晌午：阳光明媚，通透湛蓝
            case .noon: return [Color(hex: 0xFF2E8FE0), Color(hex: 0xFF5FB0F0), Color(hex: 0xFFAEDCFB)]
            // 午后：日光西斜，蓝中透暖
            case .afternoon: return [Color(hex: 0xFF5B9FD4), Color(hex: 0xFF9CC8E8), Color(hex: 0xFFF7D9A8)]
            // 日落：漫天橙红晚霞渐入暮紫
            case .sunset: return [Color(hex: 0xFF43335F), Color(hex: 0xFFB3556A), Color(hex: 0xFFF29C5A)]
            // 夜晚：深蓝星空
            case .night: return [Color(hex: 0xFF0D1B3E), Color(hex: 0xFF1A2B5C), Color(hex: 0xFF2C3E70)]
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
/// 底色随时段实时变换（黎明 / 清晨 / 晌午 / 午后 / 日落 / 夜晚 六档），
/// 并绘制对应天空景物（朝阳 / 高悬烈日 / 落日余晖 / 月亮星空）；
/// 粒子动效随天气切换（漂浮云彩 / 雨丝 / 雪花 / 沙尘横扫 / 雷暴闪烁）。
/// 时段直接取自 TimelineView 帧时间，跨时段自动切换，无需重进页面。
struct DynamicWeatherBackgroundView: View {
    let weatherCode: Int?

    private static let particles = (0..<48).map { Particle(index: $0) }

    var body: some View {
        let effect = WeatherEffect.of(weatherCode)

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { ctx, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let t = (time.truncatingRemainder(dividingBy: 12)) / 12          // 主进度：粒子循环
                let flash = (time.truncatingRemainder(dividingBy: 3.6)) / 3.6    // 雷暴闪烁
                // 时段随帧时间实时计算，跨时段无感切换
                let hour = Calendar.current.component(.hour, from: timeline.date)
                let phase = WeatherBackdrop.phaseOf(hour)
                let colors = WeatherBackdrop.colors(weatherCode, hour: hour)

                // 时段渐变底色
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(colors: colors),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                ))

                switch effect {
                case .cloud:
                    // 天空景物：随时段绘制太阳/月亮/星空
                    switch phase {
                    case .dawn:
                        drawStars(&ctx, size, t, dim: 0.45)
                        drawSun(&ctx, size, cx: 0.22, cy: 0.88, r: 0.085, glow: 0.9, tint: Color(hex: 0xFFFFB74D), t: t)
                    case .morning:
                        drawSun(&ctx, size, cx: 0.20, cy: 0.30, r: 0.075, glow: 0.55, tint: Color(hex: 0xFFFFE082), t: t)
                    case .noon:
                        drawSun(&ctx, size, cx: 0.50, cy: 0.16, r: 0.085, glow: 0.75, tint: Color(hex: 0xFFFFF59D), t: t, rays: true)
                    case .afternoon:
                        drawSun(&ctx, size, cx: 0.76, cy: 0.32, r: 0.075, glow: 0.55, tint: Color(hex: 0xFFFFD180), t: t)
                    case .sunset:
                        drawSun(&ctx, size, cx: 0.80, cy: 0.86, r: 0.10, glow: 1.0, tint: Color(hex: 0xFFFF8A65), t: t)
                    case .night:
                        drawStars(&ctx, size, t, dim: 1)
                        drawMoon(&ctx, size, t)
                    }
                    drawClouds(&ctx, size, t, night: phase == .night, count: 5)
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

    /// 太阳：光晕呼吸 + 可选放射光芒（晌午烈日）
    private func drawSun(_ ctx: inout GraphicsContext, _ size: CGSize,
                         cx: Double, cy: Double, r: Double,
                         glow: Double, tint: Color, t: Double, rays: Bool = false) {
        let center = CGPoint(x: cx * size.width, y: cy * size.height)
        let radius = r * size.width
        let breathe = 1 + 0.06 * sin(t * 6.28 * 2)
        // 三层光晕由外向内
        for (mul, alpha) in [(2.6 * breathe, 0.10), (1.9 * breathe, 0.18), (1.4, 0.30)] {
            let rr = radius * mul
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2)),
                     with: .color(tint.opacity(alpha * glow)))
        }
        // 日轮
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                 with: .radialGradient(Gradient(colors: [.white.opacity(0.95), tint]),
                                       center: center, startRadius: 0, endRadius: radius))
        // 晌午放射光芒（缓慢旋转）
        if rays {
            let rot = t * 0.5
            for i in 0..<12 {
                let a = (Double(i * 30) + rot * 360) * .pi / 180
                let inner = radius * 1.55
                let outer = radius * (2.0 + 0.15 * sin((t * 4 + Double(i)) * 6.28))
                var path = Path()
                path.move(to: CGPoint(x: center.x + inner * cos(a), y: center.y + inner * sin(a)))
                path.addLine(to: CGPoint(x: center.x + outer * cos(a), y: center.y + outer * sin(a)))
                ctx.stroke(path, with: .color(tint.opacity(0.45)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        }
    }

    /// 弯月：主圆叠夜色遮罩圆形成月牙，附柔和光晕
    private func drawMoon(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let center = CGPoint(x: size.width * 0.78, y: size.height * 0.22)
        let radius = size.width * 0.06
        let breathe = 1 + 0.05 * sin(t * 6.28 * 2)
        let halo = radius * 2.2 * breathe
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - halo, y: center.y - halo, width: halo * 2, height: halo * 2)),
                 with: .color(Color(hex: 0xFFFFF9C4).opacity(0.12)))
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                 with: .color(Color(hex: 0xFFFFF9C4).opacity(0.95)))
        // 遮罩圆偏移形成月牙（用背景夜色盖掉一角）
        let mr = radius * 0.92
        let mc = CGPoint(x: center.x - radius * 0.42, y: center.y - radius * 0.30)
        ctx.fill(Path(ellipseIn: CGRect(x: mc.x - mr, y: mc.y - mr, width: mr * 2, height: mr * 2)),
                 with: .color(Color(hex: 0xFF16254E)))
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

    /// 夜空星星：轻微闪烁（dim 控制整体亮度，黎明残星更暗淡）
    private func drawStars(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, dim: Double = 1) {
        for p in Self.particles.dropFirst(5).prefix(30) {
            let alpha = 0.3 + 0.7 * ((sin((t * 6.28 + p.phase * 6.28) * (1 + p.speed)) + 1) / 2)
            let r = 1.2 + p.size * 2
            let c = CGPoint(x: p.x * size.width, y: p.y * size.height * 0.7)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                     with: .color(.white.opacity(alpha * 0.8 * dim)))
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
    var faceColor: Color = .clear
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

                    // 磨砂表盘底色（与动态背景拉开色差，保证指针/刻度清晰）
                    if faceColor != .clear {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: cx - radius - 2, y: cy - radius - 2,
                                                   width: (radius + 2) * 2, height: (radius + 2) * 2)),
                            with: .color(faceColor))
                    }

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
