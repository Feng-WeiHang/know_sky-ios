import Foundation

/// 天气数据仓库 - 统一管理数据获取、缓存与城市名本地化
/// 对应 Android WeatherRepository
final class WeatherRepository {

    static let shared = WeatherRepository()
    private let store = AppStore.shared

    // MARK: - 天气数据

    /// 获取指定城市的完整天气数据（空气质量失败不阻断）
    func fetchCityWeather(_ city: CityInfo) async throws -> CityWeatherData {
        let forecast = try await WeatherAPI.getForecast(latitude: city.latitude, longitude: city.longitude)
        let airQuality = try? await WeatherAPI.getAirQuality(latitude: city.latitude, longitude: city.longitude).current

        let data = CityWeatherData(
            city: city,
            current: forecast.current,
            hourly: forecast.hourly,
            daily: forecast.daily,
            airQuality: airQuality,
            lastUpdated: Date()
        )
        store.cacheWeather(data)
        return data
    }

    /// 批量获取所有城市的天气数据（失败城市跳过）
    func fetchAllCitiesWeather() async -> [CityWeatherData] {
        let cities = store.getCities()
        var result: [CityWeatherData] = []
        await withTaskGroup(of: CityWeatherData?.self) { group in
            for city in cities {
                group.addTask { try? await self.fetchCityWeather(city) }
            }
            for await item in group {
                if let item { result.append(item) }
            }
        }
        // 保持城市原顺序
        let order = Dictionary(uniqueKeysWithValues: cities.enumerated().map { ($1.id, $0) })
        return result.sorted { (order[$0.city.id] ?? 0) < (order[$1.city.id] ?? 0) }
    }

    // MARK: - 城市搜索

    /// 搜索城市：内置中国省市区县离线索引优先（1 个字即可模糊匹配），
    /// 再用 open-meteo 在线结果去重后补充（海外/英文检索场景）。
    func searchCities(_ query: String, language: AppLanguage) async -> [GeocodingResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        // 1) 离线索引本地检索（解决在线接口搜不到盘锦/台安/岫岩等小地市的问题）
        let local = ChinaRegionIndex.search(q)

        // 2) 在线补充：API 2 字符以下无模糊能力，不发请求避免白跑
        var online: [GeocodingResult] = []
        if q.count >= 2 {
            online = (try? await WeatherAPI.searchCity(name: q, language: geoLang(language))) ?? []
        }

        // 3) 合并去重：坐标接近且名字互为前缀则视为同一地点，保留离线条目
        let merged = local + online.filter { o in
            !local.contains { l in
                abs(l.latitude - o.latitude) < 0.6 &&
                    abs(l.longitude - o.longitude) < 0.6 &&
                    isSameName(l.name, o.name)
            }
        }
        return Array(merged.prefix(30))
    }

    /// 名字去重判定：互为前缀（兼容“盘锦”/“盘锦市”等后缀差异）
    private func isSameName(_ a: String, _ b: String) -> Bool {
        guard !a.isEmpty, !b.isEmpty else { return false }
        func strip(_ s: String) -> String {
            var s = s
            for suf in ["市", "县", "区"] where s.hasSuffix(suf) {
                s = String(s.dropLast(suf.count))
            }
            return s
        }
        return a.hasPrefix(b) || b.hasPrefix(a) || strip(a) == strip(b)
    }

    /// 按目标语言在线补全已添加城市的本地化名称并持久化缓存。
    /// 已有缓存的城市跳过；网络失败静默（界面回退原名）。
    func localizeCities(_ language: AppLanguage) async {
        // 简体中文为存储原名，无需翻译
        guard language != .simplifiedChinese else { return }
        var cities = store.getCities()
        var changed = false

        for i in cities.indices {
            let city = cities[i]
            if let cached = city.localizedNames?[language.code], !cached.isEmpty { continue }
            // 1) 解析地点 ID（旧数据无 geoId：用中文名搜索 + 经纬度就近匹配补齐）
            var resolvedId = city.geoId
            if resolvedId == nil { resolvedId = await resolveGeoId(city) }
            guard let geoId = resolvedId else { continue }
            // 2) 按 ID 直查目标语言名称（search 接口不支持跨语言，get 接口可以）
            guard let match = try? await WeatherAPI.getCityById(id: geoId, language: geoLang(language)) else {
                // ID 已解析但取名失败：仅回写 geoId，下次重试免重新搜索
                if city.geoId == nil { cities[i].geoId = geoId; changed = true }
                continue
            }
            var names = city.localizedNames ?? [:]
            var admins = city.localizedAdmins ?? [:]
            names[language.code] = match.name
            admins[language.code] = match.admin1 ?? ""
            cities[i].geoId = geoId
            cities[i].localizedNames = names
            cities[i].localizedAdmins = admins
            changed = true
        }
        if changed { store.saveCities(cities) }
    }

    /// 旧数据补齐地点 ID：用存储原名（中文）搜索，经纬度就近匹配
    private func resolveGeoId(_ city: CityInfo) async -> Int? {
        // 城市名可能带"市/县/区"后缀导致检索不中，逐级去后缀重试
        var queries: [String] = [city.name]
        var trimmed = city.name
        for suffix in ["市", "县", "区"] where trimmed.hasSuffix(suffix) {
            trimmed = String(trimmed.dropLast())
        }
        if trimmed != city.name && !trimmed.isEmpty { queries.append(trimmed) }

        for q in queries {
            guard let results = try? await WeatherAPI.searchCity(name: q, language: "zh") else { continue }
            let match = results
                .filter { abs($0.latitude - city.latitude) < 0.1 && abs($0.longitude - city.longitude) < 0.1 }
                .min { lhs, rhs in
                    (abs(lhs.latitude - city.latitude) + abs(lhs.longitude - city.longitude)) <
                    (abs(rhs.latitude - city.latitude) + abs(rhs.longitude - city.longitude))
                }
            if let match { return match.id }
        }
        return nil
    }

    /// AppLanguage → geocoding API 语言码（API 不支持繁体，回退 zh）
    private func geoLang(_ language: AppLanguage) -> String {
        language == .traditionalChinese ? "zh" : language.code
    }
}
