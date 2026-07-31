import Foundation

/// 共享持久化存储（App Group UserDefaults，主应用与小组件共用）
/// 对应 Android AppDataStore（DataStore Preferences）
final class AppStore {

    static let shared = AppStore()
    static let appGroupId = "group.com.xiaotian.skysense"

    private let defaults: UserDefaults

    private enum Keys {
        static let cities = "cities_json"
        static let selectedCityId = "selected_city_id"
        static let settings = "settings_json"
        static let alertKeys = "recent_alert_keys"          // [key: 触发时间戳]
        static let weatherCachePrefix = "weather_cache_"    // + cityId
        static let currentLocation = "current_location_json"
    }

    /// 预警去重有效期：2 小时（与 Android 一致）
    private static let alertDedupInterval: TimeInterval = 2 * 3600

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: AppStore.appGroupId) ?? .standard
    }

    // MARK: - 城市

    func getCities() -> [CityInfo] {
        guard let data = defaults.data(forKey: Keys.cities) else { return [] }
        return (try? JSONDecoder().decode([CityInfo].self, from: data)) ?? []
    }

    func saveCities(_ cities: [CityInfo]) {
        if let data = try? JSONEncoder().encode(cities) {
            defaults.set(data, forKey: Keys.cities)
        }
    }

    func addCity(_ city: CityInfo) {
        var cities = getCities()
        guard !cities.contains(where: { $0.id == city.id }) else { return }
        cities.append(city)
        saveCities(cities)
        // 首个城市自动设为选中
        if cities.count == 1 { setSelectedCityId(city.id) }
    }

    func removeCity(_ cityId: String) {
        var cities = getCities()
        cities.removeAll { $0.id == cityId }
        saveCities(cities)
        defaults.removeObject(forKey: Keys.weatherCachePrefix + cityId)
        // 删除的是选中城市则改选第一个
        if getSelectedCityId() == cityId {
            setSelectedCityId(cities.first?.id ?? "")
        }
    }

    // MARK: - 选中城市

    func getSelectedCityId() -> String? {
        let id = defaults.string(forKey: Keys.selectedCityId)
        return (id?.isEmpty == false) ? id : nil
    }

    func setSelectedCityId(_ cityId: String) {
        defaults.set(cityId, forKey: Keys.selectedCityId)
    }

    /// 当前选中城市（无选中则回退第一个）
    func getSelectedCity() -> CityInfo? {
        let cities = getCities()
        if let id = getSelectedCityId(), let c = cities.first(where: { $0.id == id }) { return c }
        return cities.first
    }

    // MARK: - 设置

    func getSettings() -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings) else { return AppSettings() }
        return (try? JSONDecoder().decode(AppSettings.self, from: data)) ?? AppSettings()
    }

    func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Keys.settings)
        }
    }

    // MARK: - 天气缓存（小组件离线展示 + 冷启动秒开）

    func getCachedWeather(cityId: String) -> CityWeatherData? {
        guard let data = defaults.data(forKey: Keys.weatherCachePrefix + cityId) else { return nil }
        return try? JSONDecoder().decode(CityWeatherData.self, from: data)
    }

    func cacheWeather(_ weather: CityWeatherData) {
        if let data = try? JSONEncoder().encode(weather) {
            defaults.set(data, forKey: Keys.weatherCachePrefix + weather.city.id)
        }
    }

    // MARK: - 预警记录（去重）

    /// 未过期的预警 key 集合
    func getRecentAlertKeys() -> Set<String> {
        cleanExpiredAlertKeys()
        let dict = defaults.dictionary(forKey: Keys.alertKeys) as? [String: Double] ?? [:]
        return Set(dict.keys)
    }

    // MARK: - GPS 当前定位点

    /// 最近一次成功定位的点（含反查地名与时间戳），供后台预警读取
    func getCurrentLocation() -> CurrentLocationPoint? {
        guard let data = defaults.data(forKey: Keys.currentLocation) else { return nil }
        return try? JSONDecoder().decode(CurrentLocationPoint.self, from: data)
    }

    func saveCurrentLocation(_ point: CurrentLocationPoint) {
        if let data = try? JSONEncoder().encode(point) {
            defaults.set(data, forKey: Keys.currentLocation)
        }
    }

    // MARK: - 预警去重记录

    func addAlertKey(_ key: String) {
        var dict = defaults.dictionary(forKey: Keys.alertKeys) as? [String: Double] ?? [:]
        dict[key] = Date().timeIntervalSince1970
        defaults.set(dict, forKey: Keys.alertKeys)
    }

    func cleanExpiredAlertKeys() {
        var dict = defaults.dictionary(forKey: Keys.alertKeys) as? [String: Double] ?? [:]
        let cutoff = Date().timeIntervalSince1970 - AppStore.alertDedupInterval
        dict = dict.filter { $0.value >= cutoff }
        defaults.set(dict, forKey: Keys.alertKeys)
    }
}
