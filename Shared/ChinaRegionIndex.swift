import Foundation

/// 中国省市区县离线索引（内置 Resources/china_regions.json，约 3400 条，WGS84 坐标）
///
/// 背景：open-meteo geocoding 接口对中国县级市/县收录差，且官方规则
/// 1 字符返回空、2 字符仅精确匹配、3 字符以上才模糊匹配，导致
/// "盘锦""台安""岫岩"等小地市搜不到。本索引支持输入 1 个字即可模糊检索。
enum ChinaRegionIndex {

    private struct Region {
        let name: String
        let admin: String
        let lat: Double
        let lon: Double
    }

    /// 懒加载（首次搜索时读取，约 190KB，解析开销一次性）
    private static let regions: [Region] = loadRegions()

    private static func loadRegions() -> [Region] {
        guard let url = Bundle.main.url(forResource: "china_regions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            return []
        }
        return arr.compactMap { e in
            guard e.count == 4,
                  let name = e[0] as? String,
                  let admin = e[1] as? String,
                  let lat = (e[2] as? NSNumber)?.doubleValue,
                  let lon = (e[3] as? NSNumber)?.doubleValue else { return nil }
            return Region(name: name, admin: admin, lat: lat, lon: lon)
        }
    }

    /// 本地模糊搜索：1 个字符起即可匹配（名称包含即命中）
    /// 排序：全等 > 前缀 > 包含；同分时行政级别高（直辖市/地级市）优先
    static func search(_ query: String, limit: Int = 20) -> [GeocodingResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !regions.isEmpty else { return [] }

        return regions.compactMap { r -> (Region, Int)? in
            let matchScore: Int
            if r.name == q {
                matchScore = 0
            } else if r.name.hasPrefix(q) {
                matchScore = 1
            } else if r.name.contains(q) {
                matchScore = 2
            } else {
                return nil
            }
            // 行政级别权重：admin 为空（直辖市）=0，一段（地级市）=1，两段（区县）=2
            let levelWeight = r.admin.isEmpty ? 0 : r.admin.filter { $0 == " " }.count + 1
            return (r, matchScore * 10 + levelWeight)
        }
        .sorted { l, r in
            if l.1 != r.1 { return l.1 < r.1 }
            return l.0.name.count < r.0.name.count
        }
        .prefix(limit)
        .map { toGeocodingResult($0.0) }
    }

    private static func toGeocodingResult(_ r: Region) -> GeocodingResult {
        GeocodingResult(
            // 负数 id 标记为离线条目（非 open-meteo geoId），toCityInfo 时不作为 geoId 使用
            id: -stableHash("\(r.name)|\(r.admin)") - 1,
            name: r.name,
            latitude: r.lat,
            longitude: r.lon,
            country: "中国",
            country_code: "CN",
            admin1: r.admin.isEmpty ? nil : r.admin,
            timezone: "Asia/Shanghai"
        )
    }

    /// 确定性哈希（djb2，Swift 原生 hashValue 每次启动随机化不可用）
    private static func stableHash(_ s: String) -> Int {
        var h: UInt32 = 5381
        for b in s.utf8 { h = h &* 33 &+ UInt32(b) }
        return Int(h & 0x7FFF_FFFF)
    }
}
