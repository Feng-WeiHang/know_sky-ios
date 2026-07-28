import Foundation
import SwiftUI
import WidgetKit

/// 天气主视图模型（对应 Android WeatherViewModel）
@MainActor
final class WeatherViewModel: ObservableObject {

    @Published var cities: [CityInfo] = []
    @Published var selectedCityId: String?
    @Published var settings = AppSettings()
    @Published var weatherByCity: [String: CityWeatherData] = [:]
    @Published var isRefreshing = false
    @Published var searchResults: [GeocodingResult] = []
    @Published var isSearching = false

    private let store = AppStore.shared
    private let repository = WeatherRepository.shared

    /// 当前语言全部文案
    var strings: Strings { I18n.of(settings.language) }

    /// 当前选中城市
    var selectedCity: CityInfo? {
        if let id = selectedCityId, let c = cities.first(where: { $0.id == id }) { return c }
        return cities.first
    }

    /// 当前选中城市的天气
    var selectedWeather: CityWeatherData? {
        guard let city = selectedCity else { return nil }
        return weatherByCity[city.id]
    }

    init() {
        load()
        // 冷启动先展示缓存，再后台刷新
        Task { await refreshAll() }
    }

    /// 从本地存储载入状态与缓存
    func load() {
        cities = store.getCities()
        selectedCityId = store.getSelectedCityId() ?? cities.first?.id
        settings = store.getSettings()
        for city in cities {
            if let cached = store.getCachedWeather(cityId: city.id) {
                weatherByCity[city.id] = cached
            }
        }
    }

    // MARK: - 天气刷新

    /// 刷新全部城市天气
    func refreshAll() async {
        guard !cities.isEmpty else { return }
        isRefreshing = true
        let list = await repository.fetchAllCitiesWeather()
        for item in list { weatherByCity[item.city.id] = item }
        isRefreshing = false
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 数据超过刷新间隔才刷新（回到前台时调用）
    func refreshIfStale() async {
        let interval = TimeInterval(settings.refreshIntervalMinutes * 60)
        if let w = selectedWeather, Date().timeIntervalSince(w.lastUpdated) < interval { return }
        await refreshAll()
    }

    // MARK: - 城市管理

    func selectCity(_ cityId: String) {
        selectedCityId = cityId
        store.setSelectedCityId(cityId)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func addCity(_ result: GeocodingResult) {
        let city = result.toCityInfo()
        store.addCity(city)
        cities = store.getCities()
        if selectedCityId == nil { selectedCityId = city.id }
        Task {
            if let data = try? await repository.fetchCityWeather(city) {
                weatherByCity[city.id] = data
            }
            // 非中文界面下补全新城市的本地化名
            await repository.localizeCities(settings.language)
            cities = store.getCities()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func removeCity(_ cityId: String) {
        store.removeCity(cityId)
        cities = store.getCities()
        weatherByCity.removeValue(forKey: cityId)
        if selectedCityId == cityId { selectedCityId = cities.first?.id }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 拖动排序提交
    func reorderCities(_ newOrder: [CityInfo]) {
        cities = newOrder
        store.saveCities(newOrder)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 是否已添加
    func isCityAdded(_ result: GeocodingResult) -> Bool {
        cities.contains { $0.id == result.toCityInfo().id }
    }

    // MARK: - 城市搜索

    func searchCities(_ query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        searchResults = await repository.searchCities(query, language: settings.language)
        isSearching = false
    }

    // MARK: - 设置

    func updateSettings(_ newSettings: AppSettings) {
        let languageChanged = newSettings.language != settings.language
        settings = newSettings
        store.saveSettings(newSettings)
        WidgetCenter.shared.reloadAllTimelines()
        if languageChanged {
            // 切换语言后在线补全城市本地化名
            Task {
                await repository.localizeCities(newSettings.language)
                cities = store.getCities()
            }
        }
    }
}
