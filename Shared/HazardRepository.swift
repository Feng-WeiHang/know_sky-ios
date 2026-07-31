import Foundation

/// 地表防灾预报仓库（对应 Android data/repository/HazardRepository.kt）
///
/// 地形高程与 OSM 要素属于不随时间变化的静态地理信息，按城市长期缓存（进程内）；
/// 灾害预测结果随气象更新，缓存 30 分钟。Overpass 查询失败不影响整体流程，仅退化为方位描述。
actor HazardRepository {

    static let shared = HazardRepository()

    private let predictionTTL: TimeInterval = 30 * 60

    private var terrainCache: [String: TerrainProfile] = [:]
    private var featureCache: [String: [GeoFeature]] = [:]
    private var predictionCache: [String: (Date, [HazardPrediction])] = [:]

    /// 取城市的地表灾害预测；地形/气象任一取不到时返回 nil（UI 显示为未能推演）
    func getPredictions(city: CityInfo, forceRefresh: Bool = false) async -> [HazardPrediction]? {
        let key = city.id
        if !forceRefresh, let (ts, list) = predictionCache[key],
           Date().timeIntervalSince(ts) < predictionTTL {
            return list
        }

        guard let terrain = await loadTerrain(city) else { return nil }
        let features = await loadFeatures(city)

        guard let forecast = try? await GeoAPI.getHazardForecast(
            latitude: city.latitude, longitude: city.longitude
        ), let hourly = forecast.hourly else { return nil }

        let predictions = HazardEngine.analyze(
            profile: terrain,
            features: features,
            hourly: hourly,
            anchorIso: forecast.current?.time
        )
        predictionCache[key] = (Date(), predictions)
        return predictions
    }

    /// 高程网格 → 地形画像（长期缓存）
    private func loadTerrain(_ city: CityInfo) async -> TerrainProfile? {
        if let cached = terrainCache[city.id] { return cached }
        let grid = TerrainAnalyzer.buildGrid(lat: city.latitude, lon: city.longitude)
        let posix = Locale(identifier: "en_US_POSIX")
        let lats = grid.map { String(format: "%.4f", locale: posix, $0.0) }.joined(separator: ",")
        let lons = grid.map { String(format: "%.4f", locale: posix, $0.1) }.joined(separator: ",")
        guard let resp = try? await GeoAPI.getElevations(latitudes: lats, longitudes: lons),
              let elevations = resp.elevation else { return nil }
        guard let profile = TerrainAnalyzer.analyze(
            lat: city.latitude, lon: city.longitude, grid: grid, elevations: elevations
        ) else { return nil }
        terrainCache[city.id] = profile
        return profile
    }

    /// OSM 具名要素（长期缓存；查询失败返回空表，引擎会退化为方位描述）
    private func loadFeatures(_ city: CityInfo) async -> [GeoFeature] {
        if let cached = featureCache[city.id] { return cached }
        let query = GeoAPI.buildOverpassQuery(lat: city.latitude, lon: city.longitude)
        guard let resp = try? await GeoAPI.queryOverpass(query) else { return [] }
        let features = TerrainAnalyzer.parseFeatures(resp, lat: city.latitude, lon: city.longitude)
        // 只有成功拿到要素才写缓存，失败时留待下次刷新重试
        if !features.isEmpty { featureCache[city.id] = features }
        return features
    }
}
