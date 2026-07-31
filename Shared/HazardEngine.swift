import Foundation

/// 地表灾害多因子推理引擎（对应 Android util/HazardEngine.kt，判据与权重逐条一致）
///
/// 思路：气象要素按时间窗聚合 → 与地形/地理要素做门控判定 → 加权评分 → 映射等级 →
/// 绑定具体落点（OSM 命中的街道/村/高速/河流，或方位回退）→ 输出语言无关的预测结构。
///
/// 主要科学判据：
///  - Caine (1980) 降雨强度-历时滑坡阈值 I = 14.82 × D^(-0.39)
///  - 气压增水 1 hPa ≈ 1 cm；风致增水 ≈ 0.0006 × U²(m/s)
///  - 深水有效波高 Hs ≈ 0.0035 × U²(m/s)
///  - 度日因子融雪 ≈ 4 mm/(°C·d)
///  - Angström 火险指数 I = RH/20 + (27 − T)/10
///  - 城市排水按 3 小时 25 毫米折算，超量部分乘地形汇流系数折为积水深度
enum HazardEngine {

    /// metricLabels 索引
    enum M {
        static let slope = 0
        static let rainSum = 1
        static let rainRate = 2
        static let soilTop = 3
        static let soilDeep = 4
        static let gust = 5
        static let snowDepth = 6
        static let snowNew = 7
        static let tempMin = 8
        static let tempMax = 9
        static let freezeThaw = 10
        static let visibility = 11
        static let humidity = 12
        static let pressureMin = 13
        static let relief = 14
        static let lowland = 15
        static let cape = 16
        static let wind = 17
    }

    /// 单卡最多展示条数
    static let maxItems = 16

    // MARK: - 入口

    static func analyze(
        profile: TerrainProfile,
        features: [GeoFeature],
        hourly: HazardHourly,
        anchorIso: String?
    ) -> [HazardPrediction] {
        let times = hourly.time
        if times.isEmpty { return [] }
        var start = 0
        if let anchor = anchorIso?.prefix(13) {
            if let idx = times.firstIndex(where: { $0.prefix(13) >= anchor }) { start = idx }
        }

        let w = aggregate(hourly, start: start)
        let sites = SitePicker(profile: profile, features: features)
        var out: [HazardPrediction] = []

        func emit(
            _ type: HazardType,
            _ score: Double,
            valueA: String? = nil,
            valueB: String? = nil,
            metrics: [HazardMetric] = []
        ) {
            let s = clamp(score, 0, 1)
            guard let level = HazardLevel.fromScore(s, cap: type.levelCap) else { return }
            guard let site = sites.pick(type.siteKind) else { return }
            out.append(
                HazardPrediction(
                    type: type, level: level, score: s,
                    featureName: site.name, bearingIndex: site.bearingIndex,
                    distanceKm: site.distanceKm, valueA: valueA, valueB: valueB,
                    metrics: metrics
                )
            )
        }

        let slope = profile.maxSlopeDeg
        let relief = profile.relief
        let lowRatio = profile.lowlandRatio
        let hasRoad = sites.hasRoad
        let hasRiver = sites.hasRiver
        let hasReservoir = sites.hasReservoir
        let coastal = profile.isCoastal && sites.hasCoast

        // ---------- 1 泥石流 ----------
        if slope >= 4.0 && (w.p6 >= 30 || w.p24 >= 60) {
            emit(
                .debrisFlow,
                0.45 * ramp(slope, 4, 12) + 0.35 * ramp(w.p6, 25, 80) +
                    0.20 * ramp(w.soilDeep, 0.25, 0.42),
                valueA: mm(w.p6),
                metrics: [
                    metric(M.slope, deg(slope)), metric(M.rainSum, mm(w.p6)),
                    metric(M.soilDeep, pct(w.soilDeep))
                ]
            )
        }

        // ---------- 2 山体滑坡 ----------
        if slope >= 3.0 && (w.p24 >= 50 || (w.soilDeep >= 0.33 && w.p12 >= 25)) {
            emit(
                .landslide,
                0.40 * ramp(slope, 3, 10) + 0.35 * ramp(w.p24, 40, 120) +
                    0.25 * ramp(w.soilDeep, 0.28, 0.45),
                valueA: mm(w.p24), valueB: pct(w.soilDeep),
                metrics: [
                    metric(M.slope, deg(slope)), metric(M.rainSum, mm(w.p24)),
                    metric(M.relief, m0(relief))
                ]
            )
        }

        // ---------- 3 崩塌落石 ----------
        if slope >= 4.0 && (w.p12 >= 20 || w.freezeThaw >= 2) {
            emit(
                .rockfall,
                0.40 * ramp(slope, 4, 12) + 0.30 * ramp(w.p12, 15, 60) +
                    0.30 * ramp(Double(w.freezeThaw), 1, 6),
                valueA: deg(slope),
                metrics: [
                    metric(M.slope, deg(slope)), metric(M.rainSum, mm(w.p12)),
                    metric(M.freezeThaw, "\(w.freezeThaw)")
                ]
            )
        }

        // ---------- 4 路基边坡垮塌 ----------
        if hasRoad && slope >= 3.0 && w.p12 >= 30 {
            emit(
                .slopeCollapse,
                0.35 * ramp(slope, 3, 10) + 0.40 * ramp(w.p12, 25, 80) +
                    0.25 * ramp(w.soilMid, 0.25, 0.42),
                valueA: mm(w.p12),
                metrics: [
                    metric(M.rainSum, mm(w.p12)), metric(M.slope, deg(slope)),
                    metric(M.soilTop, pct(w.soilMid))
                ]
            )
        }

        // ---------- 5 山洪暴发 ----------
        if relief >= 100 && (w.p3 >= 25 || w.p1 >= 15) {
            emit(
                .flashFlood,
                0.45 * ramp(w.p3, 20, 70) + 0.30 * ramp(w.p1, 12, 40) +
                    0.25 * ramp(relief, 80, 600),
                valueA: mm(w.p3), valueB: mm(w.p1),
                metrics: [
                    metric(M.rainRate, mm(w.p1)), metric(M.rainSum, mm(w.p3)),
                    metric(M.relief, m0(relief))
                ]
            )
        }

        // ---------- 6 路面积水 / 7 涵洞倒灌 ----------
        if w.p3 >= 20 || w.p1 >= 15 {
            let k = 4.0 + 6.0 * ramp(relief, 20, 300) + 2.0 * ramp(lowRatio, 0.1, 0.6)
            let depth = clamp(((w.p3 - 25.0) / 1000.0) * k, 0.05, 1.2)
            emit(
                .urbanWaterlog,
                0.55 * ramp(w.p3, 20, 80) + 0.25 * ramp(w.p1, 12, 40) +
                    0.20 * ramp(lowRatio, 0.1, 0.5),
                valueA: mm(w.p3), valueB: m2(depth),
                metrics: [
                    metric(M.rainSum, mm(w.p3)), metric(M.rainRate, mm(w.p1)),
                    metric(M.lowland, pct(lowRatio))
                ]
            )
            if hasRoad && (w.p3 >= 25 || w.p1 >= 20) {
                emit(
                    .underpassFlood,
                    0.50 * ramp(w.p3, 25, 80) + 0.30 * ramp(w.p1, 15, 45) +
                        0.20 * ramp(lowRatio, 0.1, 0.5),
                    valueA: m2(clamp(depth * 1.6, 0.1, 2.0)),
                    metrics: [
                        metric(M.rainSum, mm(w.p3)), metric(M.rainRate, mm(w.p1)),
                        metric(M.lowland, pct(lowRatio))
                    ]
                )
            }
        }

        // ---------- 8 河道涨水漫堤 ----------
        if hasRiver && w.p24 >= 40 {
            let coef = 8.0 + 17.0 * ramp(relief, 50, 800)
            let rise = clamp((w.p24 / 1000.0) * coef, 0.1, 6.0)
            emit(
                .riverFlood,
                0.50 * ramp(w.p24, 40, 150) + 0.25 * ramp(w.p48, 60, 250) +
                    0.25 * ramp(w.soilDeep, 0.28, 0.45),
                valueA: mm(w.p24), valueB: m2(rise),
                metrics: [
                    metric(M.rainSum, mm(w.p24)), metric(M.soilDeep, pct(w.soilDeep)),
                    metric(M.relief, m0(relief))
                ]
            )
        }

        // ---------- 9 水库超汛限泄洪 ----------
        if hasReservoir && w.p24 >= 45 {
            emit(
                .reservoirSpill,
                0.55 * ramp(w.p24, 45, 150) + 0.25 * ramp(w.p48, 70, 260) +
                    0.20 * ramp(w.p6, 20, 70),
                valueA: mm(w.p24),
                metrics: [
                    metric(M.rainSum, mm(w.p24)), metric(M.rainRate, mm(w.p1))
                ]
            )
        }

        // ---------- 10 农田内涝 ----------
        if w.p24 >= 35 && (lowRatio >= 0.15 || w.soilTop >= 0.35) {
            emit(
                .farmlandWaterlog,
                0.45 * ramp(w.p24, 35, 120) + 0.30 * ramp(w.soilTop, 0.30, 0.45) +
                    0.25 * ramp(lowRatio, 0.15, 0.55),
                valueA: mm(w.p24), valueB: pct(w.soilTop),
                metrics: [
                    metric(M.rainSum, mm(w.p24)), metric(M.soilTop, pct(w.soilTop)),
                    metric(M.lowland, pct(lowRatio))
                ]
            )
        }

        // ---------- 11 风暴潮增水 ----------
        if coastal && (w.pressureMin <= 1005 || w.windMax >= 45) {
            let windMs = w.windMax / 3.6
            let surge = clamp(0.01 * max(0, 1013.0 - w.pressureMin) + 0.0006 * windMs * windMs, 0.05, 4.0)
            emit(
                .stormSurge,
                0.50 * ramp(surge, 0.2, 1.5) + 0.30 * ramp(w.gustMax, 40, 110) +
                    0.20 * ramp(w.p24, 20, 100),
                valueA: hpa(w.pressureMin), valueB: m2(surge),
                metrics: [
                    metric(M.pressureMin, hpa(w.pressureMin)), metric(M.gust, kmh(w.gustMax)),
                    metric(M.wind, kmh(w.windMax))
                ]
            )
        }

        // ---------- 12 近岸巨浪 ----------
        if coastal && w.windMax >= 30 {
            let windMs = w.windMax / 3.6
            let hs = clamp(0.0035 * windMs * windMs, 0.2, 12.0)
            emit(
                .highWaves,
                0.55 * ramp(hs, 1, 5) + 0.45 * ramp(w.gustMax, 35, 100),
                valueA: kmh(w.gustMax), valueB: m1(hs),
                metrics: [
                    metric(M.gust, kmh(w.gustMax)), metric(M.wind, kmh(w.windMax))
                ]
            )
        }

        // ---------- 13 潮水顶托倒灌 ----------
        if coastal && hasRiver && (w.p12 >= 20 || w.pressureMin <= 1008) {
            emit(
                .tidalBackflow,
                0.40 * ramp(w.p12, 15, 60) + 0.30 * ramp(1013.0 - w.pressureMin, 3, 25) +
                    0.30 * ramp(w.gustMax, 30, 90),
                valueA: mm(w.p12),
                metrics: [
                    metric(M.rainSum, mm(w.p12)), metric(M.pressureMin, hpa(w.pressureMin))
                ]
            )
        }

        // ---------- 14 道路结冰 / 15 桥面暗冰 ----------
        if hasRoad && w.tempMin <= 1.0 && (w.p24 >= 1 || w.humidityMax >= 88 || w.snowNew >= 0.5) {
            emit(
                .roadIce,
                0.45 * ramp(-w.tempMin, -1, 8) + 0.30 * ramp(w.p24, 0.5, 15) +
                    0.25 * ramp(Double(w.humidityMax), 80, 98),
                valueA: c1(w.tempMin),
                metrics: [
                    metric(M.tempMin, c1(w.tempMin)), metric(M.humidity, "\(w.humidityMax)%"),
                    metric(M.rainSum, mm(w.p24))
                ]
            )
        }
        if hasRoad && w.tempMin <= 2.0 && (w.humidityMax >= 85 || w.p24 >= 0.5) {
            emit(
                .bridgeIce,
                0.45 * ramp(-w.tempMin, -2, 6) + 0.30 * ramp(Double(w.humidityMax), 80, 98) +
                    0.25 * ramp(w.windMax, 10, 45),
                valueA: c1(w.tempMin),
                metrics: [
                    metric(M.tempMin, c1(w.tempMin)), metric(M.wind, kmh(w.windMax)),
                    metric(M.humidity, "\(w.humidityMax)%")
                ]
            )
        }

        // ---------- 16 积雪荷载 ----------
        if w.snowNew >= 8 || w.snowDepth >= 0.2 {
            emit(
                .snowLoad,
                0.50 * ramp(w.snowNew, 8, 40) + 0.50 * ramp(w.snowDepth, 0.15, 0.8),
                valueA: cm(w.snowNew), valueB: m2(w.snowDepth),
                metrics: [
                    metric(M.snowNew, cm(w.snowNew)), metric(M.snowDepth, m2(w.snowDepth)),
                    metric(M.tempMin, c1(w.tempMin))
                ]
            )
        }

        // ---------- 17 雪崩 ----------
        if profile.maxElevation >= 1500 && w.snowDepth >= 0.4 && slope >= 4.0 &&
            (w.snowNew >= 10 || w.tempMax >= 2) {
            emit(
                .avalanche,
                0.35 * ramp(w.snowDepth, 0.4, 2.0) + 0.30 * ramp(w.snowNew, 10, 45) +
                    0.20 * ramp(slope, 4, 12) + 0.15 * ramp(w.tempMax, -2, 6),
                valueA: m2(w.snowDepth), valueB: cm(w.snowNew),
                metrics: [
                    metric(M.snowDepth, m2(w.snowDepth)), metric(M.snowNew, cm(w.snowNew)),
                    metric(M.slope, deg(slope))
                ]
            )
        }

        // ---------- 18 融雪型洪水 ----------
        if hasRiver && w.snowDepth >= 0.15 && w.tempMax >= 3 {
            let melt = 4.0 * max(0, w.tempMax)
            emit(
                .snowmeltFlood,
                0.40 * ramp(melt, 10, 60) + 0.30 * ramp(w.snowDepth, 0.15, 1.0) +
                    0.30 * ramp(w.p24, 5, 50),
                valueA: c1(w.tempMax), valueB: m2(w.snowDepth),
                metrics: [
                    metric(M.tempMax, c1(w.tempMax)), metric(M.snowDepth, m2(w.snowDepth)),
                    metric(M.rainSum, mm(w.p24))
                ]
            )
        }

        // ---------- 19 冻融翻浆 ----------
        if hasRoad && w.freezeThaw >= 2 && (w.p48 >= 3 || w.snowDepth >= 0.05) {
            emit(
                .frostHeave,
                0.50 * ramp(Double(w.freezeThaw), 2, 10) + 0.30 * ramp(w.p48, 3, 30) +
                    0.20 * ramp(-w.tempMin, -2, 10),
                valueA: "\(w.freezeThaw)",
                metrics: [
                    metric(M.freezeThaw, "\(w.freezeThaw)"), metric(M.tempMin, c1(w.tempMin)),
                    metric(M.rainSum, mm(w.p48))
                ]
            )
        }

        // ---------- 20 大风损毁 ----------
        if w.gustMax >= 55 {
            emit(
                .windDamage,
                0.60 * ramp(w.gustMax, 55, 140) + 0.25 * ramp(w.windMax, 35, 90) +
                    0.15 * ramp(w.cape, 300, 2500),
                valueA: kmh(w.gustMax), valueB: "\(beaufort(w.gustMax))",
                metrics: [
                    metric(M.gust, kmh(w.gustMax)), metric(M.wind, kmh(w.windMax)),
                    metric(M.cape, "\(Int(w.cape.rounded())) J/kg")
                ]
            )
        }

        // ---------- 21 高速团雾 ----------
        if hasRoad && w.visibilityMin <= 1500 && w.humidityMax >= 88 {
            emit(
                .highwayFog,
                0.55 * (1.0 - ramp(w.visibilityMin, 50, 1500)) +
                    0.30 * ramp(Double(w.humidityMax), 88, 99) +
                    0.15 * (1.0 - ramp(w.windMax, 3, 20)),
                valueA: "\(Int(w.visibilityMin.rounded()))",
                metrics: [
                    metric(M.visibility, "\(Int(w.visibilityMin.rounded())) m"),
                    metric(M.humidity, "\(w.humidityMax)%"), metric(M.wind, kmh(w.windMax))
                ]
            )
        }

        // ---------- 22 扬沙沙尘 ----------
        if w.gustMax >= 35 && w.humidityMin <= 45 && w.p48 <= 3 && w.snowDepth < 0.02 {
            emit(
                .dustStorm,
                0.50 * ramp(w.gustMax, 35, 100) + 0.30 * (1.0 - ramp(Double(w.humidityMin), 10, 45)) +
                    0.20 * (1.0 - ramp(w.p48, 0, 5)),
                valueA: kmh(w.gustMax), valueB: "\(w.humidityMin)",
                metrics: [
                    metric(M.gust, kmh(w.gustMax)), metric(M.humidity, "\(w.humidityMin)%"),
                    metric(M.rainSum, mm(w.p48))
                ]
            )
        }

        // ---------- 23 山林火险 ----------
        if profile.isMountainous && w.p48 <= 2 && w.humidityMin <= 45 && w.tempMax >= 22 {
            let angstrom = Double(w.humidityMin) / 20.0 + (27.0 - w.tempMax) / 10.0
            emit(
                .wildfire,
                0.50 * ramp(4.0 - angstrom, 0, 3) +
                    0.30 * (1.0 - ramp(Double(w.humidityMin), 15, 50)) +
                    0.20 * ramp(w.gustMax, 20, 70),
                valueA: c1(w.tempMax), valueB: "\(w.humidityMin)",
                metrics: [
                    metric(M.tempMax, c1(w.tempMax)), metric(M.humidity, "\(w.humidityMin)%"),
                    metric(M.gust, kmh(w.gustMax))
                ]
            )
        }

        // ---------- 24 土壤干裂 ----------
        if w.p48 <= 1.5 && w.soilTop <= 0.16 && w.tempMax >= 20 {
            emit(
                .soilCrack,
                0.50 * (1.0 - ramp(w.soilTop, 0.05, 0.20)) +
                    0.30 * (1.0 - ramp(Double(w.humidityMin), 15, 50)) +
                    0.20 * ramp(w.tempMax, 20, 40),
                valueA: pct(w.soilTop),
                metrics: [
                    metric(M.soilTop, pct(w.soilTop)), metric(M.tempMax, c1(w.tempMax)),
                    metric(M.humidity, "\(w.humidityMin)%")
                ]
            )
        }

        // ---------- 25 路面塌陷 ----------
        if hasRoad && w.p24 >= 45 {
            emit(
                .groundSubsidence,
                0.50 * ramp(w.p24, 45, 140) + 0.30 * ramp(w.p1, 15, 45) +
                    0.20 * ramp(w.soilMid, 0.28, 0.45),
                valueA: mm(w.p24),
                metrics: [
                    metric(M.rainSum, mm(w.p24)), metric(M.rainRate, mm(w.p1)),
                    metric(M.soilTop, pct(w.soilMid))
                ]
            )
        }

        // ---------- 26 水土流失 ----------
        if slope >= 3.0 && w.p24 >= 25 {
            emit(
                .erosion,
                0.45 * ramp(w.p24, 25, 110) + 0.30 * ramp(slope, 3, 10) +
                    0.25 * ramp(w.p1, 10, 35),
                valueA: mm(w.p24),
                metrics: [
                    metric(M.rainSum, mm(w.p24)), metric(M.slope, deg(slope)),
                    metric(M.rainRate, mm(w.p1))
                ]
            )
        }

        // 紧急 → 重要 → 一般；同级按评分降序
        let sorted = out.sorted { a, b in
            a.level.rawValue == b.level.rawValue ? a.score > b.score : a.level.rawValue < b.level.rawValue
        }
        return Array(sorted.prefix(maxItems))
    }

    // MARK: - 地点绑定

    private struct Site {
        let name: String?
        let bearingIndex: Int
        let distanceKm: Double
    }

    /// 按灾害载体类型挑选落点；同类灾害轮转取不同候选，避免所有条目指向同一地名。
    /// Overpass 不可用（features 为空）时：道路类允许走方位回退，河流/水库/海岸线不臆测其存在。
    private final class SitePicker {
        private let cLat: Double
        private let cLon: Double
        private let steep: TerrainPoint?
        private let low: TerrainPoint?
        private let sea: TerrainPoint?

        private let peaks: [GeoFeature]
        private let slopeSettlements: [GeoFeature]
        private let lowSettlements: [GeoFeature]
        private let roads: [GeoFeature]
        private let rivers: [GeoFeature]
        private let coasts: [GeoFeature]
        private let reservoirs: [GeoFeature]

        let hasRoad: Bool
        let hasRiver: Bool
        let hasReservoir: Bool
        let hasCoast: Bool

        private var cursor: [SiteKind: Int] = [:]

        init(profile: TerrainProfile, features: [GeoFeature]) {
            cLat = profile.centerLat
            cLon = profile.centerLon
            steep = profile.steepPoint ?? profile.highPoint
            low = profile.lowPoint
            sea = profile.seaPoint

            func sorted(_ kind: GeoFeatureKind, _ refLat: Double, _ refLon: Double) -> [GeoFeature] {
                features.filter { $0.kind == kind }.sorted {
                    TerrainAnalyzer.distanceKm(refLat, refLon, $0.lat, $0.lon) <
                        TerrainAnalyzer.distanceKm(refLat, refLon, $1.lat, $1.lon)
                }
            }

            let steepLat = steep?.lat ?? cLat
            let steepLon = steep?.lon ?? cLon
            let lowLat = low?.lat ?? cLat
            let lowLon = low?.lon ?? cLon
            let seaLat = sea?.lat ?? cLat
            let seaLon = sea?.lon ?? cLon

            peaks = sorted(.peak, steepLat, steepLon)
            slopeSettlements = sorted(.settlement, steepLat, steepLon)
            lowSettlements = sorted(.settlement, lowLat, lowLon)
            roads = sorted(.road, cLat, cLon)
            rivers = sorted(.river, lowLat, lowLon)
            coasts = sorted(.coast, seaLat, seaLon)
            reservoirs = sorted(.reservoir, cLat, cLon)

            let featuresEmpty = features.isEmpty
            hasRoad = !roads.isEmpty || featuresEmpty
            hasRiver = !rivers.isEmpty
            hasReservoir = !reservoirs.isEmpty
            hasCoast = !coasts.isEmpty || featuresEmpty
        }

        func pick(_ kind: SiteKind) -> Site? {
            let candidates: [GeoFeature]
            switch kind {
            case .slope: candidates = peaks.isEmpty ? slopeSettlements : peaks
            case .lowland: candidates = lowSettlements
            case .farmland: candidates = lowSettlements.reversed()
            case .road: candidates = roads
            case .river: candidates = rivers
            case .coast: candidates = coasts
            case .reservoir: candidates = reservoirs
            }
            let anchorPoint: TerrainPoint?
            switch kind {
            case .slope: anchorPoint = steep
            case .lowland, .farmland, .river: anchorPoint = low
            case .coast: anchorPoint = sea
            default: anchorPoint = nil
            }
            if candidates.isEmpty {
                // 方位回退：用地形特征点描述大致位置
                guard let p = anchorPoint else { return Site(name: nil, bearingIndex: 0, distanceKm: 0) }
                return Site(
                    name: nil,
                    bearingIndex: TerrainAnalyzer.bearingIndex(cLat, cLon, p.lat, p.lon),
                    distanceKm: TerrainAnalyzer.distanceKm(cLat, cLon, p.lat, p.lon)
                )
            }
            var idx = cursor[kind] ?? 0
            if idx >= candidates.count { idx = 0 }
            cursor[kind] = idx + 1
            let f = candidates[idx]
            let name = f.name == TerrainAnalyzer.coastPlaceholder ? nil : f.name
            return Site(
                name: name,
                bearingIndex: TerrainAnalyzer.bearingIndex(cLat, cLon, f.lat, f.lon),
                distanceKm: TerrainAnalyzer.distanceKm(cLat, cLon, f.lat, f.lon)
            )
        }
    }

    // MARK: - 气象要素聚合

    private struct Window {
        let p1, p3, p6, p12, p24, p48: Double
        let snowNew, snowDepth: Double
        let tempMin, tempMax: Double
        let freezeThaw: Int
        let humidityMin, humidityMax: Int
        let windMax, gustMax: Double
        let visibilityMin, pressureMin: Double
        let soilTop, soilMid, soilDeep: Double
        let cape: Double
    }

    private static func aggregate(_ h: HazardHourly, start: Int) -> Window {
        let n = h.time.count
        let p24 = sumD(h.precipitation, start, 24, n)
        let p48 = sumD(h.precipitation, start, 48, n)
        // 土壤湿度缺测时用近 48 小时降水做代理估计，保证门控仍可工作
        let proxy = 0.15 + 0.25 * ramp(p48, 0, 80)
        let windMax = maxD(h.windSpeed, start, 24, n)
        return Window(
            p1: maxD(h.precipitation, start, 24, n) ?? 0,
            p3: sumD(h.precipitation, start, 3, n),
            p6: sumD(h.precipitation, start, 6, n),
            p12: sumD(h.precipitation, start, 12, n),
            p24: p24,
            p48: p48,
            snowNew: sumD(h.snowfall, start, 24, n),
            snowDepth: maxD(h.snowDepth, start, 48, n) ?? 0,
            tempMin: minD(h.temperature, start, 24, n) ?? 15,
            tempMax: maxD(h.temperature, start, 24, n) ?? 15,
            freezeThaw: freezeThawCount(h.temperature, start, 48, n),
            humidityMin: minI(h.humidity, start, 24, n) ?? 60,
            humidityMax: maxI(h.humidity, start, 24, n) ?? 60,
            windMax: windMax ?? 0,
            gustMax: maxD(h.windGusts, start, 24, n) ?? ((windMax ?? 0) * 1.5),
            visibilityMin: minD(h.visibility, start, 24, n) ?? 20000,
            pressureMin: minD(h.surfacePressure, start, 24, n) ?? 1013,
            soilTop: maxD(h.soilMoistureTop, start, 24, n) ?? proxy,
            soilMid: maxD(h.soilMoistureMid, start, 24, n) ?? proxy,
            soilDeep: maxD(h.soilMoistureDeep, start, 24, n) ?? maxD(h.soilMoistureMid, start, 24, n) ?? proxy,
            cape: maxD(h.cape, start, 24, n) ?? 0
        )
    }

    private static func upperBound(_ start: Int, _ hours: Int, _ count: Int, _ n: Int) -> Int {
        min(start + hours, min(count, n))
    }

    private static func sumD(_ list: [Double?]?, _ start: Int, _ hours: Int, _ n: Int) -> Double {
        guard let list else { return 0 }
        var s = 0.0
        let end = upperBound(start, hours, list.count, n)
        var i = start
        while i < end {
            s += list[i] ?? 0
            i += 1
        }
        return s
    }

    private static func maxD(_ list: [Double?]?, _ start: Int, _ hours: Int, _ n: Int) -> Double? {
        guard let list else { return nil }
        var r: Double?
        let end = upperBound(start, hours, list.count, n)
        var i = start
        while i < end {
            if let v = list[i], r == nil || v > r! { r = v }
            i += 1
        }
        return r
    }

    private static func minD(_ list: [Double?]?, _ start: Int, _ hours: Int, _ n: Int) -> Double? {
        guard let list else { return nil }
        var r: Double?
        let end = upperBound(start, hours, list.count, n)
        var i = start
        while i < end {
            if let v = list[i], r == nil || v < r! { r = v }
            i += 1
        }
        return r
    }

    private static func maxI(_ list: [Int?]?, _ start: Int, _ hours: Int, _ n: Int) -> Int? {
        guard let list else { return nil }
        var r: Int?
        let end = upperBound(start, hours, list.count, n)
        var i = start
        while i < end {
            if let v = list[i], r == nil || v > r! { r = v }
            i += 1
        }
        return r
    }

    private static func minI(_ list: [Int?]?, _ start: Int, _ hours: Int, _ n: Int) -> Int? {
        guard let list else { return nil }
        var r: Int?
        let end = upperBound(start, hours, list.count, n)
        var i = start
        while i < end {
            if let v = list[i], r == nil || v < r! { r = v }
            i += 1
        }
        return r
    }

    /// 冻融循环次数：气温穿越 0 ℃ 的次数除以 2（一升一降算一轮）
    private static func freezeThawCount(_ list: [Double?]?, _ start: Int, _ hours: Int, _ n: Int) -> Int {
        guard let list else { return 0 }
        var crossings = 0
        var prev: Bool?
        let end = upperBound(start, hours, list.count, n)
        var i = start
        while i < end {
            if let v = list[i] {
                let below = v < 0
                if let p = prev, p != below { crossings += 1 }
                prev = below
            }
            i += 1
        }
        return crossings / 2
    }

    // MARK: - 工具

    /// 线性斜坡归一化
    static func ramp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        hi <= lo ? 0 : clamp((v - lo) / (hi - lo), 0, 1)
    }

    private static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(hi, max(lo, v))
    }

    private static func metric(_ index: Int, _ text: String) -> HazardMetric {
        HazardMetric(labelIndex: index, text: text)
    }

    private static func mm(_ v: Double) -> String { "\(fmt1(v)) mm" }
    private static func cm(_ v: Double) -> String { "\(fmt1(v)) cm" }
    private static func m1(_ v: Double) -> String { "\(fmt1(v)) m" }
    private static func m2(_ v: Double) -> String { "\(fmt2(v)) m" }
    private static func m0(_ v: Double) -> String { "\(Int(v.rounded())) m" }
    private static func deg(_ v: Double) -> String { "\(fmt1(v))°" }
    private static func kmh(_ v: Double) -> String { "\(Int(v.rounded())) km/h" }
    private static func hpa(_ v: Double) -> String { "\(Int(v.rounded())) hPa" }
    private static func c1(_ v: Double) -> String { "\(fmt1(v))°C" }
    private static func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }

    private static let posix = Locale(identifier: "en_US_POSIX")
    private static func fmt1(_ v: Double) -> String { String(format: "%.1f", locale: posix, v) }
    private static func fmt2(_ v: Double) -> String { String(format: "%.2f", locale: posix, v) }

    /// 阵风（km/h）→ 蒲福风力等级
    static func beaufort(_ kmh: Double) -> Int {
        switch kmh {
        case ..<1: return 0
        case ..<6: return 1
        case ..<12: return 2
        case ..<20: return 3
        case ..<29: return 4
        case ..<39: return 5
        case ..<50: return 6
        case ..<62: return 7
        case ..<75: return 8
        case ..<89: return 9
        case ..<103: return 10
        case ..<118: return 11
        case ..<134: return 12
        case ..<150: return 13
        case ..<167: return 14
        case ..<184: return 15
        case ..<202: return 16
        case ..<221: return 17
        default: return 18
        }
    }
}
