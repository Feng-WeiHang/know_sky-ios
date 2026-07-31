import Foundation

/// 地形分析器（对应 Android util/TerrainAnalyzer.kt）
///
/// 用 9×9 高程网格（≈13 km × 13 km）刻画城市周边地势：高差、坡度、低洼占比、海域占比，
/// 并挑出最陡点 / 最低点 / 最高点 / 海域点作为灾害落点候选。
///
/// 注意：网格间距约 1.7 km，算出的坡度是「网格尺度平均坡度」，数值上远小于真实沟谷坡度，
/// 因此判据阈值按此尺度单独标定（3°/6°/10°），文案中也如实标注为网格尺度。
enum TerrainAnalyzer {

    /// 网格边长（采样点数），81 点满足高程接口单次 100 点上限
    static let gridSize = 9

    /// 纬向步长（度），0.015° ≈ 1.67 km
    private static let stepLat = 0.015

    private static let earthRadiusKm = 6371.0

    /// 海岸线常无 name 标签，用占位符标识，渲染时改用「近岸海岸线」类描述
    static let coastPlaceholder = "\u{0000}coast"

    /// 生成网格坐标（行优先，中心点位于正中）
    static func buildGrid(lat: Double, lon: Double) -> [(Double, Double)] {
        let half = gridSize / 2
        let cosLat = max(0.2, cos(lat * .pi / 180))
        let stepLon = stepLat / cosLat
        var out: [(Double, Double)] = []
        out.reserveCapacity(gridSize * gridSize)
        for r in -half...half {
            for c in -half...half {
                let la = min(89.9, max(-89.9, lat + Double(r) * stepLat))
                var lo = lon + Double(c) * stepLon
                if lo > 180 { lo -= 360 }
                if lo < -180 { lo += 360 }
                out.append((la, lo))
            }
        }
        return out
    }

    /// 网格间距（公里）
    static func gridSpacingKm(lat: Double) -> Double { stepLat * 111.32 }

    /// 由高程数组构建地形画像；数据不足时返回 nil
    static func analyze(
        lat: Double,
        lon: Double,
        grid: [(Double, Double)],
        elevations: [Double]
    ) -> TerrainProfile? {
        guard elevations.count >= grid.count, grid.count >= gridSize * gridSize else { return nil }

        let spacingKm = gridSpacingKm(lat: lat)
        let spacingM = spacingKm * 1000
        let n = gridSize

        func elevAt(_ r: Int, _ c: Int) -> Double { elevations[r * n + c] }

        // 逐点坡度：取四邻域最大高差 / 网格间距
        var points: [TerrainPoint] = []
        points.reserveCapacity(grid.count)
        for r in 0..<n {
            for c in 0..<n {
                let h = elevAt(r, c)
                var maxDiff = 0.0
                if r > 0 { maxDiff = max(maxDiff, abs(h - elevAt(r - 1, c))) }
                if r < n - 1 { maxDiff = max(maxDiff, abs(h - elevAt(r + 1, c))) }
                if c > 0 { maxDiff = max(maxDiff, abs(h - elevAt(r, c - 1))) }
                if c < n - 1 { maxDiff = max(maxDiff, abs(h - elevAt(r, c + 1))) }
                let slope = atan(maxDiff / spacingM) * 180 / .pi
                let p = grid[r * n + c]
                points.append(TerrainPoint(lat: p.0, lon: p.1, elevation: h, slopeDeg: slope))
            }
        }

        let centerIdx = (n / 2) * n + (n / 2)
        let centerElev = points[centerIdx].elevation
        let minElev = points.map(\.elevation).min() ?? centerElev
        let maxElev = points.map(\.elevation).max() ?? centerElev
        let meanElev = points.reduce(0) { $0 + $1.elevation } / Double(points.count)
        let landPoints = points.filter { $0.elevation > 0.5 }
        let seaPoints = points.filter { $0.elevation <= 0.5 }

        let steep = landPoints.max { $0.slopeDeg < $1.slopeDeg } ?? points.max { $0.slopeDeg < $1.slopeDeg }
        let low = landPoints.min { $0.elevation < $1.elevation } ?? points.min { $0.elevation < $1.elevation }
        let high = points.max { $0.elevation < $1.elevation }
        // 海域点取离城市中心最近的一个，代表最可能受影响的岸段
        let sea = seaPoints.min {
            distanceKm(lat, lon, $0.lat, $0.lon) < distanceKm(lat, lon, $1.lat, $1.lon)
        }

        let lowThreshold = min(centerElev, meanElev)
        let lowlandRatio = Double(points.filter { $0.elevation <= lowThreshold + 2.0 }.count) / Double(points.count)

        return TerrainProfile(
            centerLat: lat,
            centerLon: lon,
            centerElevation: centerElev,
            minElevation: minElev,
            maxElevation: maxElev,
            meanElevation: meanElev,
            relief: maxElev - minElev,
            maxSlopeDeg: points.map(\.slopeDeg).max() ?? 0,
            meanSlopeDeg: points.reduce(0) { $0 + $1.slopeDeg } / Double(points.count),
            seaRatio: Double(seaPoints.count) / Double(points.count),
            lowlandRatio: lowlandRatio,
            steepPoint: steep,
            lowPoint: low,
            highPoint: high,
            seaPoint: sea,
            gridSpacingKm: spacingKm
        )
    }

    /// 解析 Overpass 响应为具名地理要素；同名要素只保留距中心最近的一个
    static func parseFeatures(_ resp: OverpassResponse, lat: Double, lon: Double) -> [GeoFeature] {
        guard let elements = resp.elements else { return [] }
        var keys: [String] = []
        var byName: [String: GeoFeature] = [:]
        for e in elements {
            guard let tags = e.tags else { continue }
            guard let pLat = e.lat ?? e.center?.lat, let pLon = e.lon ?? e.center?.lon else { continue }
            guard let kind = classify(tags) else { continue }
            let rawName = tags["name"] ?? tags["name:zh"] ?? (kind == .coast ? coastPlaceholder : nil)
            guard let name = rawName, !name.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let key = "\(kind)|\(name)"
            let feature = GeoFeature(kind: kind, name: name, lat: pLat, lon: pLon)
            if let old = byName[key] {
                if distanceKm(lat, lon, pLat, pLon) < distanceKm(lat, lon, old.lat, old.lon) {
                    byName[key] = feature
                }
            } else {
                keys.append(key)
                byName[key] = feature
            }
        }
        return keys.compactMap { byName[$0] }
    }

    private static func classify(_ tags: [String: String]) -> GeoFeatureKind? {
        if let place = tags["place"],
           ["town", "suburb", "village", "hamlet", "neighbourhood", "quarter"].contains(place) {
            return .settlement
        }
        if tags["natural"] == "peak" { return .peak }
        if tags["natural"] == "coastline" { return .coast }
        if let highway = tags["highway"], ["motorway", "trunk", "primary"].contains(highway) { return .road }
        if let waterway = tags["waterway"], ["river", "stream", "canal"].contains(waterway) { return .river }
        if let water = tags["water"], water == "reservoir" || water == "lake" { return .reservoir }
        return nil
    }

    /// 简化球面距离（公里）
    static func distanceKm(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadiusKm * atan2(sqrt(a), sqrt(1 - a))
    }

    /// 方位索引：0=北，顺时针每 45° 一档，对应 Strings.windDirs
    static func bearingIndex(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Int {
        let dLon = (lon2 - lon1) * .pi / 180
        let la1 = lat1 * .pi / 180
        let la2 = lat2 * .pi / 180
        let y = sin(dLon) * cos(la2)
        let x = cos(la1) * sin(la2) - sin(la1) * cos(la2) * cos(dLon)
        var deg = atan2(y, x) * 180 / .pi
        if deg < 0 { deg += 360 }
        return Int((deg + 22.5) / 45.0) % 8
    }
}
